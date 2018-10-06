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
        \ '__ref_count': 0,
        \ '__source': a:source,
        \ '__subject': a:subject,
        \ '__connection': v:null,
        \ 'is_connected': funcref('s:_connectable_observable_is_connected'),
        \ 'connect': funcref('s:_connectable_observable_connect'),
        \ 'subscribe': funcref('s:_connectable_observable_subscribe'),
        \})
  return observable
endfunction

function! s:_connectable_observable_is_connected() abort dict
  return self.__connection isnot# v:null && !self.__connection.closed()
endfunction

function! s:_connectable_observable_connect() abort dict
  if self.is_connected()
    return self.__connection
  endif
  let self.__connection = self.__source.subscribe(self.__subject)
  return self.__connection
endfunction

function! s:_connectable_observable_subscribe(...) abort dict
  return call(self.__subject.subscribe, a:000, self.__subject)
endfunction
