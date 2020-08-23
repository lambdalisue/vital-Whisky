let s:prefix = matchstr(
      \ fnamemodify(expand('<sfile>'), ':p:h:h:t'),
      \ '^\%(__\zs.*\ze__\|_\zs.*\)$',
      \)

function! s:get_prefix() abort
  return s:prefix
endfunction

function! s:set_prefix(prefix) abort
  let s:prefix = a:prefix
endfunction

function! s:init() abort
  execute printf(
        \ 'nnoremap <buffer><silent> <Plug>(%s-action-choice) :<C-u>call <SID>_map_choice()<CR>',
        \ s:prefix,
        \)
  execute printf(
        \ 'nnoremap <buffer><silent> <Plug>(%s-action-repeat) :<C-u>call <SID>_map_repeat()<CR>',
        \ s:prefix,
        \)
  execute printf(
        \ 'nnoremap <buffer><silent> <Plug>(%s-action-help) :<C-u>call <SID>_map_help(0)<CR>',
        \ s:prefix,
        \)
  execute printf(
        \ 'nnoremap <buffer><silent> <Plug>(%s-action-help:all) :<C-u>call <SID>_map_help(1)<CR>',
        \ s:prefix,
        \)

  if !hasmapto(printf('<Plug>(%s-action-choice)', s:prefix), 'n')
    execute printf(
          \ 'nmap <buffer> a <Plug>(%s-action-choice)',
          \ s:prefix,
          \)
  endif
  if !hasmapto(printf('<Plug>(%s-action-repeat)', s:prefix), 'n')
    execute printf(
          \ 'nmap <buffer> . <Plug>(%s-action-repeat)',
          \ s:prefix,
          \)
  endif
  if !hasmapto(printf('<Plug>(%s-action-help)', s:prefix), 'n')
    execute printf(
          \ 'nmap <buffer> ? <Plug>(%s-action-help)',
          \ s:prefix,
          \)
  endif

  let b:{s:prefix}_action = {
        \ 'actions': s:_build_actions(),
        \ 'previous': '',
        \}
endfunction

function! s:call(name, ...) abort
  let options = extend({
        \ 'capture': 0,
        \ 'verbose': 0,
        \}, a:0 ? a:1 : {},
        \)
  if !exists(printf('b:%s_action', s:prefix))
    throw 'the buffer has not been initialized for actions'
  endif
  if index(b:{s:prefix}_action.actions, a:name) is# -1
    throw printf('no action %s found in the buffer', a:name)
  endif
  let b:{s:prefix}_action.previous = a:name
  let Fn = funcref('s:_call', [a:name])
  if options.verbose
    let Fn = funcref('s:_verbose', [Fn])
  endif
  if options.capture
    let Fn = funcref('s:_capture', [Fn])
  endif
  call Fn()
endfunction

