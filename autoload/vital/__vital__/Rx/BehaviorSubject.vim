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
        \ 'next': funcref('s:_behavior_subject_next', [super]),
        \ 'subscribe': funcref('s:_behavior_subject_subscribe', [super]),
        \})
  if a:0
    call subject.next(a:1)
  endif
  return subject
endfunction

function! s:_behavior_subject_next(super, value) abort dict
  let self.__latest = a:value
  let self.__has_value = v:true
  call call(a:super.next, [a:value], self)
endfunction

function! s:_behavior_subject_subscribe(super, ...) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.BehaviorSubject: Subject is already closed.'
  endif
  let observer = call(s:Observer.new, a:000, s:Observer)
  let subscription = call(a:super.subscribe, [observer], self)
  if self.__has_error isnot# v:true && !self.__stopped && self.__has_value
    call observer.next(self.__latest)
  endif
  return subscription
endfunction
