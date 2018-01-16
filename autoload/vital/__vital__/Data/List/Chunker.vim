function! s:_vital_healthcheck() abort
  if has('patch-8.0.0001') || has('nvim-0.2.0')
    return
  endif
  return 'Data.List.Chunker requires Vim 8.0.0001 or Neovim 0.2.0'
endfunction

function! s:new(size, candidates) abort
  return {
        \ '__cursor': 0,
        \ 'next': function('s:_chunker_next', [a:size, a:candidates]),
        \}
endfunction

function! s:_chunker_next(size, candidates) abort dict
  let prev_cursor = self.__cursor
  let self.__cursor = self.__cursor + a:size
  return a:candidates[ prev_cursor : (self.__cursor - 1) ]
endfunction
