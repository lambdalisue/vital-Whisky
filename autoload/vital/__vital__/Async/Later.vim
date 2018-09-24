let s:tasks = []
let s:timer = v:null

let s:DEFAULT_WAIT_INTERVAL = 30

function! s:_vital_loaded(V) abort
  let s:Error = a:V.import('Error')
endfunction

function! s:_vital_depends() abort
  return ['Error']
endfunction

function! s:_vital_healthcheck() abort
  if (v:version >= 800 && !has('nvim')) || has('nvim-0.2.0')
    return
  endif
  return 'This module requires Vim 8.0.0000 or Neovim 0.2.0'
endfunction


function! s:call(fn, ...) abort
  call add(s:tasks, [a:fn, a:000])
  call s:_emit()
endfunction


function! s:_emit() abort
  if v:dying || s:timer isnot# v:null || empty(s:tasks)
    return
  endif
  let s:timer = timer_start(0, funcref('s:_callback'))
endfunction

function! s:_callback(timer) abort
  let s:timer = v:null
  if v:dying || empty(s:tasks)
    return
  endif
  try
    call call('call', remove(s:tasks, 0))
  catch
    call s:Error.catch().echomsg()
  endtry
  call s:_emit()
endfunction
