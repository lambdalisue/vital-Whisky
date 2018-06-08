let s:PENDING = 0
let s:FULFILLED = 1
let s:REJECTED = 2
let s:STATES = ['pending', 'fulfilled', 'rejected']

function! s:_vital_loaded(V) abort
  let s:Promise = a:V.import('Async.Promise')
endfunction

function! s:_vital_depends() abort
  return ['Async.Promise']
endfunction

function! s:state(promise) abort
  return s:STATES[a:promise._state]
endfunction

function! s:result(promise) abort
  return a:promise._result
endfunction

function! s:wait(promise, ...) abort
  let t = a:0 ? (a:1 / 1000) : v:null
  let s = reltime()
  while a:promise._state is# s:PENDING
        \ && (t is# v:null || reltimefloat(reltime(s)) < t)
    sleep 10m
  endwhile
  return s:state(a:promise)
endfunction

function! s:sleep(delay, ...) abort
  let value = a:0 ? a:1 : v:null
  return s:Promise.new({ r -> timer_start(a:delay, { -> r(value) }) })
endfunction
