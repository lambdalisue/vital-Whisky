let s:tasks = []
let s:timer = v:null

let s:DEFAULT_WAIT_INTERVAL = 30

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
    let ms = split(v:exception . "\n" . v:throwpoint, '\r\?\n')
    echohl ErrorMsg
    for m in ms
      echomsg m
    endfor
    echohl None
  endtry
  call s:_emit()
endfunction
