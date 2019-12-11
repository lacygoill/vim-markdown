if exists('b:did_ftplugin')
    finish
endif

" TODO: study this folding code from tpope vim-markdown{{{

" setl fdm=expr fde=Markdown_fold() fdt=Markdown_fold_text()

" fu Markdown_fold_text() abort
"     let hash_indent = s:hash_indent(v:foldstart)
"     let title       = substitute(getline(v:foldstart), '^#\+\s*', '', '')
"     let foldsize    = (v:foldend - v:foldstart + 1)
"     let linecount   = '['.foldsize.' lines]'
"     return hash_indent.' '.title.' '.linecount
" endfu

" fu Markdown_fold() abort
"     let line = getline(v:lnum)

"     " Regular headers
"     let depth = match(line, '\(^#\+\)\@6<=\( .*$\)\@=')
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

" fu s:hash_indent(lnum) abort
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

" Would it make sense to also source html filetype plugins?{{{
"
" Yes, because html tags can be used in Markdown:
"
"     https://daringfireball.net/projects/markdown/syntax#html
"
" Besides, that's what tpope does in its markdown plugin.
"}}}
" How could I source them?{{{
"
" You would need to consider the 3 possible naming schemes:
"
"     ru! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
"       │
"       └ all of them
"         (even if there are several ftplugin/html.vim in various directories of &rtp)
"}}}
" Why don't you source them?{{{
"
" We have some html settings which are undesirable in markdown.
"
" Examples:
" We set `'sw'` to 2 in an html  file (as per google style guide), but we prefer
" to set it to 4 in a markdown file.
"
" In our  HTML plugin (`~/.vim/after/ftplugin/html.vim`),
" We set up  the web browser to look for the word under the cursor when we press `K`.
" But, in a markdown buffer, we prefer a more granular approach.
" Sometimes, `:Man`,  sometimes `:help`,  and maybe other  values in  the future
" depending on the location of the file.
"}}}

" TODO:
" read this: http://www.oliversherouse.com/2017/08/21/vim_zero.html
"
" And this: https://www.romanzolotarev.com/jekyll/
"
" Jekyll is a program which could convert our markdown notes into webpages.
" We could read the latter in firefox.

" TODO:
" Study this plugin.
"
" https://github.com/vim-pandoc/vim-rmarkdown
" https://rmarkdown.rstudio.com/lesson-1.html
" https://rmarkdown.rstudio.com/authoring_pandoc_markdown.html#philosophy
"
" And maybe these ones:
"
" https://github.com/jalvesaq/Nvim-R
" https://github.com/gaalcaras/ncm-R
" https://github.com/SidOfc/mkdx
"
" You may need to read these 2 books:
"
" https://www.amazon.com/Dynamic-Documents-knitr-Second-Chapman/dp/1498716962/
" https://www.amazon.com/Data-Science-Transform-Visualize-Model/dp/1491910399/
"
" We've already downloaded them.
"
" Also read this:
" https://medium.freecodecamp.org/turning-vim-into-an-r-ide-cd9602e8c217

" Commands {{{1

com -bar -buffer -complete=custom,markdown#check#punctuation_complete -nargs=1 -range=%
    \ CheckPunctuation  echo markdown#check#punctuation(<q-args>, <line1>, <line2>)
    "                   │{{{
    "                   └ useful to erase the command from the command-line after its execution
    "}}}

com -bar -buffer -complete=custom,markdown#commit_hash2link#completion -nargs=1 -range=% CommitHash2Link call markdown#commit_hash2link#main(<line1>,<line2>, <q-args>)

" Warning: Don't call this command `:Fix`. It wouldn't work as expected with `:argdo`.
com -bar -buffer FixFormatting call markdown#fix_formatting()

com -bar -buffer -range=%  FoldSortBySize  exe fold#md#sort#by_size(<line1>,<line2>)

" Purpose: Convert inline link:{{{
"
"     [text](url)
"
" ...  to reference link:
"
"     [text][ref]
"
"  Make it local to markdown
"}}}
com -buffer -bar -range=% LinkInline2Ref  call markdown#link_inline2ref#main()

com -buffer -bar Preview call markdown#preview#main()

" Mappings {{{1

nno <buffer><nowait><silent> cof :<c-u>call fold#md#fde#toggle()<cr>

nno <buffer><nowait><silent> gd :<c-u>call markdown#get_definition#main()<cr>
xno <buffer><nowait><silent> gd :<c-u>call markdown#get_definition#main('vis')<cr>
nno <buffer><nowait><silent> gl :<c-u>call fold#md#how_many#print()<cr>

nno <buffer><nowait><silent> +[# :<c-u>call markdown#put_fold(0)<cr>
nno <buffer><nowait><silent> +]# :<c-u>call markdown#put_fold(1)<cr>

" Options {{{1
" ai {{{2

" There's no  indent plugin in $VIMRUNTIME/indent/, so we  use 'autoindent' as a
" poor-man's solution.
setl ai

" cms {{{2

" template for a comment (taken from html); will be used by `gc` (could also
" be used by `zf` &friends, if &l:fdm = 'manual')
setl cms=>\ %s

" comments {{{2

