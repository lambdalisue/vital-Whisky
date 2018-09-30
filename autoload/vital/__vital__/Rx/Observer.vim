function! s:_vital_loaded(V) abort
  let s:Later = a:V.import('Async.Later')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Async.Later',
        \]
endfunction

function! s:new(...) abort
  let observer = a:0 is# 1 && type(a:1) is# v:t_dict ? a:1 : {
        \ 'next': get(a:, 1, v:null),
        \ 'error': get(a:, 2, v:null),
        \ 'complete': get(a:, 3, v:null),
        \}
  if get(observer, 'next', v:null) is# v:null
    let observer.next = { -> 0 }
  endif
  if get(observer, 'error', v:null) is# v:null
    let observer.error = funcref('s:_observer_error')
  endif
  if get(observer, 'complete', v:null) is# v:null
    let observer.complete = { -> 0 }
  endif
  return observer
endfunction

function! s:_observer_error(error) abort
  if type(a:error) is# v:t_dict && has_key(a:error, 'exception')
    call s:Later.call({ ->
          \ s:_report(a:error.exception, get(a:error, 'throwpoint', ''))
          \})
  elseif type(a:error) is# v:t_string
    call s:Later.call({ -> s:_report(a:error, '') })
  else
    call s:Later.call({ -> s:_report(string(a:error), '') })
  endif
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
