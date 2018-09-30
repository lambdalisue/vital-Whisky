function! s:new(subject, observer) abort
  return {
        \ '__subject': a:subject,
        \ '__observer': a:observer,
        \ '__closed': v:false,
        \ 'closed': funcref('s:_subject_subscription_closed'),
        \ 'unsubscribe': funcref('s:_subject_subscription_unsubscribe'),
        \}
endfunction

function! s:_subject_subscription_closed() abort dict
  return self.__closed is# v:true
endfunction

function! s:_subject_subscription_unsubscribe() abort dict
  if self.closed()
    return
  endif
  let subject = self.__subject
  let observers = subject.observers
  let self.__closed = v:true
  let self.__subject = v:null
  if empty(observers) || subject.__stopped || subject.__closed
    return
  endif
  let index = index(observers, self.__observer)
  if index isnot# -1
    call remove(observers, index)
  endif
endfunction
