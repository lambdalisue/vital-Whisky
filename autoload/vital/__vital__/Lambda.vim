function! s:void(...) abort
endfunction

function! s:pass(value, ...) abort
  return a:value
endfunction

function! s:let(object, key, value) abort
  let a:object[a:key] = a:value
endfunction

function! s:unlet(object, key, ...) abort
  let force = a:0 ? a:1 : 0
  if (a:0 ? a:1 : 0) is# 1
    silent! unlet! a:object[a:key]
  else
    unlet a:object[a:key]
  endif
endfunction

function! s:throw(message) abort
  throw a:message
endfunction

function! s:echo(message) abort
  echo a:message
endfunction

function! s:echomsg(message) abort
  echomsg a:message
endfunction

function! s:if(condition, true, ...) abort
  if a:condition
    return a:true()
  elseif a:0
    return a:1()
  endif
endfunction

function! s:map(list, fn) abort
  return map(copy(a:list), { k, v -> a:fn(v, k) })
endfunction

function! s:filter(list, fn) abort
  return filter(copy(a:list), { k, v -> a:fn(v, k) })
endfunction

function! s:reduce(list, fn, ...) abort
  let accumulator = a:0 ? a:1 : a:list[0]
  let offset = a:0 ? 0 : 1
  for index in range(len(a:list) - offset)
    let accumulator = a:fn(
          \ accumulator,
          \ a:list[offset + index],
          \ offset + index,
          \)
  endfor
  return accumulator
endfunction

function! s:map_f(fn) abort
  return { list -> s:map(list, a:fn) }
endfunction

function! s:filter_f(fn) abort
  return { list -> s:filter(list, a:fn) }
endfunction

function! s:reduce_f(fn, ...) abort
  let args = a:000
  return { list -> call('s:reduce', [list, a:fn] + args) }
endfunction
