function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
  let s:Promise = a:V.import('Async.Promise')
  let s:CancellationToken = a:V.import('Async.CancellationToken')
endfunction

function! s:_vital_depends() abort
  return ['System.Job', 'Async.Promise', 'Async.CancellationToken']
endfunction

function! s:start(args, ...) abort
  let options = extend({
        \ 'cwd': '.',
        \ 'raw': 0,
        \ 'stdin': s:Promise.reject(),
        \ 'token': s:CancellationToken.none,
        \ 'reject_on_failure': v:false,
        \}, a:0 ? a:1 : {},
        \)
  let p = s:Promise.new(funcref('s:_executor', [a:args, options]))
  if options.reject_on_failure
    let p = p.then(funcref('s:_reject_on_failure'))
  endif
  return p
endfunction

function! s:is_available() abort
  if !has('patch-8.0.0107') && !has('nvim-0.2.0')
    return 0
  endif
  return s:Promise.is_available() && s:Job.is_available()
endfunction

function! s:_reject_on_failure(result) abort
  if a:result.exitval
    return s:Promise.reject(a:result)
  endif
  return a:result
endfunction

function! s:_executor(args, options, resolve, reject) abort
  call a:options.token.throw_if_cancellation_requested()

  let ns = {
        \ 'args': a:args,
        \ 'stdout': [''],
        \ 'stderr': [''],
        \ 'resolve': a:resolve,
        \ 'reject': a:reject,
        \ 'token': a:options.token,
        \}
  let reg = ns.token.register(funcref('s:_on_cancel', [ns]))
  let ns.job = s:Job.start(a:args, {
        \ 'cwd': a:options.cwd,
        \ 'on_stdout': a:options.raw
        \   ? funcref('s:_on_receive_raw', [ns.stdout])
        \   : funcref('s:_on_receive', [ns.stdout]),
        \ 'on_stderr': a:options.raw
        \   ? funcref('s:_on_receive_raw', [ns.stderr])
        \   : funcref('s:_on_receive', [ns.stderr]),
        \ 'on_exit': funcref('s:_on_exit', [reg, ns]),
        \})
  call a:options.stdin
        \.then({ v -> ns.job.send(v) })
        \.then({ -> ns.job.close() })
  if has_key(a:options, 'abort')
    echohl WarningMsg
    echomsg 'vital: Async.Promise.Process: The "abort" has deprecated. Use "token" instead.'
    echohl None
    call a:options.abort
          \.then({ -> ns.job.stop() })
  endif
endfunction

function! s:_on_receive(buffer, data) abort
  call map(a:data, 'v:val[-1:] ==# "\r" ? v:val[:-2] : v:val')
  let a:buffer[-1] .= a:data[0]
  call extend(a:buffer, a:data[1:])
endfunction

function! s:_on_receive_raw(buffer, data) abort
  let a:buffer[-1] .= a:data[0]
  call extend(a:buffer, a:data[1:])
endfunction

function! s:_on_exit(reg, ns, data) abort
  call a:reg.unregister()
  call a:ns.resolve({
        \ 'args': a:ns.args,
        \ 'stdout': a:ns.stdout,
        \ 'stderr': a:ns.stderr,
        \ 'exitval': a:data,
        \})
endfunction

function! s:_on_cancel(ns, ...) abort
  call a:ns.job.stop()
  call a:ns.reject(s:CancellationToken.CancelledError)
endfunction
