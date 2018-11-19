function! s:_vital_loaded(V) abort
  let s:Observable = a:V.import('Rx.Observable')
  let s:Subject = a:V.import('Rx.Subject')
  let s:AsyncSubject = a:V.import('Rx.AsyncSubject')
  let s:BehaviorSubject = a:V.import('Rx.BehaviorSubject')
  let s:ReplaySubject = a:V.import('Rx.ReplaySubject')
  let s:ConnectableObservable = a:V.import('Rx.ConnectableObservable')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Rx.Observable',
        \ 'Rx.Subject',
        \ 'Rx.AsyncSubject',
        \ 'Rx.BehaviorSubject',
        \ 'Rx.ReplaySubject',
        \ 'Rx.ConnectableObservable',
        \]
endfunction

function! s:catch_error(project) abort
  return { s, ctor -> ctor(funcref('s:_catch_error_subscriber', [a:project, s])) }
endfunction

function! s:_catch_error_subscriber(project, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'project': a:project,
        \ 'source': a:source,
        \}
  let ns.subscription = a:source.subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': funcref('s:_catch_error_error', [ns, a:observer]),
        \ 'complete': { -> a:observer.complete() },
        \})
  return { -> ns.subscription.unsubscribe() }
endfunction

function! s:_catch_error_error(ns, observer, error) abort
  try
    let a:ns.source = a:ns.project(a:error, a:ns.source)
  catch
    call a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
    return
  endtry
  let a:ns.subscription = a:ns.source.subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': funcref('s:_catch_error_error', [a:ns, a:observer]),
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:concat_map(project) abort
  return s:merge_map(a:project, 1)
endfunction

function! s:default_if_empty(default) abort
  return { s, ctor -> ctor(funcref('s:_default_if_empty_subscriber', [a:default, s])) }
endfunction

function! s:_default_if_empty_subscriber(default, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'default': a:default,
        \ 'empty': v:true,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_default_if_empty_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_default_if_empty_complete', [ns, a:observer]),
        \})
endfunction

function! s:_default_if_empty_next(ns, observer, value) abort
  let a:ns.empty = v:false
  call a:observer.next(a:value)
endfunction

function! s:_default_if_empty_complete(ns, observer) abort
  if a:ns.empty is# v:true
    call a:observer.next(a:ns.default)
  endif
  call a:observer.complete()
endfunction

function! s:delay(delay) abort
  let delayer = s:Observable.timer(a:delay).pipe(s:ignore_elements())
  return { s -> s:Observable.concat(delayer, s) }
endfunction

function! s:every(fn) abort
  return { s, ctor -> ctor(funcref('s:_every_subscriber', [a:fn, s])) }
endfunction

function! s:_every_subscriber(fn, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'fn': a:fn,
        \ 'index': -1,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_every_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_every_complete', [ns, a:observer]),
        \})
endfunction

function! s:_every_next(ns, observer, value) abort
  let a:ns.index += 1
  try
    if !a:ns.fn(a:value, a:ns.index)
      call a:observer.next(v:false)
      call a:observer.complete()
    endif
  catch
    return a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
endfunction

function! s:_every_complete(ns, observer) abort
  call a:observer.next(v:true)
  call a:observer.complete()
endfunction

function! s:filter(fn) abort
  return { s, ctor -> ctor(funcref('s:_filter_subscriber', [a:fn, s])) }
endfunction

