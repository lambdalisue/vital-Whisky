let s:EMPTY_SUBSCRIPTION = {
      \ 'closed': { -> 1 },
      \ 'unsubscribe': { -> 0 },
      \}

function! s:_vital_loaded(V) abort
  let s:Subject = a:V.import('Rx.Subject')
  let s:Observer = a:V.import('Rx.Observer')
  let s:SubjectSubscription = a:V.import('Rx.SubjectSubscription')
endfunction

function! s:_vital_depends() abort
  return [
        \ 'Rx.Subject',
        \ 'Rx.Observer',
        \ 'Rx.SubjectSubscription',
        \]
endfunction

function! s:new(...) abort
  let super = s:Subject.new()
  let subject = extend(copy(super), {
        \ '__events': [],
        \ '__buffer_size': a:0 > 0 ? a:1 : v:null,
        \ '__window_size': a:0 > 1 ? a:2 : v:null,
        \ 'next': a:0 > 1 && a:2 isnot# v:null
        \   ? funcref('s:_replay_subject_next_window', [super])
        \   : funcref('s:_replay_subject_next_buffer', [super]),
        \ 'subscribe': funcref('s:_replay_subject_subscribe'),
        \})
  return subject
endfunction

function! s:_replay_subject_next_buffer(super, value) abort dict
  call add(self.__events, a:value)
  if self.__buffer_size isnot# v:null && len(self.__events) > self.__buffer_size
    call remove(self.__events, 0)
  endif
  call call(a:super.next, [a:value], self)
endfunction

function! s:_replay_subject_next_window(super, value) abort dict
  call add(self.__events, [a:value, reltime()])
  call s:_trim(self.__events, self.__buffer_size, self.__window_size)
  call call(a:super.next, [a:value], self)
endfunction

function! s:_replay_subject_subscribe(...) abort dict
  if self.__closed is# v:true
    throw 'vital: Rx.ReplaySubject: Subject is already closed.'
  endif
  let observer = call(s:Observer.new, a:000, s:Observer)
  if self.__has_error is# v:true || self.__stopped
    let subscription = copy(s:EMPTY_SUBSCRIPTION)
  else
    call add(self.observers, observer)
    let subscription = s:SubjectSubscription.new(self, observer)
  endif

  if self.__window_size is# v:null
    call map(copy(self.__events), { -> observer.next(v:val) })
  else
    call s:_trim(self.__events, self.__buffer_size, self.__window_size)
    call map(copy(self.__events), { -> observer.next(v:val[0]) })
  endif

  if self.__has_error is# v:true
    call observer.error(self.__thrown_error)
  elseif self.__stopped
    call observer.complete()
  endif

  return subscription
endfunction

function! s:_trim(events, buffer_size, window_size) abort
  let t = len(a:events)
  let s = 0
  while s < t
    if reltimefloat(reltime(a:events[s][1])) * 1000 < a:window_size
      break
    endif
    let s += 1
  endwhile
  if a:buffer_size isnot# v:null && t > a:buffer_size
    let s = max([s, t - a:buffer_size])
  endif
  if s > 0
    call remove(a:events, 0, s - 1)
  endif
  return a:events
endfunction
