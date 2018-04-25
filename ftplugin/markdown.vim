" TODO: study this folding code from tpope vim-markdown{{{

" setl fdm=expr fde=Markdown_fold() fdt=Markdown_fold_text()

" fu! Markdown_fold_text() abort
"     let hash_indent = s:hash_indent(v:foldstart)
"     let title       = substitute(getline(v:foldstart), '^#\+\s*', '', '')
"     let foldsize    = (v:foldend - v:foldstart + 1)
"     let linecount   = '['.foldsize.' lines]'
"     return hash_indent.' '.title.' '.linecount
" endfu

" fu! Markdown_fold() abort
"     let line = getline(v:lnum)

"     " Regular headers
"     let depth = match(line, '\(^#\+\)\@<=\( .*$\)\@=')
"     if depth > 0
"         return '>'.depth
"     endif

"     " Setext style headings
"     let nextline = getline(v:lnum + 1)
"     if (line =~ '^.\+$') && (nextline =~ '^=\+$')
"         return '>1'
"     endif

"     if (line =~ '^.\+$') && (nextline =~ '^-\+$')
"         return '>2'
"     endif

"     return '='
" endfu

" fu! s:hash_indent(lnum) abort
"     let hash_header = matchstr(getline(a:lnum), '^#\{1,6}')
"     if len(hash_header) > 0
"         " hashtag header
"         return hash_header
"     else
"         " == or -- header
"         let nextline = getline(a:lnum + 1)
"         if nextline =~ '^=\+\s*$'
"             return repeat('#', 1)
"         elseif nextline =~ '^-\+\s*$'
"             return repeat('#', 2)
"         endif
"     endif
" endfu
"}}}

" HTML tags can be used in Markdown, therefore, we also load html ftplugins.
"     https://daringfireball.net/projects/markdown/syntax#html
"
" We consider the 3 possible naming schemes
runtime! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
"      │
"      └─ all of them (even if there's several ftplugin/html.vim in various
"         directories of &rtp)

" TODO:
" read this:
"         http://www.oliversherouse.com/2017/08/21/vim_zero.html
"
" And this:
"         https://www.romanzolotarev.com/jekyll/
"
" Jekyll is a program which could convert our markdown notes into webpages.
" We could read the latter in firefox.

" TODO:
" Create a plugin, and move the functions in `autoload/`.

" TODO:
" Study this plugin.
"
"     https://github.com/vim-pandoc/vim-rmarkdown
"     https://rmarkdown.rstudio.com/lesson-1.html
"     https://rmarkdown.rstudio.com/authoring_pandoc_markdown.html#philosophy
"
" And maybe these ones:
"
"     https://github.com/jalvesaq/Nvim-R
"     https://github.com/gaalcaras/ncm-R
"
" You may need to read these 2 books:
"
"     https://www.amazon.com/Dynamic-Documents-knitr-Second-Chapman/dp/1498716962/
"     https://www.amazon.com/Data-Science-Transform-Visualize-Model/dp/1491910399/
"
" We've already downloaded them.
"
" Also read this:
" https://medium.freecodecamp.org/turning-vim-into-an-r-ide-cd9602e8c217

" Commands {{{1

com! -buffer FoldToggle call fold#md#toggle_fde()

cnorea <expr> <buffer> foldtoggle  getcmdtype() is# ':' && getcmdline() is# 'foldtoggle'
\                                  ?    'FoldToggle'
\                                  :    'foldtoggle'

com! -buffer -range=%  FoldSortBySize  exe fold#md#sort_by_size(<line1>,<line2>)

cnorea  <buffer><expr>  foldsortbysize  getcmdtype() is# ':' && getcmdline() is# 'foldsortbysize'
\                                       ?    'FoldSortBySize'
\                                       :    'foldsortbysize'

" Mappings {{{1

" Don't put a guard around the mappings,{{{
" to check the existence of `lg#motion#regex#rhs()`.
" Why?
"
" Because  of `b:undo_ftplugin`. If  the  function doesn't  exist, the  mappings
" won't be installed.  But the teardown  will still try to remove them. So, when
" you'll reload  a markdown  buffer, or  change its filetype,  it will  raise an
" error.
"}}}
noremap  <buffer><expr><nowait><silent>  [[  lg#motion#regex#rhs('#',0)
noremap  <buffer><expr><nowait><silent>  ]]  lg#motion#regex#rhs('#',1)

