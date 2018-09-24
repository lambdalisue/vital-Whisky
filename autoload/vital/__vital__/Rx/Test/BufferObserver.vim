function! s:new(...) abort
  let p = extend({
        \ 'next': 'n:',
        \ 'error': 'e:',
        \ 'complete': 'c',
        \}, a:0 ? a:1 : {},
        \)
  let b = { 'results': [] }
  return extend(b, {
        \ 'next': { v -> add(b.results, printf('%s%s', p.next, v)) },
        \ 'error': { e -> add(b.results, printf('%s%s', p.error, e)) },
        \ 'complete': { -> add(b.results, p.complete) },
        \})
endfunction
