let s:EMPTY_SUBSCRIPTION = {
      \ 'closed': { -> 1 },
      \ 'unsubscribe': { -> 0 },
      \}

function! s:_vital_loaded(V) abort
  let s:Subject = a:V.import('Rx.Subject')
  let s:Observer = a:V.import('Rx.Observer')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Rx.Subject',
        \ 'Rx.Observer',
        \]
endfunction

function! s:new(...) abort
  let super = s:Subject.new()
  let subject = extend(copy(super), {
        \ '__latest': v:null,
        \ '__has_value': v:false,
        \ '__has_completed': v:false,
        \ 'next': funcref('s:_async_subject_next'),
        \ 'error': funcref('s:_async_subject_error', [super]),
        \ 'complete': funcref('s:_async_subject_complete', [super]),
        \ 'subscribe': funcref('s:_async_subject_subscribe', [super]),
        \})
  return subject
endfunction

function! s:_async_subject_subscribe(super, ...) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.AsyncSubject: Subject is already closed.'
  endif
  let observer = call(s:Observer.new, a:000, s:Observer)
  if self.__has_error
    call observer.error(self.__thrown_error)
    return copy(s:EMPTY_SUBSCRIPTION)
  elseif self.__has_completed && self.__has_value
    call observer.next(self.__latest)
    call observer.complete()
    return copy(s:EMPTY_SUBSCRIPTION)
  endif
  return call(a:super.subscribe, [observer], self)
endfunction

function! s:_async_subject_next(value) abort dict
  if !self.__has_completed
    let self.__latest = a:value
    let self.__has_value = v:true
  endif
endfunction

function! s:_async_subject_error(super, error) abort dict
  if !self.__has_completed
    call call(a:super.error, [a:error], self)
  endif
endfunction

function! s:_async_subject_complete(super) abort dict
  let self.__has_completed = v:true
  if self.__has_value
    call call(a:super.next, [self.__latest], self)
  endif
  call call(a:super.complete, [], self)
endfunction