function! s:_filter_subscriber(fn, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'fn': a:fn,
        \ 'index': -1,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_filter_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_filter_next(ns, observer, value) abort
  let a:ns.index += 1
  try
    if a:ns.fn(a:value, a:ns.index)
      call a:observer.next(a:value)
    endif
  catch
    return a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
endfunction

function! s:first(...) abort
  let Predicate = a:0 ? a:1 : v:null
  let defaultValue = a:0 > 1 ? a:2 : v:null
  return { s -> s.pipe(
        \ Predicate is# v:null
        \   ? s:identity()
        \   : s:filter({ v, i -> Predicate(v, i, s) }),
        \ s:take(1),
        \ defaultValue is# v:null
        \   ? s:throw_if_empty()
        \   : s:default_if_empty(defaultValue),
        \) }
endfunction

function! s:identity() abort
  return { s -> s }
endfunction

function! s:ignore_elements() abort
  return { s, ctor -> ctor(funcref('s:_ignore_elements_subscriber', [s])) }
endfunction

function! s:_ignore_elements_subscriber(source, observer) abort
  if a:observer.closed()
    return
  endif
  return a:source.subscribe({
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:map(fn) abort
  return { s, ctor -> ctor(funcref('s:_map_subscriber', [a:fn, s])) }
endfunction

function! s:_map_subscriber(fn, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'fn': a:fn,
        \ 'index': 0,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_map_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_map_next(ns, observer, value) abort
  try
    let value = a:ns.fn(a:value, a:ns.index)
  catch
    return a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
  call a:observer.next(value)
  let a:ns.index += 1
endfunction

function! s:merge_map(project, ...) abort
  let concurrent = a:0 ? a:1 : 0
  return { s, ctor -> ctor(funcref('s:_merge_map_subscriber', [a:project, concurrent, s])) }
endfunction

function! s:_merge_map_subscriber(project, concurrent, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'project': a:project,
        \ 'concurrent': a:concurrent,
        \ 'active': 0,
        \ 'index': 0,
        \ 'buffer': [],
        \ 'completed': v:false,
        \ 'subscriptions': [],
        \}
  let ns.outer = a:source.subscribe({
        \ 'next': funcref('s:_merge_map_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_merge_map_complete_if_done', [ns, a:observer]),
        \})
  return funcref('s:_merge_map_cleanup', [ns])
endfunction

function! s:_merge_map_next(ns, observer, value) abort
  if a:ns.concurrent is# 0 || a:ns.active < a:ns.concurrent
    call s:_merge_map_try_next(a:ns, a:observer, a:value)
  else
    call add(a:ns.buffer, a:value)
  endif
endfunction

function! s:_merge_map_try_next(ns, observer, value) abort
  try
    let value = a:ns.project(a:value, a:ns.index)
  catch
    return a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
  let a:ns.index += 1
  let a:ns.active += 1
  let inner = {}
  let inner.subscription = s:Observable.from(value).subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_merge_map_complete_inner', [a:ns, inner, a:observer]),
        \})
  call add(a:ns.subscriptions, inner.subscription)
endfunction

function! s:_merge_map_complete_inner(ns, inner, observer) abort
  call remove(
        \ a:ns.subscriptions,
        \ index(a:ns.subscriptions, a:inner.subscription),
        \)
  let a:ns.active -= 1
  if !empty(a:ns.buffer)
    call s:_merge_map_next(a:ns, a:observer, remove(a:ns.buffer, 0))
  elseif a:ns.active is# 0 && a:ns.completed
    call a:observer.complete()
  endif
endfunction

function! s:_merge_map_complete_if_done(ns, observer) abort
  let a:ns.completed = v:true
  if a:ns.active is# 0 && empty(a:ns.buffer)
    call a:observer.complete()
  endif
endfunction

function! s:_merge_map_cleanup(ns) abort
  call map(a:ns.subscriptions, { -> v:val.unsubscribe() })
  call a:ns.outer.unsubscribe()
endfunction

function! s:multicast(subject) abort
  return funcref('s:_multicast', [a:subject])
endfunction

function! s:_multicast(subject, source, ...) abort
  if a:subject is# v:null
    let subject = s:Subject.new()
  elseif type(a:subject) is# v:t_dict
    let subject = a:subject
  elseif type(a:subject) is# v:t_func
    let subject = a:subject()
  else
    throw 'vital: Rx.Operators: subject must be a suject instance or a factory function'
  endif
  return s:ConnectableObservable.new(a:source, subject)
endfunction

function! s:ref_count() abort
  return { s, ctor -> ctor(funcref('s:_ref_count_subscriber', [s])) }
endfunction

function! s:_ref_count_subscriber(source, observer) abort
  if a:observer.closed()
    return
  endif
  let a:source.__ref_count += 1
  let ns = {
        \ 'subscription': a:source.subscribe(a:observer),
        \ 'connection': a:source.connect(),
        \}
  return funcref('s:_ref_count_cleanup', [ns, a:source])
endfunction

function! s:_ref_count_cleanup(ns, source) abort
  call a:ns.subscription.unsubscribe()
  let a:source.__ref_count -= 1
  if a:source.__ref_count > 0
    return
  endif
  let connection = a:ns.connection
  let a:ns.connection = v:null
  call connection.unsubscribe()
endfunction

function! s:reduce(fn, ...) abort
  let has_seed = a:0 isnot# 0
  let accumulate = a:0 ? a:1 : v:null
  return { s, ctor -> ctor(funcref('s:_reduce_subscriber', [a:fn, has_seed, accumulate, s])) }
endfunction

function! s:_reduce_subscriber(fn, has_seed, accumulate, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'fn': a:fn,
        \ 'index': 0,
        \ 'has_seed': a:has_seed,
        \ 'accumulate': copy(a:accumulate),
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_reduce_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_reduce_complete', [ns, a:observer]),
        \})
endfunction

function! s:_reduce_next(ns, observer, value) abort
  if a:ns.index isnot# 0 || a:ns.has_seed
    try
      let a:ns.accumulate = a:ns.fn(a:ns.accumulate, a:value, a:ns.index)
    catch
      return a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  else
    let a:ns.accumulate = a:value
  endif
  let a:ns.index += 1
endfunction

function! s:_reduce_complete(ns, observer) abort
  if a:ns.index is# 0 && a:ns.has_seed is# 0
    call a:observer.error({
          \ 'exception': 'vital: Rx.Operators: Cannot reduce an empty sequence',
          \})
    return
  endif
  call a:observer.next(a:ns.accumulate)
  call a:observer.complete()
endfunction

function! s:publish(...) abort
  return s:multicast(call(s:Subject.new, a:000, s:Subject))
endfunction

function! s:publish_behavior(...) abort
  return s:multicast(call(s:BehaviorSubject.new, a:000, s:BehaviorSubject))
endfunction

function! s:publish_last(...) abort
  return s:multicast(call(s:AsyncSubject.new, a:000, s:AsyncSubject))
endfunction

function! s:publish_replay(...) abort
  return s:multicast(call(s:ReplaySubject.new, a:000, s:ReplaySubject))
endfunction

function! s:pluck(...) abort
  if a:0 is# 0
    throw 'vital: Rx.Operators.pluck: At least one property is required'
  endif
  let properties = copy(a:000)
  return { s, ctor -> ctor(funcref('s:_pluck_subscriber', [properties, s])) }
endfunction

function! s:_pluck_subscriber(properties, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'properties': a:properties,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_pluck_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_pluck_next(ns, observer, value) abort
  let value = a:value
  for property in a:ns.properties
    if type(value) isnot# v:t_dict || !has_key(value, property)
      call a:observer.next(v:null)
      return
    endif
    let value = value[property]
  endfor
  call a:observer.next(value)
endfunction

function! s:scan(fn, ...) abort
  let has_seed = a:0 isnot# 0
  let accumulate = a:0 ? a:1 : v:null
  return { s, ctor -> ctor(funcref('s:_scan_subscriber', [a:fn, has_seed, accumulate, s])) }
endfunction

function! s:_scan_subscriber(fn, has_seed, accumulate, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'fn': a:fn,
        \ 'index': 0,
        \ 'has_seed': a:has_seed,
        \ 'accumulate': copy(a:accumulate),
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_scan_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() }
        \})
