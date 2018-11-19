let s:SYMBOL = '@@observable'
let s:DEFAULT_WAIT_INTERVAL = 30

function! s:_vital_depends() abort
  return [
        \ 'Async.Later',
        \ 'Async.Promise'
        \]
endfunction

function! s:_vital_loaded(V) abort
  let s:Later = a:V.import('Async.Later')
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:_vital_created(module) abort
  let a:module.SYMBOL = s:SYMBOL
endfunction

function! s:new(subscriber) abort
  if type(a:subscriber) isnot# v:t_func
    throw 'vital: Async.Observable: Observable initializer must be a function'
  endif
  return s:_new_observable(a:subscriber)
endfunction

function! s:of(...) abort
  return s:from(a:000)
endfunction

function! s:from(input) abort
  if s:is_observable(a:input)
    return s:_new_observable(funcref('s:_from_observable_subscriber', [a:input]))
  elseif s:Promise.is_promise(a:input)
    return s:_new_observable(funcref('s:_from_promise_subscriber', [a:input]))
  elseif type(a:input) is# v:t_list
    return s:_new_observable({ o ->
          \ s:Later.call(funcref('s:_from_array_subscriber', [a:input, o]))
          \})
  endif
  throw printf('vital: Async.Observable: %s is not observable', a:input)
endfunction

function! s:_from_observable_subscriber(observable, observer) abort
  if a:observer.closed()
    return
  endif
  return a:observable[s:SYMBOL]().subscribe(a:observer)
endfunction

function! s:_from_promise_subscriber(promise, observer) abort
  if a:observer.closed()
    return
  endif
  call a:promise
        \.catch({ e -> a:observer.error(e) })
        \.then({ v -> a:observer.next(v) })
        \.then({ -> a:observer.complete() })
endfunction

function! s:_from_array_subscriber(array, observer) abort
  if a:observer.closed()
    return
  endif
  for item in a:array
    call a:observer.next(item)
    if a:observer.closed()
      return
    endif
  endfor
  call a:observer.complete()
endfunction

function! s:wait(subscriptions, ...) abort
  let subscriptions = type(a:subscriptions) is# v:t_list
        \ ? copy(a:subscriptions)
        \ : [a:subscriptions]
  if a:0 && type(a:1) is# v:t_number
    let t = a:1
    let i = s:DEFAULT_WAIT_INTERVAL . 'm'
  else
    let o = a:0 ? a:1 : {}
    let t = get(o, 'timeout', v:null)
    let i = get(o, 'interval', s:DEFAULT_WAIT_INTERVAL) . 'm'
  endif
  let s = reltime()
  for subscription in subscriptions
    while !subscription.closed()
      if t isnot# v:null && reltimefloat(reltime(s)) * 1000 > t
        return 1
      endif
      execute 'sleep' i
    endwhile
  endfor
endfunction

function! s:is_observable(maybe_observable) abort
  return type(a:maybe_observable) is# v:t_dict
        \ && type(get(a:maybe_observable, s:SYMBOL, v:null)) is# v:t_func
endfunction


" Observable ---------------------------------------------------------------
function! s:_new_observable(subscriber) abort
  let observable = {
        \ '__subscriber': a:subscriber,
        \ 'subscribe': funcref('s:_observable_subscribe'),
        \ 'foreach': funcref('s:_observable_foreach'),
        \ 'pipe': funcref('s:_observable_pipe'),
        \ 'to_promise': funcref('s:_observable_to_promise'),
        \}
  let observable[s:SYMBOL] = funcref('s:_observable_symbol')
  return observable
endfunction

function! s:_observable_symbol() abort dict
  return self
endfunction

function! s:_observable_subscribe(...) abort dict
  let observer = a:0 is# 1 && type(a:1) is# v:t_dict ? a:1 : {
        \ 'next': get(a:, 1, v:null),
        \ 'error': get(a:, 2, v:null),
        \ 'complete': get(a:, 3, v:null),
        \}
  return s:_new_subscription(
        \ observer,
        \ self.__subscriber,
        \)
endfunction

function! s:_observable_foreach(fn) abort dict
  return s:Promise.new(funcref('s:_observable_foreach_executor', [self, a:fn]))
endfunction

