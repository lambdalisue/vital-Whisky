let s:plugin_name = matchstr(
      \ expand('<sfile>:p'),
      \ '[\\/]autoload[\\/]vital[\\/]\%(__\zs.\{-}\ze__\|_\zs.\{-}\ze\)[\\/]',
      \)

function! s:_vital_created(module) abort
  let a:module.plugin_name = s:plugin_name
endfunction

function! s:new(exception, ...) abort dict
  return {
        \ 'exception': a:exception,
        \ 'throwpoint': a:0 ? a:1 : '',
        \ 'echo': funcref('s:_error_echo', [self]),
        \ 'echomsg': funcref('s:_error_echomsg', [self]),
        \ 'throw': funcref('s:_error_throw', [self]),
        \}
endfunction

function! s:from(any) abort dict
  if type(a:any) is# v:t_dict && has_key(a:any, 'exception')
    return self.new(
          \ a:any.exception,
          \ get(a:any, 'throwpoint', ''),
          \)
  elseif type(a:any) is# v:t_string
    return self.catch(a:any)
  endif
  return self.new(string(a:any))
endfunction

function! s:catch(...) abort dict
  let exception = a:0 ? a:1 : v:exception
  if empty(exception)
    throw 'vital: Error: Error.catch() must be called in a :catch block or an error message is required.'
  endif
  try
    if exception =~# '^{.*}$'
      let error = json_decode(exception)
      return self.new(error.exception, error.throwpoint)
    endif
  catch
  endtry
  return self.new(exception, v:throwpoint)
endfunction


" Error instance -----------------------------------------------------------
function! s:_error_echo(module, ...) abort dict
  let hl = a:0 ? a:1 : 'ErrorMsg'
  let messages = split(self.exception, '\n') + split(self.throwpoint, '\n')
  if empty(messages)
    return
  endif
  execute 'echohl' hl
  echo printf('[%s] %s', a:module.plugin_name, remove(messages, 0))
  for message in messages
    echo message
  endfor
  echohl None
  execute "normal! \<Esc>"
endfunction

function! s:_error_echomsg(module, ...) abort dict
  let hl = a:0 ? a:1 : 'ErrorMsg'
  let messages = split(self.exception, '\n') + split(self.throwpoint, '\n')
  if empty(messages)
    return
  endif
  execute 'echohl' hl
  echomsg printf('[%s] %s', a:module.plugin_name, remove(messages, 0))
  for message in messages
    echomsg message
  endfor
  echohl None
  execute "normal! \<Esc>"
endfunction

function! s:_error_throw(module) abort dict
  throw json_encode({
        \ 'exception': self.exception,
        \ 'throwpoint': self.throwpoint,
        \})
endfunction