if has_key(get(g:, 'plugs', {}), 'vim-lg-lib')
    call lg#motion#repeatable#make#all({
    \        'mode':   '',
    \        'buffer': 1,
    \        'axis':   {'bwd': ',', 'fwd': ';'},
    \        'from':   expand('<sfile>:p').':'.expand('<slnum>'),
    \        'motions': [{'bwd': '[[',  'fwd': ']]'}]
    \ })
endif

" Options {{{1
" ai {{{2

" There's no  indent plugin in $VIMRUNTIME/indent/, so we  use 'autoindent' as a
" poor-man's solution.
setl ai

" cms {{{2

" template for a comment (taken from html); will be used by `gc` (could also
" be used by `zf` &friends, if &l:fdm = 'manual')
setl cms=<!--%s-->

" com {{{2

"        ┌─ Only the first line has the comment leader.
"        │  Do not repeat comment on the next line, but preserve indentation:
"        │  useful for bullet-list.
"        │
"        │ ┌─ Nested comment.
"        │ │  Nesting with mixed parts is allowed.
"        │ │  Ex: if 'comments' is "n:•,n:-", a line starting with "• -" is a comment.
"        │ │                                                        └─┤
"        │ │                                                          └ mixed
setl com=fbn:•,fbn:-,fb:*,fb:+
"         │
"         └─ Blank (Space, Tab or EOL) required after the comment leader.
"            So here, '• hello' would be recognized as a comment, but not '•hello'.

" What's the purpose of 'com'? {{{
"
" 'comments' contains a list of strings which can start a commented line.
" Vim needs to know what the comment leader is in various occasions:
"
"         • if 'fo' contains the flag `r`, and we open a new line, hitting CR
"           from insert mode, Vim needs to know what to prepend at the
"           beginning
"
"           same thing if 'fo' contains the flag `o`, and we open a new line,
"           hitting o O from normal mode
"
"         • if 'fo' contains the flag `c`, Vim automatically wraps a long
"           commented line; when it breaks the current line, and open a new
"           one, it must know what to prepend at the beginning
"
"         • when we format a comment with the `gw` operator, Vim needs to know
"           what the comment leader is, to be able to remove / add it when it
"           joins / splits lines

" We aren't limited to single-line comments.
" We can make Vim recognize multi-line ones too.
" Doing so allows us to format them with `gw`.
"}}}
" Don't confuse 'com' with 'cms'{{{
"
" 'cms' is just a template used by folding commands (ex: `zf`) when they have
" to (un)comment a marker which they need to add/remove on the starting/ending
" line of a fold.
" We often use it to infer what a comment looks like, because it's easier than
" parsing 'com', but that's it.
"
"                          ┌ %s is replaced by "{{{ and "}}}  at the end of resp.
"                          │ the starting line of the fold and the ending line of the fold
"                 ┌────────┤
"         "%s  →  "{{{  "}}}
"         └─┤
"           └ template
"}}}
" What's the meaning of the 'f' flag? {{{

" Here's a long line:
"
"         • some very long comment some very long comment some very long comment some very long comment