"        ┌ Only the first line has the comment leader.{{{
"        │ Do not repeat comment on the next line, but preserve indentation:
"        │ useful for bullet-list.
"        │
"        │┌ Blank (Space, Tab or EOL) required after the comment leader.
"        ││ So here, '- hello' would be recognized as a comment, but not '-hello'.
"        ││
"        ││┌ Nested comment.
"        │││ Nesting with mixed parts is allowed.
"        │││ Ex: if 'comments' is "n:*,n:-", a line starting with "* -" is a comment.
"        │││                                                       ├─┘
"        │││                                                       └ mixed
"        │││}}}
setl com=fbn:-,fb:*,fb:+

" What's the purpose of 'com'? {{{
"
" 'comments' contains a list of strings which can start a commented line.
" Vim needs to know what the comment leader is in various occasions:
"
"    - if 'fo' contains the flag `r`, and we open a new line, hitting CR
"      from insert mode, Vim needs to know what to prepend at the
"      beginning
"
"      same thing if 'fo' contains the flag `o`, and we open a new line,
"      hitting o O from normal mode
"
"    - if 'fo' contains the flag `c`, Vim automatically wraps a long
"      commented line; when it breaks the current line, and open a new
"      one, it must know what to prepend at the beginning
"
"    - when we format a comment with the `gw` operator, Vim needs to know
"      what the comment leader is, to be able to remove / add it when it
"      joins / splits lines

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
"                 ┌ %s is replaced by "{{_{ and "}}_}  at the end of resp.
"                 │ the starting line of the fold and the ending line of the fold
"                 ├──────────┐
"         "%s  →  "{{_{  "}}_}
"         ├─┘
"         └ template
"}}}
" What's the meaning of the 'f' flag? {{{

" Here's a long line:
"
"     - some very long comment some very long comment some very long comment some very long comment

" If we type this line in a markdown buffer, or if it has already been typed and
" we press `gwip`:
"
" Without the `f` flag and with `&l:tw = 80`, we get:
"
"     - some very long comment some very long comment some very long comment some
"     - very long comment
"
" With the `f` flag and `&l:tw = 80`, we get:
"
"     - some very long comment some very long comment some very long comment some
"       very long comment
"
" This shows  why `f` is important  for a comment  leader used as a  bullet list
" marker. The meaning  of a  comment leader  depends on  the context  where it's
" used. It means that all the text between it and the next comment leader:
"
"    - is commented in a regular paragraph
"    - belongs to a same item in a bullet list
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
"     * - some very long comment some very long comment some very long comment some very long comment
"
" Without `n`:
"
"       ┌ interpreted as a part of the comment
"       │
"     * - some very long comment some very long comment some very long comment some
"       very long comment
"
" With `n`:
"       ┌ recognized as a (nested) comment leader
"       │
"     * - some very long comment some very long comment some very long comment
"         some very long comment
"
" }}}

" compiler {{{2

try | compiler pandoc | catch /^Vim\%((\a\+)\)\=:E666:/ | endtry

" folding + conceal "{{{2

augroup my_fold_markdown
    au BufWinEnter,FileChangedShellPost <buffer>
        \   setl fml=0
        \ | setl fdm=expr
        \ | setl fdt=fold#fdt#get()
        \ | setl fde=fold#md#fde#stacked()
        \ | setl cole=2
        \ | setl cocu=nc
augroup END

" fp  tw {{{2

setl tw=80

" We want `gq` to use par in a markdown buffer.
let &l:fp = 'par -w'.&l:tw.'rjeq'

" kp "{{{2

if expand('%:p') =~# '/wiki/vim/'
    setl kp=:help
else
    setl kp=:Man
endif

" spl "{{{2

setl spl=en

" wrap "{{{2

" It's nice to have when we're reading the wiki of a github project.
setl wrap
" }}}1
" Variables {{{1
" cr_command {{{2

" When we hit `CR`, we want the cursor to move on the 100th column.
" By default, it moves on the 80th column.

const b:cr_command = 'norm! 100|'

" exchange_indent {{{2

" We've set up `vim-exchange` to re-indent linewise exchanges with `==`.
" But we don't want that for markdown buffers.
" For more info:    :h g:exchange_indent

const b:exchange_indent = ''

" markdown_embed {{{2

" We want  syntax highlighting  in fenced  blocks, but  only for  certain files,
" because  the more  you  add syntax  plugins,  the  more it  has  an impact  on
" performance.

if search('^```\S\+', 'n')
    const b:markdown_embed = map(uniq(sort(filter(getline(1, '$'),
        \ {_,v -> v =~# '^```\S\+'}))),
        \ {_,v -> matchstr(v, '```\zs[a-z]\+')})
endif

" mc_chain {{{2

const b:mc_chain =<< trim END
    file
    keyn
    tags
    ulti
    dict
    abbr
    c-n
END

" sandwich_recipes {{{2

" Let us conceal the answer to a question by pressing `sa {text-object} c`.
const b:sandwich_recipes = deepcopy(get(g:, 'sandwich#recipes', get(g:, 'sandwich#default_recipes', [])))
    \ + [{
    \     'buns': ['↣ ', ' ↢'],
    \     'input': ['c'],
    \     'command': [
    \         "']mark z",
    \         "keepj keepp '[s/^\\s*↣\\s*$/↣/e",
    \         "keepj keepp 'zs/^\\s*↢\\s*$/↢/e",
    \ ]}]

" did_ftplugin {{{2

" We don't want other ftplugins to be sourced.
" The less code, the faster we can reload our notes.
let b:did_ftplugin = 1
" }}}1
" Teardown {{{1

let b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    \ ..'| call markdown#undo_ftplugin()'

