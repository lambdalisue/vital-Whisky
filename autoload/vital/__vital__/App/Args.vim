function! s:_index(args, pattern) abort
  for index in range(len(a:args))
    if a:args[index] =~# a:pattern
      return index
    endif
  endfor
  return -1
endfunction

function! s:get(args, name, default) abort
  let pattern = printf('^-%s\%(=.*\)\?$', a:name)
  let index = s:_index(a:args, pattern)
  if index is# -1
    return a:default
  else
    let value = a:args[index]
    return value =~# '^-[^=]\+='
          \ ? matchstr(value, '=\zs.*$')
          \ : v:true
  endif
endfunction

function! s:pop(args, name, default) abort
  let pattern = printf('^-%s\%(=.*\)\?$', a:name)
  let index = s:_index(a:args, pattern)
  if index is# -1
    return a:default
  else
    let value = remove(a:args, index)
    return value =~# '^-[^=]\+='
          \ ? matchstr(value, '=\zs.*$')
          \ : v:true
  endif
endfunction

function! s:set(args, name, value) abort
  let pattern = printf('^-%s\%(=.*\)\?$', a:name)
  let index = s:_index(a:args, pattern)
  let value = a:value is# v:true
        \ ? printf('-%s', a:name)
        \ : printf('-%s=%s', a:name, a:value)
  if index is# -1
    call add(a:args, value)
  elseif a:value is# v:false
    call remove(a:args, index)
  else
    let a:args[index] = value
  endif
endfunction

function! s:throw_if_dirty(args, ...) abort
  let prefix = a:0 ? a:1 : ''
  for arg in a:args
    if arg =~# '^-'
      throw printf('%sunknown option %s has specified', prefix, arg)
    endif
  endfor
endfunction
