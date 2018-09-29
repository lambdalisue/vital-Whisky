function! s:_vital_depends() abort
  return [
        \ 'System.File',
        \ 'System.Filepath'
        \]
endfunction

function! s:_vital_loaded(V) abort
  let s:File = a:V.import('System.File')
  let s:Path = a:V.import('System.Filepath')
endfunction

function! s:new(...) abort
  let Factory = a:0 ? a:1 : function('tempname')
  let sandbox = {
        \ '__home': fnamemodify(resolve(Factory()), ':p'),
        \ '__origin': fnamemodify(resolve(getcwd()), ':p'),
        \ 'origin': funcref('s:_sandbox_origin'),
        \ 'path': funcref('s:_sandbox_path'),
        \ 'visit': funcref('s:_sandbox_visit'),
        \ 'return': funcref('s:_sandbox_return'),
        \ 'dispose': funcref('s:_sandbox_dispose'),
        \}
  call s:File.mkdir_nothrow(sandbox.__home, 'r', 0700)
  call sandbox.return()
  lockvar 2 sandbox
  return sandbox
endfunction

function! s:_sandbox_origin() abort dict
  return self.__origin
endfunction

function! s:_sandbox_path(...) abort dict
  let path = a:0 ? a:1 : ''
  if s:Path.is_absolute(path)
    throw printf('vital: System.Sandbox: path requires to be a relative path: %s', path)
  endif
  return resolve(s:Path.join(self.__home, s:Path.realpath(path)))
endfunction

function! s:_sandbox_visit(path) abort dict
  let path = self.path(a:path)
  if !isdirectory(path)
    call s:File.mkdir_nothrow(path, 'r', 0700)
  endif
  execute 'cd' fnameescape(path)
endfunction

function! s:_sandbox_return() abort dict
  execute 'cd' fnameescape(self.__home)
endfunction

function! s:_sandbox_dispose() abort dict
  execute 'cd' fnameescape(self.__origin)
  call s:File.rmdir(self.__home, 'r')
endfunction
