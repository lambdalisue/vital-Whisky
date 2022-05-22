let s:threshold = 0
let s:conditions = [
      \ { wi -> !wi.loclist },
      \ { wi -> !wi.quickfix },
      \ { wi -> !getwinvar(wi.winid, '&winfixwidth', 0) },
      \ { wi -> !getwinvar(wi.winid, '&winfixheight', 0) },
      \ { wi -> !getbufvar(wi.bufnr, '&previewwindow', 0) },
      \]

" Add condition to make sure that the window is not floating
if exists('*nvim_win_get_config')
  call add(s:conditions, { wi -> nvim_win_get_config(wi.winid).relative ==# '' })
endif

function! s:score(winnr) abort
  let winid = win_getid(a:winnr)
  let wininfo = getwininfo(winid)
  if empty(wininfo)
    return 0
  endif
  let wi = wininfo[0]
  let score = 1
  for Condition in s:conditions
    let score += Condition(wi)
  endfor
  return score
endfunction

function! s:list() abort
  let nwinnr = winnr('$')
  if nwinnr == 1
    return 1
  endif
  let threshold = s:get_threshold()
  while threshold > 0
    let ws = filter(
          \ range(1, winnr('$')),
          \ { -> s:score(v:val) >= threshold }
          \)
    if !empty(ws)
      break
    endif
    let threshold -= 1
  endwhile
  return ws
endfunction

function! s:find(origin) abort
  let nwinnr = winnr('$')
  if nwinnr == 1
    return 1
  endif
  let origin = a:origin == 0 ? winnr() : a:origin
  let former = range(origin, winnr('$'))
  let latter = reverse(range(1, origin - 1))
  let threshold = s:get_threshold()
  while threshold > 0
    for winnr in (former + latter)
      if s:score(winnr) >= threshold
        return winnr
      endif
    endfor
    let threshold -= 1
  endwhile
  return 0
endfunction

function! s:focus(origin) abort
  let winnr = s:find(a:origin)
  if winnr == 0 || winnr == winnr()
    return 1
  endif
  call win_gotoid(win_getid(winnr))
endfunction

function! s:get_conditions() abort
  return copy(s:conditions)
endfunction

function! s:set_conditions(conditions) abort
  let s:conditions = copy(a:conditions)
endfunction

function! s:get_threshold() abort
  return s:threshold is# 0 ? len(s:conditions) + 1 : s:threshold
endfunction

function! s:set_threshold(threshold) abort
  let s:threshold = a:threshold
endfunction