endfunction

function! s:_scan_next(ns, observer, value) abort
  if a:ns.index isnot# 0 || a:ns.has_seed
    try
      let a:ns.accumulate = a:ns.fn(a:ns.accumulate, a:value, a:ns.index)
    catch
      return a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  else
    let a:ns.accumulate = a:value
  endif
  call a:observer.next(a:ns.accumulate)
  let a:ns.index += 1
endfunction

function! s:share() abort
  return { s -> s.pipe(s:publish(), s:ref_count()) }
endfunction

function! s:share_replay(...) abort
  let args = a:000
  return { s -> s.pipe(call('s:publish_replay', args), s:ref_count()) }
endfunction

function! s:skip(the) abort
  if a:the < 0
    throw 'vital: Rx.Operators: invalid the has specified'
  endif
  return { s, ctor -> ctor(funcref('s:_skip_subscriber', [a:the, s])) }
endfunction

function! s:_skip_subscriber(the, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'the': a:the,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_skip_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_skip_next(ns, observer, value) abort
  if a:ns.the is# 0
    call a:observer.next(a:value)
  else
    let a:ns.the -= 1
  endif
endfunction

function! s:skip_until(notifier) abort
  return { s, ctor -> ctor(funcref('s:_skip_until_subscriber', [a:notifier, s])) }
endfunction

function! s:_skip_until_subscriber(notifier, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'seen': v:false
        \}
  let ns.source = a:source.subscribe({
        \ 'next': funcref('s:_skip_until_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
  let ns.notifier = a:notifier.subscribe({
        \ 'next': funcref('s:_skip_until_next_notifier', [ns, a:observer]),
        \})
  return { -> map([ns.source, ns.notifier], { -> v:val.unsubscribe }) }
endfunction

function! s:_skip_until_next(ns, observer, value) abort
  if a:ns.seen
    call a:observer.next(a:value)
  endif
endfunction

function! s:_skip_until_next_notifier(ns, observer, value) abort
  let a:ns.seen = v:true
  call a:ns.notifier.unsubscribe()
endfunction

function! s:start_with(...) abort
  let items = a:000
  return { s -> s:Observable.concat(s:Observable.from(items), s) }
endfunction

function! s:switch_map(project, ...) abort
  return { s, ctor -> ctor(funcref('s:_switch_map_subscriber', [a:project, s])) }
endfunction

function! s:_switch_map_subscriber(project, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'project': a:project,
        \ 'index': 0,
        \ 'inner': v:null,
        \}
  let ns.outer = a:source.subscribe({
        \ 'next': funcref('s:_switch_map_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_switch_map_complete_if_done', [ns, a:observer]),
        \})
  return funcref('s:_switch_map_cleanup', [ns])
endfunction

function! s:_switch_map_next(ns, observer, value) abort
  try
    let value = a:ns.project(a:value, a:ns.index)
  catch
    return a:observer.error({
          \ 'exception': v:exception,
          \ 'throwpoint': v:throwpoint,
          \})
  endtry
  let a:ns.index += 1
  if !empty(a:ns.inner)
    call a:ns.inner.unsubscribe()
  endif
  let a:ns.inner = s:Observable.from(value).subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_switch_map_complete_inner', [a:ns, a:observer]),
        \})
endfunction

function! s:_switch_map_complete_inner(ns, observer) abort
  let a:ns.inner = v:null
  if a:ns.outer.closed()
    call a:observer.complete()
  endif
endfunction

function! s:_switch_map_complete_if_done(ns, observer) abort
  if empty(a:ns.inner) || a:ns.inner.closed()
    call a:observer.complete()
  endif
endfunction

function! s:_switch_map_cleanup(ns) abort
  if !empty(a:ns.inner)
    call a:ns.inner.unsubscribe()
  endif
  call a:ns.outer.unsubscribe()
endfunction

function! s:take(count) abort
  if a:count < 0
    throw 'vital: Rx.Operators: invalid count has specified'
  endif
  return { s, ctor -> ctor(funcref('s:_take_subscriber', [a:count, s])) }
endfunction

function! s:_take_subscriber(count, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'count': a:count,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_take_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_take_next(ns, observer, value) abort
  call a:observer.next(a:value)
  let a:ns.count -= 1
  if a:ns.count is# 0
    call a:observer.complete()
  endif
endfunction

function! s:take_until(notifier) abort
  return { s, ctor -> ctor(funcref('s:_take_until_subscriber', [a:notifier, s])) }
endfunction

function! s:_take_until_subscriber(notifier, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {}
  let ns.source = a:source.subscribe({
        \ 'next': { v -> a:observer.next(v) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() }
        \})
  let ns.notifier = a:notifier.subscribe({ -> a:observer.complete() })
  return { -> map([ns.source, ns.notifier], { -> v:val.unsubscribe() }) }
endfunction

function! s:tap(...) abort
  if a:0 is# 1 && type(a:1) is# v:t_dict
    let sniffer = a:1
  else
    let sniffer = {
          \ 'next': get(a:, 1, v:null),
          \ 'error': get(a:, 2, v:null),
          \ 'complete': get(a:, 3, v:null),
          \}
  endif
  return { s, ctor -> ctor(funcref('s:_tap_subscriber', [sniffer, s])) }
endfunction

function! s:_tap_subscriber(sniffer, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'sniffer': a:sniffer,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_tap_next', [ns, a:observer]),
        \ 'error': funcref('s:_tap_error', [ns, a:observer]),
        \ 'complete': funcref('s:_tap_complete', [ns, a:observer]),
        \})
endfunction

function! s:_tap_next(ns, observer, value) abort
  if get(a:ns.sniffer, 'next', v:null) isnot# v:null
    try
      call a:ns.sniffer.next(a:value)
    catch
      return a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  endif
  call a:observer.next(a:value)
endfunction

function! s:_tap_error(ns, observer, error) abort
  if get(a:ns.sniffer, 'error', v:null) isnot# v:null
    try
      call a:ns.sniffer.error(a:error)
    catch
      return a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  endif
  call a:observer.error(a:error)
endfunction

function! s:_tap_complete(ns, observer) abort
  if get(a:ns.sniffer, 'complete', v:null) isnot# v:null
    try
      call a:ns.sniffer.complete()
    catch
      return a:observer.error({
            \ 'exception': v:exception,
            \ 'throwpoint': v:throwpoint,
            \})
    endtry
  endif
  call a:observer.complete()
endfunction

function! s:throw_if_empty(...) abort
  let EMPTY_ERROR = 'vital: Rx.Operators.throwIfEmpty: Empty observable'
  let Factory = a:0 ? a:1 : { -> EMPTY_ERROR }
  let ns = {
        \ 'empty': v:true,
        \ 'factory': Factory,
        \}
  return s:tap({
        \ 'next': funcref('s:_throw_if_empty_next', [ns]),
        \ 'complete': funcref('s:_throw_if_empty_complete', [ns]),
        \})
endfunction

function! s:_throw_if_empty_next(ns, value) abort
  let a:ns.empty = v:false
endfunction

function! s:_throw_if_empty_complete(ns) abort
  if a:ns.empty is# v:true
    throw a:ns.factory()
  endif
endfunction

function! s:timeout(due) abort
  let TIMEOUT_ERROR = 'vital: Rx.Operators: Timeout error'
  let timer = s:Observable.concat(
        \ s:Observable.timer(a:due),
        \ s:Observable.throw_error(TIMEOUT_ERROR),
        \)
  return { s -> s:Observable.race(timer, s) }
endfunction
