function! s:_vital_loaded(V) abort
  let s:Job = a:V.import('System.Job')
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:_vital_depends() abort
  return ['System.Job', 'Async.Promise']
endfunction

function! s:start(args, ...) abort
  let options = extend({
        \ 'cwd': '.',
        \ 'raw': 0,
        \ 'stdin': s:Promise.reject(),
        \ 'abort': s:Promise.reject(),
        \}, a:0 ? a:1 : {},
        \)
  return s:Promise.new(funcref('s:_executor', [a:args, options]))
endfunction

function! s:is_available() abort
  if !has('patch-8.0.0107') && !has('nvim-0.2.0')
    return 0
  endif
  return s:Promise.is_available() && s:Job.is_available()
endfunction

function! s:_executor(args, options, resolve, ...) abort
  let ns = {
        \ 'args': a:args,
        \ 'stdout': [''],
        \ 'stderr': [''],
        \ 'resolve': a:resolve,
        \}
  let job = s:Job.start(a:args, {
        \ 'cwd': a:options.cwd,
        \ 'on_stdout': a:options.raw
        \   ? funcref('s:_on_receive_raw', [ns.stdout])
        \   : funcref('s:_on_receive', [ns.stdout]),
        \ 'on_stderr': a:options.raw
        \   ? funcref('s:_on_receive_raw', [ns.stderr])
        \   : funcref('s:_on_receive', [ns.stderr]),
        \ 'on_exit': funcref('s:_on_exit', [ns]),
        \})
  call a:options.stdin
        \.then({ v -> job.send(v) })
        \.then({ -> job.close() })
  call a:options.abort
        \.then({ -> job.stop() })
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

function! s:_on_exit(ns, data) abort
  call a:ns.resolve({
        \ 'args': a:ns.args,
        \ 'stdout': a:ns.stdout,
        \ 'stderr': a:ns.stderr,
        \ 'exitval': a:data,
        \})
endfunction
