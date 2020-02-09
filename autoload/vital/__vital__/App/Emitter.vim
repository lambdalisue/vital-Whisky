let s:listeners = {}
let s:middlewares = []

function! s:subscribe(name, listener, ...) abort
  let dict = get(a:000, 0, v:null)
  let s:listeners[a:name] = get(s:listeners, a:name, [])
  call add(s:listeners[a:name], [a:listener, dict])
endfunction

function! s:unsubscribe(...) abort
  if a:0 == 0
    let s:listeners = {}
  elseif a:0 == 1
    let s:listeners[a:1] = []
  else
    let dict = a:0 == 3 ? a:3 : v:null
    let s:listeners[a:1] = get(s:listeners, a:1, [])
    let index = index(s:listeners[a:1], [a:2, dict])
    if index != -1
      call remove(s:listeners[a:1], index)
    endif
  endif
endfunction

function! s:add_middleware(middleware) abort
  call add(s:middlewares, a:middleware)
endfunction

function! s:remove_middleware(...) abort
  if a:0 == 0
    let s:middlewares = []
  else
    let index = index(s:middlewares, a:1)
    if index != -1
      call remove(s:middlewares, index)
    endif
  endif
endfunction

function! s:emit(name, ...) abort
  let attrs = copy(a:000)
  let listeners = copy(get(s:listeners, a:name, []))
  let middlewares = map(s:middlewares, 'extend(copy(s:middleware), v:val)')
  for middleware in middlewares
    call call(middleware.on_emit_pre, [a:name, listeners, attrs], middleware)
  endfor
  for [l:Listener, dict] in listeners
    if empty(dict)
      call call(Listener, attrs)
    else
      call call(Listener, attrs, dict)
    endif
  endfor
  for middleware in middlewares
    call call(middleware.on_emit_post, [a:name, listeners, attrs], middleware)
  endfor
endfunction


" Middleware skeleton --------------------------------------------------------
let s:middleware = {}

function! s:middleware.on_emit_pre(name, listeners, attrs) abort
  " Users can override this method
endfunction

function! s:middleware.on_emit_post(name, listeners, attrs) abort
  " Users can override this method
endfunction
