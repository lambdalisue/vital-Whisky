let s:EMPTY_SUBSCRIPTION = {
      \ 'closed': { -> 1 },
      \ 'unsubscribe': { -> 0 },
      \}

function! s:_vital_loaded(V) abort
  let s:Observable = a:V.import('Rx.Observable')
  let s:Observer = a:V.import('Rx.Observer')
  let s:SubjectSubscription = a:V.import('Rx.SubjectSubscription')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Rx.Observable',
        \ 'Rx.Observer',
        \ 'Rx.SubjectSubscription',
        \]
endfunction

function! s:new() abort
  let subject = extend(s:Observable.empty(), {
        \ '__closed': v:false,
        \ '__stopped': v:false,
        \ '__has_error': v:false,
        \ '__thrown_error': v:null,
        \ 'observers': [],
        \ 'closed': funcref('s:_subject_closed'),
        \ 'next': funcref('s:_subject_next'),
        \ 'error': funcref('s:_subject_error'),
        \ 'complete': funcref('s:_subject_complete'),
        \ 'subscribe': funcref('s:_subject_subscribe'),
        \ 'unsubscribe': funcref('s:_subject_unsubscribe'),
        \})
  unlet subject.__subscriber
  return subject
endfunction

function! s:create(observer, observable) abort
  let origin = s:Observable.empty()
  let anonymous = extend(origin, {
        \ '__closed': v:false,
        \ '__stopped': v:false,
        \ '__has_error': v:false,
        \ '__thrown_error': v:null,
        \ '__destination': a:observer,
        \ '__source': a:observable,
        \ 'observers': [],
        \ 'next': funcref('s:_anonymous_next'),
        \ 'error': funcref('s:_anonymous_error'),
        \ 'complete': funcref('s:_anonymous_complete'),
        \ 'subscribe': funcref('s:_anonymous_subscribe'),
        \ 'unsubscribe': funcref('s:_subject_unsubscribe'),
        \})
  unlet anonymous.__subscriber
  return anonymous
endfunction


" Subject ------------------------------------------------------------------
function! s:_subject_closed() abort dict
  return self.__closed
endfunction

function! s:_subject_next(value) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.Subject: Subject is already closed.'
  elseif self.__stopped is# v:false
    call map(copy(self.observers), { -> v:val.next(a:value) })
  endif
endfunction

function! s:_subject_error(error) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.Subject: Subject is already closed.'
  endif
  let observers = copy(self.observers)
  let self.observers = []
  let self.__stopped = v:true
  let self.__has_error = v:true
  let self.__thrown_error = a:error
  call map(observers, { -> v:val.error(a:error) })
endfunction

function! s:_subject_complete() abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.Subject: Subject is already closed.'
  endif
  let observers = copy(self.observers)
  let self.observers = []
  let self.__stopped = v:true
  call map(observers, { -> v:val.complete() })
endfunction

function! s:_subject_subscribe(...) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.Subject: Subject is already closed.'
  endif
  let observer = call(s:Observer.new, a:000, s:Observer)
  if self.__has_error is# v:true
    call observer.error(self.__thrown_error)
    return copy(s:EMPTY_SUBSCRIPTION)
  elseif self.__stopped
    call observer.complete()
    return copy(s:EMPTY_SUBSCRIPTION)
  endif
  call add(self.observers, observer)
  return s:SubjectSubscription.new(self, observer)
endfunction

function! s:_subject_unsubscribe() abort dict
  let self.__stopped = v:true
  let self.__closed = v:true
  let self.observers = v:null
endfunction


" AnonymousSubject ---------------------------------------------------------
function! s:_anonymous_next(value) abort dict
  if self.__destination isnot# v:null && has_key(self.__destination, 'next')
    call self.__destination.next(a:value)
  endif
endfunction

function! s:_anonymous_error(error) abort dict
  if self.__destination isnot# v:null && has_key(self.__destination, 'error')
    call self.__destination.error(a:error)
  endif
endfunction

function! s:_anonymous_complete() abort dict
  if self.__destination isnot# v:null && has_key(self.__destination, 'complete')
    call self.__destination.complete()
  endif
endfunction

function! s:_anonymous_subscribe(...) abort dict
  if self.__source isnot# v:null
    return call(self.__source.subscribe, a:000, self.__source)
  else
    return copy(s:EMPTY_SUBSCRIPTION)
  endif
endfunction
