function! s:_vital_created(module) abort
  let a:module.operators = {
        \ 'focus': { -> call(s:Process.operators.focus, a:000, s:Process.operators) },
        \ 'squash': { -> call(s:Process.operators.squash, a:000, s:Process.operators) },
        \ 'stretch': { -> call(s:Process.operators.stretch, a:000, s:Process.operators) },
        \ 'pile': { -> call(s:Process.operators.pile, a:000, s:Process.operators) },
        \ 'line': { -> call(s:Process.operators.line, a:000, s:Process.operators) },
        \}
  echohl Error
  echo 'vital: Async.Process is deprecated. Use Async.Observable.Process instead.'
  echohl None
endfunction

function! s:_vital_loaded(V) abort
  let s:Process = a:V.import('Async.Observable.Process')
endfunction

function! s:_vital_depends() abort
  return ['Async.Observable.Process']
endfunction

function! s:new(...) abort
  return call(s:Process.new, a:000, s:Process)
endfunction

function! s:start(...) abort
  return call(s:Process.start, a:000, s:Process)
endfunction
