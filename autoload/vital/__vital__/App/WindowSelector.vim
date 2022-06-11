function! s:select(winnrs, ...) abort
  let options = extend({
        \ 'auto_select': 0,
        \ 'select_chars': split('abcdefghijklmnopqrstuvwxyz', '\zs'),
        \ 'statusline_hl': 'VitalWindowSelectorStatusLine',
        \ 'indicator_hl': 'VitalWindowSelectorIndicator',
        \ 'use_winbar': &laststatus is# 3 && exists('&winbar'),
        \}, a:0 ? a:1 : {})
  if !options.use_winbar && &laststatus is# 3
    echohl WarningMsg
    echomsg 'vital: App.WindowSelector: The laststatus=3 on Neovim requires winbar feature to show window indicator'
    echohl None
  endif
  if options.auto_select && len(a:winnrs) <= 1
    call win_gotoid(len(a:winnrs) ? win_getid(a:winnrs[0]) : win_getid())
    return 0
  endif
  let target = options.use_winbar ? '&winbar' : '&statusline'
  let length = len(a:winnrs)
  let store = {}
  for winnr in a:winnrs
    let store[winnr] = getwinvar(winnr, target)
  endfor
  try
    let scs = options.select_chars
    let chars = map(
          \ range(length + 1),
          \ { _, v -> get(scs, v, string(v)) },
          \)
    let l:S = funcref('s:_statusline', [
          \ options.statusline_hl,
          \ options.indicator_hl,
          \])
    call map(keys(store), { k, v -> setwinvar(v, target, S(v, chars[k])) })
    redrawstatus
    call s:_cnoremap_all(chars)
    let n = input('choose window: ')
    call s:_cunmap_all()
    redraw | echo
    if n is# v:null
      return 1
    endif
    let n = index(chars, n)
    if n is# -1
      return 1
    endif
    call win_gotoid(win_getid(a:winnrs[n]))
  finally
    call map(keys(store), { _, v -> setwinvar(v, target, store[v]) })
    redrawstatus
  endtry
endfunction

function! s:_statusline(statusline_hl, indicator_hl, winnr, char) abort
  let width = winwidth(a:winnr) - len(a:winnr . '') - 6
  let leading = repeat(' ', width / 2)
  return printf(
        \ '%%#%s#%s%%#%s#   %s   %%#%s#',
        \ a:statusline_hl,
        \ leading,
        \ a:indicator_hl,
        \ a:char,
        \ a:statusline_hl,
        \)
endfunction

function! s:_cnoremap_all(chars) abort
  for nr in range(256)
    silent! execute printf("cnoremap \<buffer>\<silent> \<Char-%d> \<Nop>", nr)
  endfor
  for char in a:chars
    silent! execute printf("cnoremap \<buffer>\<silent> %s %s\<CR>", char, char)
  endfor
  silent! cunmap <buffer> <Return>
  silent! cunmap <buffer> <Esc>
endfunction

function! s:_cunmap_all() abort
  for nr in range(256)
    silent! execute printf("cunmap \<buffer> \<Char-%d>", nr)
  endfor
endfunction


function! s:_highlight() abort
  highlight default link VitalWindowSelectorStatusLine StatusLineNC
  highlight default link VitalWindowSelectorIndicator  DiffText
endfunction

augroup vital_app_window_selector_internal
  autocmd!
  autocmd ColorScheme * call s:_highlight()
augroup END

call s:_highlight()
