function! s:select(winnrs, ...) abort
  let options = extend({
        \ 'auto_select': 0,
        \ 'select_chars': split('abcdefghijklmnopqrstuvwxyz', '\zs'),
        \ 'statusline_hl': 'VitalWindowSelectorStatusLine',
        \ 'indicator_hl': 'VitalWindowSelectorIndicator',
        \ 'use_popup': 0,
        \ 'popup_borderchars': ['╭', '─', '╮', '│', '╯', '─', '╰', '│'],
        \}, a:0 ? a:1 : {})
  if options.auto_select && len(a:winnrs) <= 1
    call win_gotoid(len(a:winnrs) ? win_getid(a:winnrs[0]) : win_getid())
    return 0
  endif
  let length = len(a:winnrs)
  try
    let scs = options.select_chars
    let chars = map(
          \ range(length + 1),
          \ { _, v -> get(scs, v, string(v)) },
          \)
    if options.use_popup
      if len(options.popup_borderchars) != 8
        throw printf('vital: App.WindowSelector: number of popup_borderchars must be eight')
      endif

      let borderchars = s:_normalize_popup_borderchars(options.popup_borderchars)
      call s:_popup(a:winnrs, options.select_chars, borderchars)
      redraw
    else
      let store = {}
      for winnr in a:winnrs
        let store[winnr] = getwinvar(winnr, '&statusline')
      endfor
      let l:S = funcref('s:_statusline', [
            \ options.statusline_hl,
            \ options.indicator_hl,
            \])
      call map(keys(store), { k, v -> setwinvar(v, '&statusline', S(v, chars[k])) })
      redrawstatus
    endif

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
    if options.use_popup
      call s:_clear_popups()
    else
      call map(keys(store), { _, v -> setwinvar(v, '&statusline', store[v]) })
      redrawstatus
    endif
  endtry
endfunction

" Convert popup window border character order to float window border character order
function! s:_normalize_popup_borderchars(chars) abort
  if has('nvim')
    return a:chars
  endif

  let borderchars = repeat([''], 8)
  " this is index for convert to float window border characters
  let idx = [4, 0, 5, 3, 6, 2, 7, 1]
  for i in range(len(idx))
    let borderchars[idx[i]] = a:chars[i]
  endfor
  return borderchars
endfunction

let s:_popup_winids = []

if has('nvim')
  function! s:_clear_popups() abort
    for winid in s:_popup_winids
      call nvim_win_close(winid, 1)
    endfor
    let s:_popup_winids = []
  endfunction

  function! s:_popup(winnrs, chars, borderchars) abort
    for idx in range(len(a:winnrs))
      let winnr = a:winnrs[idx]
      let char = a:chars[idx]
      let [width, height] = [(winwidth(winnr) - len(char) -2)/2, (winheight(winnr) - 1)/2]

      let bufnr = nvim_create_buf(0, 1)
      let text = printf(' %s ', char)

      call nvim_buf_set_lines(bufnr, 0, -1, 1, [text])
      let opt = {
            \ 'relative': 'win',
            \ 'win': win_getid(winnr),
            \ 'width': len(text),
            \ 'height': 1,
            \ 'col': width,
            \ 'row': height,
            \ 'anchor': 'NE',
            \ 'style': 'minimal',
            \ 'focusable': 0,
            \ 'border': map(copy(a:borderchars), { _, v -> [v, 'NormalFloat'] }),
            \ }
      let winid = nvim_open_win(bufnr, 1, opt)
      call add(s:_popup_winids, winid)
    endfor
  endfunction

else
  function! s:_clear_popups() abort
    for winid in s:_popup_winids
      call popup_close(winid)
    endfor
    let s:_popup_winids = []
  endfunction

  function! s:_popup(winnrs, chars, borderchars) abort
    for idx in range(len(a:winnrs))
      let winnr = a:winnrs[idx]
      let char = a:chars[idx]

      let [width, height] = [(winwidth(winnr) - len(char) -2)/2, (winheight(winnr) - 1)/2]
      let [winrow, wincol] = win_screenpos(winnr)
      let row = winrow + height
      let col = wincol + width

      let winid = popup_create([printf(' %s ', char)], {
            \ 'col': col,
            \ 'line': row,
            \ 'border': [1, 1, 1, 1],
            \ 'borderchars': copy(a:borderchars),
            \ }) 
      call add(s:_popup_winids, winid)
    endfor
  endfunction

endif

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
