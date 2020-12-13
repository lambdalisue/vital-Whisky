let s:is_windows = has('win32')

function! s:get_is_windows() abort
  return s:is_windows
endfunction

function! s:set_is_windows(is_windows) abort
  let s:is_windows = a:is_windows
endfunction

function! s:to_slash(path) abort
  return s:is_windows
        \ ? s:_to_slash_windows(a:path)
        \ : s:_to_slash_unix(a:path)
endfunction

function! s:from_slash(path) abort
  return s:is_windows
        \ ? s:_from_slash_windows(a:path)
        \ : s:_to_slash_unix(a:path)
endfunction

function! s:is_root(path) abort
  return s:is_windows
        \ ? a:path ==# ''
        \ : a:path ==# '/'
endfunction

function! s:is_drive_root(path) abort
  return s:is_windows
        \ ? a:path =~# '^\w:\\$'
        \ : a:path ==# '/'
endfunction

function! s:is_absolute(path) abort
  return s:is_windows
        \ ? s:_is_absolute_windows(a:path)
        \ : s:_is_absolute_unix(a:path)
endfunction

function! s:join(paths) abort
  let paths = map(
        \ copy(a:paths),
        \ 's:to_slash(v:val)',
        \)
  return s:from_slash(join(paths, '/'))
endfunction

function! s:_to_slash_windows(path) abort
  let prefix = s:_is_absolute_windows(a:path) ? '/' : ''
  let terms = filter(split(a:path, '\\'), '!empty(v:val)')
  return prefix . join(terms, '/')
endfunction

function! s:_to_slash_unix(path) abort
  if empty(a:path)
    return '/'
  endif
  let prefix = s:_is_absolute_unix(a:path) ? '/' : ''
  let terms = filter(split(a:path, '/'), '!empty(v:val)')
  return prefix . join(terms, '/')
endfunction

function! s:_from_slash_windows(path) abort
  let terms = filter(split(a:path, '/'), '!empty(v:val)')
  let path = join(terms, '\')
  return path[:2] =~# '^\w:$' ? path . '\' : path
endfunction

function! s:_is_absolute_windows(path) abort
  return a:path ==# '' || a:path[:2] =~# '^\w:\\$'
endfunction

function! s:_is_absolute_unix(path) abort
  return a:path ==# '' || a:path[:0] ==# '/'
endfunction
