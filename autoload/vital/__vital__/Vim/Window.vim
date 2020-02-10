let s:t_string = type('')
let s:DEFAULT_OPTIONS = {
      \ 'range': 'tabpage',
      \}

function! s:focus_window(expr, ...) abort
  let options = extend(copy(s:DEFAULT_OPTIONS), a:0 ? a:1 : {})
  let winid = s:_find_nearest_window_winid(a:expr, options.range)
  if winid == 0
    return v:null
  endif
  let guard = copy(s:guard)
  let guard.winid = win_getid()
  if winid != guard.winid
    call win_gotoid(winid)
  endif
  return guard
endfunction

function! s:focus_buffer(expr, ...) abort
  let options = extend(copy(s:DEFAULT_OPTIONS), a:0 ? a:1 : {})
  let winid = s:_find_nearest_buffer_winid(a:expr, options.range)
  if winid == 0
    return v:null
  endif
  let guard = copy(s:guard)
  let guard.winid = win_getid()
  if winid != guard.winid
    call win_gotoid(winid)
  endif
  return guard
endfunction


" Guard ----------------------------------------------------------------------
let s:guard = {}

function! s:guard.restore() abort
  let winid = self.winid
  if winid != win_getid()
    call win_gotoid(winid)
  endif
endfunction


" Private --------------------------------------------------------------------
function! s:_find_nearest_window_winid(expr, range) abort
  let ntabpages = tabpagenr('$')
  if a:range ==# 'tabpage' || ntabpages == 1
    return win_getid(type(a:expr) == s:t_string ? winnr(a:expr) : a:expr)
  endif
  let Distance = function('s:_distance', [tabpagenr()])
  for tabpagenr in sort(range(1, ntabpages), Distance)
    let winnr = type(a:expr) == s:t_string
          \ ? tabpagewinnr(tabpagenr, a:expr)
          \ : a:expr
    if winnr > 0 && winnr <= tabpagewinnr(tabpagenr, '$')
      return win_getid(winnr, tabpagenr)
    endif
  endfor
  return 0
endfunction

function! s:_find_nearest_buffer_winid(expr, range) abort
  let bufnr = type(a:expr) == s:t_string ? bufnr(a:expr) : a:expr
  let ntabpages = tabpagenr('$')
  if a:range ==# 'tabpage' || ntabpages == 1
    return win_getid(bufwinnr(bufnr))
  endif
  let Distance = function('s:_distance', [tabpagenr()])
  for tabpagenr in sort(range(1, ntabpages), Distance)
    let s:base = tabpagewinnr(tabpagenr)
    let buflist = tabpagebuflist(tabpagenr)
    for winnr in sort(range(1, len(buflist)), Distance)
      if buflist[winnr - 1] == bufnr
        return win_getid(winnr, tabpagenr)
      endif
    endfor
  endfor
  return 0
endfunction

function! s:_distance(base, a, b) abort
  return abs(a:a - a:base) - abs(a:b - a:base)
endfunction
