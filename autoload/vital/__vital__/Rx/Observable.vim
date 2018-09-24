function! s:_vital_depends() abort
  return [
        \ 'Async.Observable',
        \]
endfunction

function! s:_vital_loaded(V) abort
  let s:Observable = a:V.import('Async.Observable')
endfunction

function! s:new(...) abort
  return call(s:Observable.new, a:000, s:Observable)
endfunction

function! s:of(...) abort
  return call(s:Observable.of, a:000, s:Observable)
endfunction

function! s:from(...) abort
  return call(s:Observable.from, a:000, s:Observable)
endfunction

function! s:wait(...) abort
  return call(s:Observable.wait, a:000, s:Observable)
endfunction

function! s:is_observable(...) abort
  return call(s:Observable.is_observable, a:000, s:Observable)
endfunction

" Creation -----------------------------------------------------------------
function! s:empty() abort
  return s:new({ o -> o.complete() })
endfunction

function! s:never() abort
  return s:new({ -> 0 })
endfunction

function! s:range(start, count) abort
  return s:from(range(a:start, a:start + a:count - 1))
endfunction

function! s:scalar(value) abort
  return s:new(funcref('s:_scalar_subscriber', [a:value]))
endfunction

function! s:_scalar_subscriber(value, observer) abort
  call a:observer.next(a:value)
  call a:observer.complete()
endfunction

function! s:throw_error(error) abort
  return s:new({ o -> o.error(a:error) })
endfunction

function! s:interval(period) abort
  return s:new(funcref('s:_interval_subscriber', [a:period]))
endfunction

