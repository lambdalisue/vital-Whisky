function! s:_vital_depends() abort
  return [
        \ 'System.Job',
        \ 'Async.Observable',
        \]
endfunction

function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
  let s:Observable = a:V.import('Async.Observable')
endfunction

function! s:_vital_created(module) abort
  let a:module.operators = {
        \ 'focus': funcref('s:_focus'),
        \ 'squash': funcref('s:_squash'),
        \ 'stretch': funcref('s:_stretch'),
        \ 'pile': funcref('s:_pile'),
        \ 'line': funcref('s:_line'),
        \}
endfunction

function! s:new(args, ...) abort
  if !has('patch-8.0.0107') && !has('nvim-0.2.0')
    throw 'vital: Async.Process: Prior to Vim 8.0.0107 or Neovim 0.2.0 is not supported.'
  endif
  let options = extend({
        \ 'cwd': v:null,
        \ 'raw': v:false,
        \ 'stdin': [],
        \}, a:0 ? a:1 : {})
  return s:Observable.new(funcref('s:_process_subscriber', [a:args, options]))
endfunction

function! s:_process_subscriber(args, options, observer) abort
  let job_options = {
        \ 'on_stdout': funcref('s:_on_stdout', [a:options, a:observer]),
        \ 'on_stderr': funcref('s:_on_stderr', [a:options, a:observer]),
        \ 'on_exit': funcref('s:_on_exit', [a:options, a:observer]),
        \}
  if a:options.cwd isnot# v:null
    let job_options.cwd = a:options.cwd
  endif
  let job = s:Job.start(a:args, job_options)
  call a:observer.next({ 'pid': job.pid() })
  let stdin = s:Observable.from(a:options.stdin)
  let subscription = stdin.subscribe({
        \ 'next': { v -> job.send(v) },
        \ 'complete': { -> job.close() },
        \})
  return { -> [subscription.unsubscribe(), job.stop()] }
endfunction

function! s:_on_stdout(options, observer, data) abort
  if !a:options.raw
    call map(a:data, 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
  endif
  call a:observer.next({ 'stdout': a:data })
endfunction

function! s:_on_stderr(options, observer, data) abort
  if !a:options.raw
    call map(a:data, 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
  endif
  call a:observer.next({ 'stderr': a:data })
endfunction

function! s:_on_exit(options, observer, exitval) abort
  if a:exitval is# 0
    call a:observer.complete()
  else
    call a:observer.error(a:exitval)
  endif
endfunction


" Operators-----------------------------------------------------------------
function! s:_focus(key) abort
  return { s -> s:Observable.new(funcref('s:_focus_subscriber', [a:key, s])) }
endfunction

function! s:_focus_subscriber(key, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'key': a:key,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_focus_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_focus_next(ns, observer, value) abort
  let k = a:ns.key
  if type(a:value) isnot# v:t_dict || !has_key(a:value, k)
    return
  endif
  let data = {}
  let data[k] = a:value[k]
  call a:observer.next(data)
endfunction

function! s:_squash(key) abort
  return { s -> s:Observable.new(funcref('s:_squash_subscriber', [a:key, s])) }
endfunction

function! s:_squash_subscriber(key, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'key': a:key,
        \ 'remnant': '',
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_squash_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_squash_complete', [ns, a:observer]),
        \})
endfunction

function! s:_squash_next(ns, observer, value) abort
  let k = a:ns.key
  if type(a:value) isnot# v:t_dict || !has_key(a:value, k)
    call a:observer.next(a:value)
    return
  endif
  let data = {}
  let data[k] = copy(a:value[k])
  let data[k][0] = a:ns.remnant . data[k][0]
  let a:ns.remnant = remove(data[k], -1)
  if !empty(data[k])
    call a:observer.next(data)
  endif
endfunction

function! s:_squash_complete(ns, observer) abort
  if !empty(a:ns.remnant)
    let data = {}
    let data[a:ns.key] = [a:ns.remnant]
    call a:observer.next(data)
  endif
  call a:observer.complete()
endfunction

function! s:_stretch(key) abort
  return { s -> s:Observable.new(funcref('s:_stretch_subscriber', [a:key, s])) }
endfunction

function! s:_stretch_subscriber(key, source, observer) abort
  if a:observer.closed()
    return
  endif
  let ns = {
        \ 'key': a:key,
        \}
  return a:source.subscribe({
        \ 'next': funcref('s:_stretch_next', [ns, a:observer]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_stretch_next(ns, observer, value) abort
  let k = a:ns.key
  if type(a:value) isnot# v:t_dict || !has_key(a:value, k)
    call a:observer.next(a:value)
    return
  endif
  let data = {}
  for value in a:value[k]
    let data[k] = value
    call a:observer.next(data)
  endfor
endfunction

function! s:_pile(key) abort
  return { s -> s:Observable.new(funcref('s:_pile_subscriber', [a:key, s])) }
endfunction

function! s:_pile_subscriber(key, source, observer) abort
  if a:observer.closed()
    return
  endif
  let k = a:key
  let s = a:source.pipe(
        \ s:_focus(k),
        \ s:_squash(k),
        \)
  return s.subscribe({
        \ 'next': { v -> a:observer.next(v[k]) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction

function! s:_line(key) abort
  return { s -> s:Observable.new(funcref('s:_line_subscriber', [a:key, s])) }
endfunction

function! s:_line_subscriber(key, source, observer) abort
  if a:observer.closed()
    return
  endif
  let k = a:key
  let s = a:source.pipe(
        \ s:_focus(k),
        \ s:_squash(k),
        \ s:_stretch(k),
        \)
  return s.subscribe({
        \ 'next': { v -> a:observer.next(v[k]) },
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': { -> a:observer.complete() },
        \})
endfunction
