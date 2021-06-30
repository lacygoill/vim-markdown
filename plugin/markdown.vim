vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# TODO:  remove  this  file  and the  `#fix_fenced_code_block()`  function  once
# https://github.com/vim/vim/issues/6587 is fixed.

# In a Vim9 script, don't highlight a custom Vim function (called without `:call`) with `vimUsrCmd`.
augroup MarkdownFixFencedCodeBlock | autocmd!
    autocmd Syntax markdown markdown#fixFencedCodeBlock()
augroup END

