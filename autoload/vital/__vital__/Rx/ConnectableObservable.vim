function! s:_vital_loaded(V) abort
  let s:Observable = a:V.import('Rx.Observable')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Rx.Observable',
        \]
endfunction

function! s:new(source, subject) abort
  let origin = s:Observable.new({ -> 0 })
  let observable = extend(origin, {
        \ '__source': a:source,
        \ '__subject': a:subject,
        \ '__connection': v:null,
        \ 'is_connected': funcref('s:_connectable_observable_is_connected'),
        \ 'connect': funcref('s:_connectable_observable_connect'),
        \ 'subscribe': funcref('s:_connectable_observable_subscribe'),
        \ 'ref_count': funcref('s:_connectable_observable_ref_count'),
        \})
  return observable
endfunction

function! s:_connectable_observable_is_connected() abort dict
  return self.__connection isnot# v:null && !self.__connection.closed()
endfunction

function! s:_connectable_observable_connect() abort dict
  if self.is_connected()
    throw 'vital: Rx.ConnectableObservable: connection has already established'
  endif
  let self.__connection = self.__source.subscribe(self.__subject)
  return self.__connection
endfunction

function! s:_connectable_observable_subscribe(...) abort dict
  return call(self.__subject.subscribe, a:000, self.__subject)
endfunction

function! s:_connectable_observable_ref_count() abort dict
  let self.subscribe = funcref('s:_connectable_observable_ref_count_subscribe')
  let self.__ref_count = 0
  return self
endfunction

function! s:_connectable_observable_ref_count_subscribe(...) abort dict
  call call(self.__subject.subscribe, a:000, self.__subject)
  let self.__ref_count += 1
  if !self.is_connected()
    call self.connect()
  endif
  return funcref('s:_ref_count_cleanup', [self])
endfunction

function! s:_ref_count_cleanup(observable) abort
  let a:observable.__ref_count = max([0, a:observable.__ref_count - 1])
  if a:observable.__ref_count is# 0 && a:observable.is_connected()
    call a:observable.__connection.unsubscribe()
  endif
endfunction
