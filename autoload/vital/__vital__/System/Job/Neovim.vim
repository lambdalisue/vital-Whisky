" http://vim-jp.org/blog/2016/03/23/take-care-of-patch-1577.html
function! s:is_available() abort
  return has('nvim') && has('nvim-0.2.0')
endfunction

function! s:start(args, options) abort
  let job = extend(copy(s:job), a:options)
  let job_options = {}
  if has_key(job, 'on_stdout')
    let job_options.on_stdout = function('s:_on_stdout', [job])
  endif
  if has_key(job, 'on_stderr')
    let job_options.on_stderr = function('s:_on_stderr', [job])
  endif
  if has_key(job, 'on_exit')
    let job_options.on_exit = function('s:_on_exit', [job])
  else
    let job_options.on_exit = function('s:_on_exit_raw', [job])
  endif
  let job.__job = jobstart(a:args, job_options)
  let job.__exitval = v:null
  let job.args = a:args
  return job
endfunction

function! s:_on_stdout(job, job_id, data, event) abort
  call a:job.on_stdout(a:data)
endfunction

function! s:_on_stderr(job, job_id, data, event) abort
  call a:job.on_stderr(a:data)
endfunction

function! s:_on_exit(job, job_id, exitval, event) abort
  let a:job.__exitval = a:exitval
  call a:job.on_exit(a:exitval)
endfunction

function! s:_on_exit_raw(job, job_id, exitval, event) abort
  let a:job.__exitval = a:exitval
endfunction

" Instance -------------------------------------------------------------------
function! s:_job_id() abort dict
  return self.__job
endfunction

function! s:_job_status() abort dict
  try
    call jobpid(self.__job)
    return 'run'
  catch /^Vim\%((\a\+)\)\=:E900/
    return 'dead'
  endtry
endfunction

if exists('*chansend') " Neovim 0.2.3
  function! s:_job_send(data) abort dict
    return chansend(self.__job, a:data)
  endfunction
else
  function! s:_job_send(data) abort dict
    return jobsend(self.__job, a:data)
  endfunction
endif

if exists('*chanclose') " Neovim 0.2.3
  function! s:_job_close() abort dict
    call chanclose(self.__job, 'stdin')
  endfunction
else
  function! s:_job_close() abort dict
    call jobclose(self.__job, 'stdin')
  endfunction
endif

function! s:_job_stop() abort dict
  try
    call jobstop(self.__job)
  catch /^Vim\%((\a\+)\)\=:E900/
    " NOTE:
    " Vim does not raise exception even the job has already closed so fail
    " silently for 'E900: Invalid job id' exception
  endtry
endfunction

function! s:_job_wait(...) abort dict
  let timeout = a:0 ? a:1 : v:null
  let exitval = timeout is# v:null
        \ ? jobwait([self.__job])[0]
        \ : jobwait([self.__job], timeout)[0]
  if exitval != -3
    sleep 1m
    return exitval
  endif
  " The job has already been terminated.
  " Wait until 'on_exit' callback is called
  while self.__exitval is# v:null
    sleep 1m
  endwhile
  return self.__exitval
endfunction

" To make debug easier, use funcref instead.
let s:job = {
      \ 'id': function('s:_job_id'),
      \ 'status': function('s:_job_status'),
      \ 'send': function('s:_job_send'),
      \ 'close': function('s:_job_close'),
      \ 'stop': function('s:_job_stop'),
      \ 'wait': function('s:_job_wait'),
      \}