function! s:list(...) abort
  let conceal = a:0 ? a:1 : v:true
  let Sort = { a, b -> s:_compare(a[1], b[1]) }
  let rs = split(execute('nmap'), '\n')
  call map(rs, { _, v -> v[3:] })
  call map(rs, { _, v -> matchlist(v, '^\([^ ]\+\)\s*\*\?@\?\(.*\)$')[1:2] })

  " To action mapping
  let pattern1 = printf('^<Plug>(%s-action-\zs.*\ze)$', s:prefix)
  let pattern2 = printf('^<Plug>(%s-action-', s:prefix)
  let rs1 = map(copy(rs), { _, v -> v + [matchstr(v[1], pattern1)] })
  call filter(rs1, { _, v -> !empty(v[2]) })
  call filter(rs1, { _, v -> v[0] !~# '^<Plug>' || v[0] =~# pattern2 })
  call map(rs1, { _, v -> [v[0], v[2], v[1]] })

  " From action mapping
  let rs2 = map(copy(rs), { _, v -> v + [matchstr(v[0], pattern1)] })
  call filter(rs2, { _, v -> !empty(v[2]) })
  call map(rs2, { _, v -> ['', v[2], v[0]] })

  let rs = uniq(sort(rs1 + rs2, Sort), Sort)
  if conceal
    call filter(rs, { -> v:val[1] !~# ':' || !empty(v:val[0]) })
  endif

  return rs
endfunction

function! s:_map_choice() abort
  if !exists(printf('b:%s_action', s:prefix))
    throw 'the buffer has not been initialized for actions'
  endif
  call inputsave()
  try
    let fn = get(function('s:_complete_choice'), 'name')
    let expr = input('action: ', '', printf('customlist,%s', fn))
  finally
    call inputrestore()
  endtry
  let r = s:_parse_expr(expr)
  let ns = copy(b:{s:prefix}_action.actions)
  let r.name = get(filter(ns, { -> v:val =~# '^' . r.name }), 0)
  if empty(r.name)
    return
  endif
  call s:call(r.name, {
       \ 'capture': r.capture,
       \ 'verbose': r.verbose,
       \})
endfunction

function! s:_map_repeat() abort
  if !exists(printf('b:%s_action', s:prefix))
    throw 'the buffer has not been initialized for actions'
  endif
  if empty(b:{s:prefix}_action.previous)
    return
  endif
  call s:call(b:{s:prefix}_action.previous)
endfunction

function! s:_map_help(all) abort
  let rs = s:list(!a:all)

  let len0 = max(map(copy(rs), { -> len(v:val[0]) }))
  let len1 = max(map(copy(rs), { -> len(v:val[1]) }))
  let len2 = max(map(copy(rs), { -> len(v:val[2]) }))
  call map(rs, { _, v -> [
       \   printf(printf('%%-%dS', len0), v[0]),
       \   printf(printf('%%-%dS', len1), v[1]),
       \   printf(printf('%%-%dS', len2), v[2]),
       \ ]
       \})

  call map(rs, { -> join(v:val, '  ') })
  if !a:all
    echohl Title
    echo "NOTE: Some actions are concealed. Use 'help:all' action to see all actions."
    echohl None
  endif
  echo join(rs, "\n")
endfunction

function! s:_parse_expr(expr) abort
  if empty(a:expr)
    return {'name' : '', 'capture': 0, 'verbose': 0}
  endif
  let terms = split(a:expr)
  let name = remove(terms, -1)
  let Has = { ns, n -> len(filter(copy(ns), { -> v:val ==# n })) }
  return {
        \ 'name': name,
        \ 'capture': Has(terms, 'capture'),
        \ 'verbose': Has(terms, 'verbose'),
        \}
endfunction

function! s:_build_actions() abort
  let n = len(printf('%s-action-', s:prefix))
  let ms = split(execute(printf('nmap <Plug>(%s-action-', s:prefix)), '\n')
  call map(ms, { _, v -> split(v)[1] })
  call map(ms, { _, v -> matchstr(v, '^<Plug>(\zs.*\ze)$') })
  call filter(ms, { _, v -> !empty(v) })
  call map(ms, { _, expr -> expr[n :] })
  return sort(ms)
endfunction

function! s:_complete_choice(arglead, cmdline, cursorpos) abort
  if !exists(printf('b:%s_action', s:prefix))
    return []
  endif
  let names = copy(b:{s:prefix}_action.actions)
  let names += ['capture', 'verbose']
  if empty(a:arglead)
    call filter(names, { -> v:val !~# ':' })
  endif
  return filter(names, { -> v:val =~# '^' . a:arglead })
endfunction

function! s:_compare(i1, i2) abort
  return a:i1 == a:i2 ? 0 : a:i1 > a:i2 ? 1 : -1
endfunction

function! s:_call(name) abort
  execute printf(
        \ "normal \<Plug>(%s-action-%s)",
        \ s:prefix,
        \ a:name,
        \)
endfunction

function! s:_capture(fn) abort
  let output = execute('call a:fn()')
  let rs = split(output, '\r\?\n')
  execute printf('botright %dnew', len(rs))
  call setline(1, rs)
  setlocal buftype=nofile bufhidden=wipe
  setlocal noswapfile nobuflisted
  setlocal nomodifiable nomodified
  setlocal nolist signcolumn=no
  setlocal nonumber norelativenumber
  setlocal cursorline
  nnoremap <buffer><silent> q :<C-u>q<CR>
endfunction

function! s:_verbose(fn) abort
  let verbose_saved = &verbose
  try
    set verbose
    call a:fn()
  finally
    let &verbose = verbose_saved
  endtry
endfunction