function! s:_observable_foreach_executor(source, fn, resolve, reject) abort
  let ns = {
        \ 'fn': a:fn,
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
  let ns.subscription = a:source.subscribe({
        \ 'next': funcref('s:_observable_foreach_next', [ns]),
        \ 'error': { e -> a:reject(e) },
        \ 'complete': { -> a:resolve() },
        \})
endfunction

function! s:_observable_foreach_next(ns, value) abort
  try
    call a:ns.fn(a:value, funcref('s:_observable_foreach_done', [a:ns]))
  catch
    call a:ns.subscription.unsubscribe()
    call a:ns.reject({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
endfunction

function! s:_observable_foreach_done(ns) abort
  call a:ns.subscription.unsubscribe()
  call a:ns.resolve()
endfunction

function! s:_observable_pipe(...) abort dict
  let next = self
  for Operator in a:000
    let next = call(Operator, [next, funcref('s:new')])
  endfor
  return next
endfunction

function! s:_observable_to_promise() abort dict
  return s:Promise.new(funcref('s:_observable_to_promise_executor', [self]))
endfunction

function! s:_observable_to_promise_executor(source, resolve, reject) abort
  let ns = {
        \ 'value': 0,
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
  call a:source.subscribe({
        \ 'next': { v -> extend(ns, { 'value': v }) },
        \ 'error': { e -> a:reject(e) },
        \ 'complete': { -> a:resolve(ns.value) },
        \})
endfunction


" Subscription -------------------------------------------------------------
function! s:_new_subscription(observer, subscriber) abort
  let subscription = {
        \ '__cleanup': v:null,
        \ '__observer': a:observer,
        \ 'closed': funcref('s:_subscription_closed'),
        \ 'unsubscribe': funcref('s:_subscription_unsubscribe'),
        \}

  if type(get(a:observer, 'start', v:null)) is# v:t_func
    try
      call a:observer.start(subscription)
    catch
      call s:_report(v:exception, v:throwpoint)
    endtry
    if subscription.closed()
      return subscription
    endif
  endif

  let observer = s:_new_subscription_observer(subscription)
  try
    let Cleanup = a:subscriber(observer)
    if !empty(Cleanup)
      if type(Cleanup) is# v:t_dict && type(get(Cleanup, 'unsubscribe', v:null)) is# v:t_func
        let subscription.__cleanup = { -> Cleanup.unsubscribe() }
      elseif type(Cleanup) isnot# v:t_func
        throw printf(
              \ 'vital: Async.Observable: %s from %s(%s) is not a function',
              \ Cleanup,
              \ a:subscriber,
              \ observer,
              \)
      else
        let subscription.__cleanup = Cleanup
      endif
    endif
  catch
    call observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
    return subscription
  endtry

  if subscription.closed()
    call s:_cleanup_subscription(subscription)
  endif

  return subscription
endfunction

function! s:_subscription_closed() abort dict
  return self.__observer is# v:null
endfunction

function! s:_subscription_unsubscribe() abort dict
  if self.closed()
    return
  endif
  let self.__observer = v:null
  call s:_cleanup_subscription(self)
endfunction

function! s:_cleanup_subscription(subscription) abort
  let Cleanup = a:subscription.__cleanup
  if empty(Cleanup)
    return
  endif
  let a:subscription.__cleanup = v:null
  try
    call Cleanup()
  catch
    call s:_report(v:exception, v:throwpoint)
  endtry
endfunction


" SubscriptionObserver -----------------------------------------------------
function! s:_new_subscription_observer(subscription) abort
  let observer = {
        \ '__subscription': a:subscription,
        \ 'closed': funcref('s:_subscription_observer_closed'),
        \ 'next': funcref('s:_subscription_observer_next'),
        \ 'error': funcref('s:_subscription_observer_error'),
        \ 'complete': funcref('s:_subscription_observer_complete'),
        \}
  return observer
endfunction

function! s:_subscription_observer_closed() abort dict
  return self.__subscription.closed()
endfunction

function! s:_subscription_observer_next(value) abort dict
  let subscription = self.__subscription
  if subscription.closed()
    return
  endif
  let observer = subscription.__observer
  if get(observer, 'next', v:null) isnot# v:null
    try
      call observer.next(a:value)
    catch
      call s:_report(v:exception, v:throwpoint)
    endtry
  endif
endfunction

function! s:_subscription_observer_error(value) abort dict
  let subscription = self.__subscription
  if subscription.closed()
    return
  endif
  let observer = subscription.__observer
  let subscription.__observer = v:null
  if get(observer, 'error', v:null) isnot# v:null
    try
      call observer.error(a:value)
    catch
      call s:_report(v:exception, v:throwpoint)
    endtry
  else
    if type(a:value) is# v:t_dict && has_key(a:value, 'exception')
      call s:_report(a:value.exception, get(a:value, 'throwpoint', ''))
    elseif type(a:value) is# v:t_string
      call s:_report(a:value, '')
    else
      call s:_report(string(a:value), '')
    endif
  endif
  call s:_cleanup_subscription(subscription)
endfunction

function! s:_subscription_observer_complete() abort dict
  let subscription = self.__subscription
  if subscription.closed()
    return
  endif
  let observer = subscription.__observer
  let subscription.__observer = v:null
  if get(observer, 'complete', v:null) isnot# v:null
    try
      call observer.complete()
    catch
      call s:_report(v:exception, v:throwpoint)
    endtry
  endif
  call s:_cleanup_subscription(subscription)
endfunction


" Private ------------------------------------------------------------------
function! s:_report(exception, throwpoint) abort
  let ms = split(a:exception . "\n" . a:throwpoint, '\r\?\n')
  echohl ErrorMsg
  for m in ms
    echomsg m
  endfor
  echohl None
endfunction
