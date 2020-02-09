let s:STATE_OPEN = 0
let s:STATE_CLOSED = 1
let s:STATE_REQUESTED = 2

let s:CANCELLED_ERROR = 'vital: Async.CancellationToken: CancelledError'

function! s:_vital_created(module) abort
  " State
  call extend(a:module, {
        \ 'STATE_OPEN': s:STATE_OPEN,
        \ 'STATE_CLOSED': s:STATE_CLOSED,
        \ 'STATE_REQUESTED': s:STATE_REQUESTED,
        \})
  " A token which will never be canceled
  let a:module.none = s:new({
        \ '_state': s:STATE_CLOSED,
        \ '_registrations': [],
        \})
  " A token that is already canceled
  let a:module.canceled = s:new({
        \ '_state': s:STATE_REQUESTED,
        \ '_registrations': [],
        \})
  let a:module.CancelledError = s:CANCELLED_ERROR
  lockvar 3 a:module
endfunction

function! s:new(source) abort
  let token = {
        \ '_source': a:source,
        \ 'cancellation_requested': funcref('s:_cancellation_requested'),
        \ 'can_be_canceled': funcref('s:_can_be_canceled'),
        \ 'throw_if_cancellation_requested': funcref('s:_throw_if_cancellation_requested'),
        \ 'register': funcref('s:_register'),
        \}
  lockvar 1 token
  return token
endfunction

function! s:_cancellation_requested() abort dict
  return self._source._state is# s:STATE_REQUESTED
endfunction

function! s:_can_be_canceled() abort dict
  return self._source._state isnot# s:STATE_CLOSED
endfunction

function! s:_throw_if_cancellation_requested() abort dict
  if self.cancellation_requested()
    throw s:CANCELLED_ERROR
  endif
endfunction

function! s:_register(callback) abort dict
  if self._source._state is# s:STATE_REQUESTED
    call a:callback()
    return { 'unregister': { -> 0 } }
  elseif self._source._state is# s:STATE_CLOSED
    return { 'unregister': { -> 0 } }
  endif

  let registration = {
        \ '_source': self._source,
        \ '_target': a:callback,
        \ 'unregister': funcref('s:_unregister'),
        \}
  call add(self._source._registrations, registration)
  return registration
endfunction

function! s:_unregister() abort dict
  if self._source is# v:null
    return
  endif
  let index = index(self._source._registrations, self)
  if index isnot# -1
    call remove(self._source._registrations, index)
  endif
  let self._source = v:null
  let self._target = v:null
endfunction
