let s:separator = fnamemodify('.', ':p')[-1:]
let s:scope = themis#helper('scope')
let s:assert = themis#helper('assert')
let s:module_healths = {}

function! healthcheck#vital#import(module_name) abort
  if !has_key(s:module_healths, a:module_name)
    call s:check(a:module_name)
  endif
  if empty(s:module_healths[a:module_name])
    return vital#vital#import(a:module_name)
  else
    call s:assert.skip(s:module_healths[a:module_name])
  endif
endfunction


function! s:check(module_name) abort
  let path = ['autoload', 'vital', '__vital__'] + split(a:module_name, '\.')
  let funcs = s:scope.funcs(join(path, s:separator) . '.vim')
  if !has_key(funcs, '_vital_healthcheck')
    let s:module_healths[a:module_name] = 0
  else
    let s:module_healths[a:module_name] = funcs._vital_healthcheck()
  endif
endfunction
