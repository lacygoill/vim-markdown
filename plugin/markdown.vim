if exists('g:loaded_markdown')
    finish
endif
let g:loaded_markdown = 1

" TODO:  remove  this  file  and the  `#fix_fenced_code_block()`  function  once
" https://github.com/vim/vim/issues/6587 is fixed.

" In a Vim9 script, don't highlight a custom Vim function (called without `:call`) with `vimUsrCmd`.
augroup MarkdownFixFencedCodeBlock | au!
    au Syntax markdown call markdown#fix_fenced_code_block()
augroup END

