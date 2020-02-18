function! s:_vital_created(module) abort
endfunction

function! s:_vital_loaded(V) abort
  let s:Promise = vital#vital#import('Async.Promise')
  let s:Process = vital#vital#import('Async.Process')
endfunction

function! s:_vital_depends() abort
  return ['Async.Promise', 'Async.Process']
endfunction

if executable('powershell') || executable('pwsh')
  function! s:_raw_request_pwsh(request) abort
    let header_in = v:null
    let header_out = tempname()
    let content_out = tempname()
    let args = [
          \ 'Invoke-WebRequest',
          \ '-UseBasicParsing',
          \ '-URI', a:request.url,
          \ '-Method', a:request.method,
          \ '-OutFile', shellescape(content_out),
          \ '-PassThru',
          \ '-MaximumRetryCount', a:request.retries,
          \ '-MaximumRedirection', a:request.redirects,
          \]
    if a:request.insecure
      call extend(args, ['-SkipCertificateCheck'])
    endif
    if !empty(a:request.timeout)
      call extend(args, ['-TimeoutSec', a:request.timeout])
    endif
    if !empty(a:request.headers)
      let header_in = tempname()
      call writefile([json_encode(a:request.headers)], header_in)
      call extend(args, [
            \ '-Headers',
            \ printf('(Get-Content -Raw %s | ConvertFrom-Json)', header_in),
            \])
    endif
    let args = [
          \ printf('(%s).RawContent', join(args)),
          \ printf('Out-File %s -Encoding utf8', header_out),
          \]
    let meta = {
          \ 'header_in': header_in,
          \ 'header_out': header_out,
          \ 'content_out': content_out,
          \}
    return s:Process.start([
          \ 'pwsh',
          \ '-ExecutionPolicy', 'Bypass',
          \ '-Command', join(args, ' | '),
          \])
          \.then(funcref('s:_complete_pwsh', [meta]))
  endfunction

  function! s:_complete_pwsh(meta, result) abort
    try
      if a:result.exitval
        return s:Promise.reject(a:result.stderr)
      endif
      return {
            \ 'headers': readfile(a:meta.header_out, 'b'),
            \ 'content': a:meta.content_out,
            \}
    finally
      call delete(a:meta.header_in)
      call delete(a:meta.header_out)
    endtry
  endfunction
endif

if executable('curl')
  function! s:_raw_request_curl(request) abort
    let header_out = tempname()
    let content_out = tempname()
    let args = [
          \ 'curl',
          \ '--dump-header', header_out,
          \ '--output', content_out,
          \ '--no-styled-output',
          \ '--location',
          \ '--silent', '--show-error',
          \ '--retry', a:request.retries,
          \ '--max-redirs', a:request.redirects,
          \ a:request.url,
          \]
    if a:request.method ==? 'head'
      call extend(args, ['--head'])
    else
      call extend(args, ['--request', a:request.method])
    endif
    if a:request.insecure
      call extend(args, ['--insecure'])
    endif
    if !empty(a:request.timeout)
      call extend(args, ['--max-time', a:request.timeout])
    endif
    if !empty(a:request.headers)
      call map(
            \ s:_format_headers(a:request.headers),
            \ { -> extend(args, ['-H', v:val]) }
            \)
    endif
    let meta = {
          \ 'header_out': header_out,
          \ 'content_out': content_out,
          \}
    return s:Process.start(args)
          \.then(funcref('s:_complete_curl', [meta]))
  endfunction

  function! s:_complete_curl(meta, result) abort
    try
      if a:result.exitval
        return s:Promise.reject(a:result.stderr)
      endif
      return {
            \ 'headers': readfile(a:meta.header_out, 'b'),
            \ 'content': a:meta.content_out,
            \}
    finally
      call delete(a:meta.header_out)
    endtry
  endfunction
endif

if executable('wget')
  function! s:_raw_request_wget(request) abort
    let content_out = tempname()
    let args = [
          \ 'wget',
          \ '--no-verbose',
          \ '--tries', a:request.retries,
          \ '-O', content_out,
          \ '--server-response',
          \ printf('--max-redirect=%d', a:request.redirects),
          \ printf('--method=%s', a:request.method),
          \ a:request.url,
          \]
    if a:request.insecure
      call extend(args, ['--no-check-certificate'])
    endif
    if !empty(a:request.timeout)
      call extend(args, ['-T', a:request.timeout])
    endif
    if !empty(a:request.headers)
      call map(
            \ s:_format_headers(a:request.headers),
            \ { -> extend(args, [printf('--header=%s', v:val)]) }
            \)
    endif
    let meta = {
          \ 'content_out': content_out,
          \}
    return s:Process.start(args)
          \.then(funcref('s:_complete_wget', [meta]))
  endfunction

  function! s:_complete_wget(meta, result) abort
    if a:result.exitval
      return s:Promise.reject(a:result.stderr)
    endif
    let headers = filter(a:result.stderr, { -> v:val[:1] ==# '  ' })
    let headers = map(headers, { -> v:val[2:] })
    return {
          \ 'headers': headers,
          \ 'content': a:meta.content_out,
          \}
  endfunction
endif

function! s:_format_headers(headers) abort
  let headers = []
  call map(copy(a:headers), { k, v -> add(headers, printf('%s: %s', k, v)) })
  return headers
endfunction

function! s:_build_request(request) abort
  let request = {
        \ 'url': '',
        \ 'method': 'GET',
        \ 'data': '',
        \ 'headers': {},
        \ 'timeout': 0,
        \ 'retries': 0,
        \ 'redirects': 0,
        \ 'compressed': 0,
        \ 'auth_method': '',
        \ 'username': '',
        \ 'password': '',
        \}
  if !has_key(a:request, 'url')
    throw 'vital: Async.Request: request must have "url" attribute'
  endif
  for key in uniq(sort(keys(request) + keys(a:request)))
    if !has_key(request, key)
      throw printf('vital: Async.Request: unknown attribute "%s" has found in request', key)
    endif
    let request[key] = get(a:request, key, request[key])
  endfor
  return request
endfunction