" If we type this line in a markdown buffer, or if it has already been typed and
" we press `gwip`:
"
" Without the `f` flag and with `&l:tw = 80`, we get:
"
"         • some very long comment some very long comment some very long comment some
"         • very long comment
"
" With the `f` flag and `&l:tw = 80`, we get:
"
"         • some very long comment some very long comment some very long comment some
"           very long comment
"
" This shows  why `f` is important  for a comment  leader used as a  bullet list
" marker. The meaning  of a  comment leader  depends on  the context  where it's
" used. It means that all the text between it and the next comment leader:
"
"       • is commented in a regular paragraph
"       • belongs to a same item in a bullet list
"
" So, you can break/join the lines of a regular paragraph, however you like,
" without changing its meaning. But you can't do the same for a bullet list.
"
" Technically, if `f` is absent, Vim will add a marker every time it has to
" break down a line, which is wrong in a bullet list.
" }}}
" What's the meaning of the 'n' flag? {{{
"
" It's useful  to let Vim know  that 2 comment leaders  can be nested. Otherwise
" `gw` won't set the proper indentation level for all the lines.
" MWE:
"     • - some very long comment some very long comment some very long comment some very long comment
"
" Without `n`:
"
"       ┌─ interpreted as a part of the comment
"       │
"     • - some very long comment some very long comment some very long comment some
"       very long comment
"
" With `n`:
"       ┌─ recognized as a (nested) comment leader
"       │
"     • - some very long comment some very long comment some very long comment
"         some very long comment
"
" }}}
" flp "{{{2

"                           ┌ recognize numbered lists
"                     ┌─────┤
let &l:flp = '\v^\s*%(\d+[.)]|[-*+•])\s+'
"                             └────┤
"                                  └ recognize unordered lists

" Is 'flp' used automatically? {{{
"
" No, you also need to include the  `n` flag inside 'fo' (we did in vimrc). This
" tells Vim to use 'flp' to recognize lists when we use `gw`.
"}}}
" What's the effect?{{{
"
" Some text:
"
"     1. some very long line some very long line some very long line some very long line
"     2. another very long line another very long line another very long line another line
"
" Press `gwip` WITHOUT `n` inside 'fo':
"
"         1. some very long line some very long line some very long line some very
"     long line 2. another very long line another very long line another very long
"     line another line
"
" Press `gwip` WITH `n` inside 'fo', and the right pattern in 'flp':
"
"     1. some very long line some very long line some very long line some very
"        long line
"     2. another very long line another very long line another very long line
"        another line
" }}}
" Why use `let &l:` instead of `setl`? {{{
"
" With `setl`, you  have to double the backslashes because  the value is wrapped
" inside a non-literal string.
"
" Also, you have to add an extra backslash for every pipe character
" (alternation), because one is removed by Vim to toggle its special meaning
" (command separator).
"
" So:    2 backslashes for metacharacters (atoms, quantifiers, …)
"        3 backslashes for pipes
" }}}
" After pressing `gwip` in a list, how are the lines indented?{{{
"
" The indent of the text after the list header is used for the next line.
"}}}
" Compared to tpope ftplugin, our pattern is simpler. {{{
"
" He has added a third branch to describe a footnote. Sth looking like this:
"         ^[abc]:
"
" https://github.com/tpope/vim-markdown/commit/14977fb9df2984067780cd452e51909cf567ee9d
" I don't know how it's useful, so I didn't copy it.
" The title of the commit is:
"         Indent the footnotes also.
" }}}
" Don't conflate the `n` flag in 'fo' with the one in 'com'. {{{
"
" There's zero link between the two. This could confuse you:
"
"     setl com=f:•
"     let &l:flp = ''
"
"             • some very long line some very long line some very long line some very long line
"             • another very long line another very long line another very long line another line
"
"     gwip
"             • some very long line some very long line some very long line some
"               very long line
"             • another very long line another very long line another very long
"               line another line
"
" It worked. Vim formatted the list as we wanted. But it's a side effect of `•`
" being recognized as a comment leader, and using the `f` flag.
" For a numbered list, you have to add the `n` flag in 'fo', and include the right
" pattern in 'flp'. Why?
" Because you can't use a pattern inside 'com', only literal strings.
" }}}

" folding + conceal "{{{2
" Why don't we set the folding options directly, instead of using an autocmd?{{{
"
" When we load a markdown buffer, the window-local options:
"
"       • foldmethod
"       • foldexpr
"       • foldtext
"
" … are set properly.
"
" But after that, if we display it again in another window, using any motion
" which doesn't read a buffer:
"
"       • 'A
"       • :b42
"       • gf
"       • C-o
"       …
"
" … they aren't set anymore.
"
" Some of them ('A, gf, …) may read a buffer, but only if it doesn't already exist.
" So, most of the time:
"
"        1. BufReadPost is NOT fired
"        2. Filetype is NOT fired
"        3. the ftplugins are NOT sourced
"
" Because of this, we may lose folding when we redisplay one of our markdown
" notes in a window where it wasn't initially sourced.
"
" The pb doesn't occur if we split the window where a markdown buffer was
" first displayed. Because the new window inherits the options of the original.
"
" This problem isn't specific to these 3 options, but to ALL window-local options.
" Once a buffer is loaded in a window, we have no guarantee that its window-local
" options will be applied:
"
"        • in other windows
"        • in its initial window, if in the meantime we loaded another buffer
"          whose window-local options were in conflict
"}}}
" Are there other solutions?{{{
"
" Yes:
"
"    • :e                     re-fire `FileType`
"    • :let &ft=&ft           "
"    • :doautocmd FileType    "
"}}}
" Why `BufWinEnter` instead of `WinEnter`?{{{
"
" We can't use `WinEnter` for 2 reasons:
"
"     • too frequent
"     • not fired when we load a buffer (:e /path/to/file)
"}}}
augroup my_markdown
    " Why `au! * <buffer>` instead of simply `au!`?{{{
    "
    " We can't remove all autocmds with `au!`.
    " Suppose we load a markdown buffer A, whose number is 2:
    "
    "       it installs an autocmd for buffer 2 (<buffer=2>)
    "
    " Then, we load another one B, whose number is 4:
    "
    "       it removes the autocmd for buffer 2
    "       it installs an autocmd for buffer 4 (<buffer=4>)
    "
    " Finally, we re-display A in a new window:
    "
    "       our window-local settings won't be applied, because there's no autocmd
    "       for the pattern <buffer=2> anymore
    "
    " We must remove autocmds only for the current buffer.
"}}}
    " Usually, we don't need to pass a pattern to `au!`, what's different here?{{{
    "
    " Usually, we re-install as many autocmds as we've removed:
    "
    "       au!                               remove     for ALL buffers
    "       au CursorHold * checktime         re-install for ALL buffers (*)
    "
    "       au!                               remove     for `some_file`
    "       au BufEnter some_file some_cmd    re-install for `some_file`
    "
    " But not here:
    "
    "       au!                          remove          for ALL previous buffers, whose filetype was markdown
    "       au BufWinEnter <buffer> …    re-install ONLY for CURRENT buffer
"}}}
    au! * <buffer>
    " │ │ │
    " │ │ └─ but ONLY the ones LOCAL to the CURRENT buffer
    " │ └─ listening to any event
    " └─ remove autocmds in the current augroup

    " When we load A, this will only remove autocmds for the pattern `<buffer=2>`.
    " When we load B, this will only remove autocmds for the pattern `<buffer=4>`.
    " And every time, the next `:au` re-installs a single instance of the needed autocmd.

    au BufWinEnter  <buffer>  setl fml=0
                           \| setl fdm=expr
                           \| setl fdt=fold#text()
                           \| setl fde=fold#md#stacked()
                           "                   │
                           "                   └─ Alternative: 'nested()'
    au BufWinEnter <buffer> setl cole=2 cocu=nc
augroup END

" fp  tw {{{2

setl tw=80

" We want `gq` to use par in a markdown buffer.
let &l:fp = 'par -w'.&l:tw.'rjeq'

" kp "{{{2

" In our HTML plugin (~/.vim/after/ftplugin/html.vim), we've set up the web
" browser to look for the word under the cursor when we hit K.
" But, in a markdown buffer, we prefer `:Man` or `:help`.

if expand('%:p') =~# 'wiki/vim'
    setl kp=:help
else
    setl kp=:Man
endif

" spl "{{{2

setl spl=en

" Variables {{{1

" We don't want other ftplugins to be sourced.
" The less code, the faster we can reload our notes.
let b:did_ftplugin = 1

" When we hit `CR`, we want the cursor to move on the 100th column.
" By default, it moves on the 80th column.

let b:cr_command = 'norm! 100|'

" We've set up `vim-exchange` to re-indent linewise exchanges with `==`.
" But we don't want that for markdown buffers.
" For more info:    :h g:exchange_indent

let b:exchange_indent = ''

" Let us conceal the answer to a question with by pressing `sa {text-object} c`.
sil! let b:sandwich_recipes =  deepcopy(g:sandwich#recipes)
\  + [ {'buns':    ['↣ ', ' ↢'],
\       'input':   ['c'],
\       'command': ["']mark z",
\                   "keepj keepp '[s/^\\s*↣\\s*$/↣/e",
\                   "keepj keepp 'zs/^\\s*↢\\s*$/↢/e"]}
\ ]

" Teardown {{{1

let b:undo_ftplugin =          get(b:, 'undo_ftplugin', '')
\                     . (empty(get(b:, 'undo_ftplugin', '')) ? '' : '|')
\                     . "
\                           setl ai< cms< cocu< cole< com< fde< fdm< fdt< flp< fml< fp< kp< spl< tw<
\                         | unlet! b:cr_command b:exchange_indent b:sandwich_recipes
\                         | exe 'au!  my_markdown * <buffer>'
\                         | exe 'unmap <buffer> [['
\                         | exe 'unmap <buffer> ]]'
\                         | exe 'cuna   <buffer> foldsortbysize'
\                         | exe 'cuna   <buffer> foldtoggle'
\                         | delc FoldSortBySize
\                         | delc FoldToggle
\                       "