function! s:_interval_subscriber(period, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = { 'index': 0 }
  let ns.timer = timer_start(
        \ a:period,
        \ funcref('s:_interval_callback', [ns, a:observer]),
        \ { 'repeat': -1 },
        \)
  return { -> timer_stop(ns.timer) }
endfunction

function! s:_interval_callback(ns, observer, ...) abort
  call a:observer.next(a:ns.index)
  let a:ns.index += 1
endfunction

function! s:timer(delay, ...) abort
  if a:0 is# 0
    return s:new(funcref('s:_timer_subscriber', [a:delay]))
  else
    return s:new(funcref('s:_timer_period_subscriber', [a:delay, a:1]))
  endif
endfunction

function! s:_timer_subscriber(delay, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {}
  let ns.timer = timer_start(a:delay, { -> s:_timer_callback(a:observer) })
  return { -> timer_stop(ns.timer) }
endfunction

function! s:_timer_callback(observer) abort
  call a:observer.next(0)
  call a:observer.complete()
endfunction

function! s:_timer_period_subscriber(delay, period, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = { 'index': 0, 'period': a:period }
  let ns.timer = timer_start(
        \ a:delay,
        \ funcref('s:_timer_period_callback', [ns, a:observer]),
        \)
  return { -> timer_stop(ns.timer) }
endfunction

function! s:_timer_period_callback(ns, observer, ...) abort
  call a:observer.next(a:ns.index)
  let a:ns.index += 1
  let a:ns.timer = timer_start(
        \ a:ns.period,
        \ funcref('s:_timer_period_callback_repeat', [a:ns, a:observer]),
        \ { 'repeat': -1 },
        \)
endfunction

function! s:_timer_period_callback_repeat(ns, observer, ...) abort
  call a:observer.next(a:ns.index)
  let a:ns.index += 1
endfunction


" Combination --------------------------------------------------------------
function! s:combine_latest(...) abort
  let sources = copy(a:000)
  let Project = type(sources[-1]) is# v:t_func
        \ ? remove(sources, -1)
        \ : { v -> v }
  return s:new(funcref('s:_combine_latest_subscriber', [sources, Project]))
endfunction

function! s:_combine_latest_subscriber(sources, project, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'ready': v:false,
        \ 'project': a:project,
        \ 'inners': [],
        \ 'subscriptions': [],
        \}
  for source in a:sources
    let i = { 'buffer': [], 'completed': v:false }
    let subscription = source.subscribe({
          \ 'next': funcref('s:_combine_latest_next', [ns, a:observer, i]),
          \ 'error': { e -> a:observer.error(e) },
          \ 'complete': funcref('s:_combine_latest_complete', [ns, a:observer, i]),
          \})
    call add(ns.inners, i)
    call add(ns.subscriptions, subscription)
  endfor
  return { -> map(ns.subscriptions, { -> v:val.unsubscribe() }) }

endfunction

function! s:_combine_latest_next(ns, observer, inner, value) abort
  call add(a:inner.buffer, a:value)
  if len(a:inner.buffer) > 5
    let a:inner.buffer = [a:inner.buffer[-1]]
  endif
  if a:ns.ready || len(filter(copy(a:ns.inners), { -> empty(v:val.buffer) })) is# 0
    let a:ns.ready = v:true
    let value = map(copy(a:ns.inners), { -> v:val.buffer[-1] })
    try
      call a:observer.next(a:ns.project(value))
    catch
      call a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  endif
endfunction

function! s:_combine_latest_complete(ns, observer, inner) abort
  let a:inner.completed = v:true
  if len(filter(copy(a:ns.inners), { _, v -> !v.completed })) is# 0
    call a:observer.complete()
  endif
endfunction

function! s:concat(...) abort
  return s:new(funcref('s:_concat_subscriber', [a:000]))
endfunction

function! s:_concat_subscriber(sources, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'sources': copy(a:sources),
        \ 'subscription': v:null,
        \}
  let source = remove(ns.sources, 0)
  call s:_concat_start_next(ns, a:observer, source)
  return { -> s:_concat_cleanup(ns) }
endfunction

function! s:_concat_start_next(ns, observer, next) abort
  let a:ns.subscription = a:next.subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_concat_complete', [a:ns, a:observer]),
        \})
endfunction

function! s:_concat_complete(ns, observer) abort
  if empty(a:ns.sources)
    let a:ns.subscription = v:null
    call a:observer.complete()
  else
    call s:_concat_start_next(
          \ a:ns,
          \ a:observer,
          \ s:from(remove(a:ns.sources, 0)),
          \)
  endif
endfunction

function! s:_concat_cleanup(ns) abort
  if a:ns.subscription isnot# v:null
    call a:ns.subscription.unsubscribe()
    let a:ns.subscription = v:null
  endif
endfunction

function! s:merge(...) abort
  return s:new(funcref('s:_merge_subscriber', [a:000]))
endfunction

function! s:_merge_subscriber(sources, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'subscriptions': [],
        \}
  for source in a:sources
    let i = {}
    let i.subscription = source.subscribe({
          \ 'next': { v -> a:observer.next(v) },
          \ 'error': { e -> a:observer.error(e) },
          \ 'complete': funcref('s:_merge_complete', [ns, a:observer, i]),
          \})
    call add(ns.subscriptions, i.subscription)
  endfor
  return { -> map(ns.subscriptions, { -> v:val.unsubscribe() }) }
endfunction

function! s:_merge_complete(ns, observer, inner) abort
  let i = index(a:ns.subscriptions, a:inner.subscription)
  if i isnot# -1
    call remove(a:ns.subscriptions, i)
  endif
  if empty(a:ns.subscriptions)
    call a:observer.complete()
  endif
endfunction

function! s:race(...) abort
  return s:new(funcref('s:_race_subscriber', [a:000]))
endfunction

function! s:_race_subscriber(sources, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'winner': v:null,
        \ 'subscription': v:null,
        \ 'subscriptions': [],
        \}
  for source in a:sources
    let i = { 'source': source }
    let i.subscription = source.subscribe({
          \ 'next': funcref('s:_race_next', [ns, a:observer, i]),
          \ 'error': { e -> a:observer.error(e) },
          \ 'complete': { -> a:observer.complete() },
          \})
    call add(ns.subscriptions, i.subscription)
  endfor
  return { -> map(ns.subscriptions, { -> v:val.unsubscribe() }) }
endfunction

function! s:_race_next(ns, observer, inner, value) abort
  if a:ns.winner isnot# v:null
    call a:observer.next(a:value)
    return
  endif
  let subscriptions = copy(a:ns.subscriptions)
  let a:ns.subscriptions = []
  let a:ns.winner = {
        \ 'source': a:inner.source,
        \ 'subscription': a:inner.subscription,
        \}
  let i = index(subscriptions, a:inner.subscription)
  if i isnot# -1
    call remove(subscriptions, i)
  endif
  call map(subscriptions, { _, v -> v.unsubscribe() })
  call a:observer.next(a:value)
endfunction

function! s:zip(...) abort
  return s:new(funcref('s:_zip_subscriber', [a:000]))
endfunction

function! s:_zip_subscriber(sources, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'inners': [],
        \ 'subscriptions': [],
        \}
  for source in a:sources
    let i = { 'buffer': [], 'completed': v:false }
    let subscription = source.subscribe({
          \ 'next': funcref('s:_zip_next', [ns, a:observer, i]),
          \ 'error': { e -> a:observer.error(e) },
          \ 'complete': funcref('s:_zip_complete', [ns, a:observer, i]),
          \})
    call add(ns.inners, i)
    call add(ns.subscriptions, subscription)
  endfor
  return { -> map(ns.subscriptions, { -> v:val.unsubscribe() }) }
endfunction

function! s:_zip_next(ns, observer, inner, value) abort
  call add(a:inner.buffer, a:value)
  if len(filter(copy(a:ns.inners), { -> empty(v:val.buffer) })) is# 0
    let value = map(copy(a:ns.inners), { -> remove(v:val.buffer, 0) })
    try
      call a:observer.next(value)
    catch
      call a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  endif
  if len(filter(copy(a:ns.inners), { _, v -> v.completed && empty(v.buffer) })) > 0
    call a:observer.complete()
  endif
endfunction

function! s:_zip_complete(ns, observer, inner) abort
  let a:inner.completed = v:true
  if empty(a:inner.buffer)
    call a:observer.complete()
  endif
endfunction
