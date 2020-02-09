function! s:_vital_depends() abort
  return ['Async.CancellationToken']
endfunction

function! s:_vital_loaded(V) abort
  let s:CancellationToken = a:V.import('Async.CancellationToken')
endfunction

function! s:new(...) abort
  let source = {
        \ '_state': s:CancellationToken.STATE_OPEN,
        \ '_registrations': [],
        \ '_linking_registrations': [],
        \ 'cancel': funcref('s:_cancel'),
        \ 'close': funcref('s:_close'),
        \}
  " Link to given tokens
  for token in (a:0 ? a:1 : [])
    if token.cancellation_requested()
      let source._state = token._source._state
      call s:_unlink(source)
      break
    elseif token.can_be_canceled()
      call add(
            \ source._linking_registrations,
            \ token.register({ -> source.cancel() }),
            \)
    endif
  endfor
  " Assign token
  let source.token = s:CancellationToken.new(source)
  lockvar 1 source
  return source
endfunction

function! s:_cancel() abort dict
  if self._state isnot# s:CancellationToken.STATE_OPEN
    return
  endif

  let self._state = s:CancellationToken.STATE_REQUESTED
  call s:_unlink(self)

  let registrations = filter(
        \ self._registrations,
        \ { _, v -> v._target isnot# v:null }
        \)
  let self._registrations = []
  for registration in registrations
    try
      call registration._target()
    catch
      let exception = v:exception
      call timer_start(0, { -> s:_throw(exception) })
    endtry
  endfor
endfunction

function! s:_close() abort dict
  if self._state isnot# s:CancellationToken.STATE_OPEN
    return
  endif

  let self._state = s:CancellationToken.STATE_CLOSED
  call s:_unlink(self)
  let self._registrations = []
endfunction

function! s:_unlink(source) abort
  let linking_registrations = a:source._linking_registrations
  let a:source._linking_registrations = []
  call map(linking_registrations, { _, v -> v.unregister() })
endfunction

function! s:_throw(exception) abort
  throw a:exception
endfunction
