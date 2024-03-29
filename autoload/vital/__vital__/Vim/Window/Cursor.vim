if !exists('*nvim_win_get_cursor')
  function! s:get_cursor(winid) abort
    if win_getid() is# a:winid
      let cursor = getpos('.')
      return [cursor[1], cursor[2] - 1]
    else
      let winid_saved = win_getid()
      try
        noautocmd call win_gotoid(a:winid)
        return s:get_cursor(a:winid)
      finally
        noautocmd call win_gotoid(winid_saved)
      endtry
    endif
  endfunction
else
  function! s:get_cursor(winid) abort
    return nvim_win_get_cursor(a:winid)
  endfunction
endif

if !exists('*nvim_win_set_cursor')
  function! s:set_cursor(winid, pos) abort
    if win_getid() is# a:winid
      let cursor = [0, a:pos[0], a:pos[1] + 1, 0]
      call setpos('.', cursor)
    else
      let winid_saved = win_getid()
      try
        noautocmd call win_gotoid(a:winid)
        call s:set_cursor(a:winid, a:pos)
      finally
        noautocmd call win_gotoid(winid_saved)
      endtry
    endif
  endfunction
else
  function! s:set_cursor(winid, pos) abort
    try
      call nvim_win_set_cursor(a:winid, a:pos)
    catch /Cursor position outside buffer/
      " Do nothing
    endtry
  endfunction
endif
