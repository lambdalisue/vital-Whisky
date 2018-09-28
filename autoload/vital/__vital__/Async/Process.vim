function! s:_vital_healthcheck() abort
  if has('patch-8.0.0027') || has('nvim-0.2.0')
    return
  endif
  return 'This module requires Vim 8.0.0027 or Neovim 0.2.0'
endfunction

function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
  let s:Promise = a:V.import('Async.Promise')
  let s:Observable = a:V.import('Async.Observable')
  let s:CancellationToken = a:V.import('Async.CancellationToken')
  let s:Operators = a:V.import('Async.Observable.Operators.Reduce')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'System.Job',
        \ 'Async.Promise',
        \ 'Async.Observable',
        \ 'Async.Observable.Operators.Reduce',
        \ 'Async.CancellationToken',
        \]
endfunction

function! s:_extend(buffer, data) abort
  if empty(a:data)
    return a:buffer
  endif
  let a:buffer[-1] .= a:data[0]
  return extend(a:buffer, a:data[1:])
endfunction

function! s:read(channel) abort
  return a:channel
        \.let(s:Operators.reduce({ a, v -> s:_extend(copy(a), v) }))
        \.to_promise()
endfunction

function! s:flatten(channel) abort
  return s:Observable.new(funcref('s:_flatten_subscribe', [a:channel]))
endfunction

function! s:_flatten_subscribe(channel, observer) abort
  let ns = { 'previous': '', 'observer': a:observer }
  return a:channel.subscribe({
        \ 'next': funcref('s:_flatten_on_next', [ns]),
        \ 'error': { e -> a:observer.error(e) },
        \ 'complete': funcref('s:_flatten_on_complete', [ns]),
        \})
endfunction

function! s:_flatten_on_next(ns, value) abort
  let value = copy(a:value)
  let value[0] = a:ns.previous . value[0]
  let a:ns.previous = remove(value, -1)
  for line in value
    call a:ns.observer.next(line)
  endfor
endfunction

function! s:_flatten_on_complete(ns) abort
  call a:ns.observer.next(a:ns.previous)
  call a:ns.observer.complete()
endfunction

function! s:start(args, ...) abort
  let ns = {'stdout': [''], 'stderr': ['']}
  let options = extend({
        \ 'token': s:CancellationToken.none,
        \ 'stdin': v:true,
        \ 'stdout': v:true,
        \ 'stderr': v:true,
        \}, a:0 ? a:1 : {},
        \)
  let job_options = {
        \ 'on_exit': funcref('s:_on_exit', [ns]),
        \}
  if options.stdout
    let job_options.on_stdout = funcref('s:_on_stdout', [ns])
  endif
  if options.stderr
    let job_options.on_stderr = funcref('s:_on_stderr', [ns])
  endif
  if has_key(options, 'cwd')
    let job_options.cwd = options.cwd
  endif
  let ns.reg = options.token.register(funcref('s:_on_cancel', [ns]))
  let ns.job = s:Job.start(a:args, job_options)

  if options.stdin
    call s:Observable.new({ o -> extend(ns, {'stdin_observer': o}) })
          \.subscribe({
          \ 'next': { v -> ns.job.send(v) },
          \ 'complete': { -> ns.job.close() },
          \})
  else
    " Close stdin channel
    call ns.job.close()
  endif

  let status = s:Promise.new(funcref('s:_status_resolver', [options, ns]))
  let stdin = get(ns, 'stdin_observer', v:null)
  let stdout = options.stdout
        \ ? s:Observable.new(funcref('s:_stdout_subscribe', [options, ns]))
        \ : v:null
  let stderr = options.stderr
        \ ? s:Observable.new(funcref('s:_stderr_subscribe', [options, ns]))
        \ : v:null
  return {
        \ 'pid': ns.job.pid,
        \ 'status': status,
        \ 'stdin': stdin,
        \ 'stdout': stdout,
        \ 'stderr': stderr,
        \}
endfunction

function! s:_on_stdout(ns, data) abort
  if has_key(a:ns, 'stdout_observer')
    call a:ns.stdout_observer.next(a:data)
  endif
  call s:_extend(a:ns.stdout, a:data)
endfunction

function! s:_on_stderr(ns, data) abort
  if has_key(a:ns, 'stderr_observer')
    call a:ns.stderr_observer.next(a:data)
  endif
  call s:_extend(a:ns.stderr, a:data)
endfunction

function! s:_on_exit(ns, status) abort
  if has_key(a:ns, 'stdout_observer')
    call a:ns.stdout_observer.complete()
  endif
  if has_key(a:ns, 'stderr_observer')
    call a:ns.stderr_observer.complete()
  endif
  if has_key(a:ns, 'status_promise')
    call a:ns.status_promise.resolve(a:status)
  endif
  let a:ns.status = a:status
  call a:ns.reg.unregister()
endfunction

function! s:_on_cancel(ns) abort
  let error = s:CancellationToken.CancelledError
  if has_key(a:ns, 'job')
    call a:ns.job.stop()
  endif
  if has_key(a:ns, 'stdout_observer')
    call a:ns.stdout_observer.error(error)
  endif
  if has_key(a:ns, 'stderr_observer')
    call a:ns.stderr_observer.error(error)
  endif
  if has_key(a:ns, 'status_promise')
    call a:ns.status_promise.reject(error)
  endif
endfunction

function! s:_stdout_subscribe(options, ns, observer) abort
  call a:options.token.throw_if_cancellation_requested()

  call a:observer.next(a:ns.stdout)
  if has_key(a:ns, 'status')
    call a:observer.complete()
  endif
  let a:ns.stdout_observer = a:observer
endfunction

function! s:_stderr_subscribe(options, ns, observer) abort
  call a:options.token.throw_if_cancellation_requested()

  call a:observer.next(a:ns.stderr)
  if has_key(a:ns, 'status')
    call a:observer.complete()
  endif
  let a:ns.stderr_observer = a:observer
endfunction

function! s:_status_resolver(options, ns, resolve, reject) abort
  call a:options.token.throw_if_cancellation_requested()

  if has_key(a:ns, 'status')
    call a:resolve(a:ns.status)
  endif
  let a:ns.status_promise = {
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \}
endfunction
