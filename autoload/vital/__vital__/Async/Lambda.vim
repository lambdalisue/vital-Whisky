function! s:_vital_created(module) abort
  let a:module.chunk_size = 1000
endfunction

function! s:_vital_loaded(V) abort
  let s:Later = a:V.import('Async.Later')
  let s:Lambda = a:V.import('Lambda')
  let s:Promise = a:V.import('Async.Promise')
  let s:Chunker = a:V.import('Data.List.Chunker')
endfunction

function! s:_vital_depends() abort
  return ['Async.Later', 'Async.Promise', 'Data.List.Chunker', 'Lambda']
endfunction

function! s:map(list, fn) abort dict
  let t = self.chunk_size
  let c = s:Chunker.new(t, a:list)
  return s:Promise.new({ resolve -> s:_map(c, a:fn, [], 0, resolve)})
endfunction

function! s:filter(list, fn) abort dict
  let t = self.chunk_size
  let c = s:Chunker.new(t, a:list)
  return s:Promise.new({ resolve -> s:_filter(c, a:fn, [], 0, resolve)})
endfunction

function! s:reduce(list, fn, init) abort dict
  let t = self.chunk_size
  let c = s:Chunker.new(t, a:list)
  return s:Promise.new({ resolve -> s:_reduce(c, a:fn, a:init, 0, resolve)})
endfunction

function! s:map_f(fn) abort dict
  return { list -> self.map(list, a:fn) }
endfunction

function! s:filter_f(fn) abort dict
  return { list -> self.filter(list, a:fn) }
endfunction

function! s:reduce_f(fn, init) abort dict
  return { list -> self.reduce(list, a:fn, a:init) }
endfunction

function! s:_map(chunker, fn, result, offset, resolve) abort
  let chunk = a:chunker.next()
  let chunk_size = len(chunk)
  if chunk_size is# 0
    call a:resolve(a:result)
    return
  endif
  call extend(a:result, map(chunk, { k, v -> a:fn(v, a:offset + k) }))
  call s:Later.call({ ->
        \ s:_map(a:chunker, a:fn, a:result, a:offset + chunk_size, a:resolve)
        \})
endfunction

function! s:_filter(chunker, fn, result, offset, resolve) abort
  let chunk = a:chunker.next()
  let chunk_size = len(chunk)
  if chunk_size is# 0
    call a:resolve(a:result)
    return
  endif
  call extend(a:result, filter(chunk, { k, v -> a:fn(v, a:offset + k) }))
  call s:Later.call({ ->
        \ s:_filter(a:chunker, a:fn, a:result, a:offset + chunk_size, a:resolve)
        \})
endfunction

function! s:_reduce(chunker, fn, result, offset, resolve) abort
  let chunk = a:chunker.next()
  let chunk_size = len(chunk)
  if chunk_size is# 0
    call a:resolve(a:result)
    return
  endif
  let result = s:Lambda.reduce(
        \ chunk,
        \ { a, v, k -> a:fn(a, v, a:offset + k) },
        \ a:result,
        \)
  call s:Later.call({ ->
        \ s:_reduce(a:chunker, a:fn, result, a:offset + chunk_size, a:resolve)
        \})
endfunction
