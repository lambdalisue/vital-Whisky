function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:_vital_depends() abort
  return ['Async.Promise']
endfunction

function! s:new() abort
  let ns = {'resolve': v:null, 'reject': v:null}
  let promise = s:Promise.new(
        \ { rv, rt -> extend(ns, {'resolve': rv, 'reject': rt}) }
        \)
  while ns.resolve is# v:null
    sleep 1m
  endwhile
  let promise.resolve = ns.resolve
  let promise.reject = ns.reject
  return promise
endfunction
