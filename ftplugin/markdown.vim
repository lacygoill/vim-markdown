vim9script

if exists('b:did_ftplugin')
    finish
endif

# Would it make sense to also source html filetype plugins?{{{
#
# Yes, because html tags can be used in Markdown:
# https://daringfireball.net/projects/markdown/syntax#html
#
# Besides, that's what tpope does in his markdown plugin.
#}}}
# How could I source them?{{{
#
# You would need to consider the 3 possible naming schemes:
#
#     ru! ftplugin/html.vim ftplugin/html_*.vim ftplugin/html/*.vim
#       │
#       └ all of them
#         (even if there are several ftplugin/html.vim in various directories of &rtp)
#}}}
# Why don't you source them?{{{
#
# We have some html settings which are undesirable in markdown.
#
# Examples:
# We set `'sw'` to 2 in an html  file (as per google style guide), but we prefer
# to set it to 4 in a markdown file.
#
# In  our HTML  plugin  (`~/.vim/after/ftplugin/html.vim`), we  set  up the  web
# browser to look for the word under the cursor when we press `K`.
# But, in a markdown buffer, we prefer a more granular approach.
# Sometimes, `:Man`,  sometimes `:help`,  and maybe other  values in  the future
# depending on the location of the file.
#}}}

# TODO: Read this: http://www.oliversherouse.com/2017/08/21/vim_zero.html
#
# And this: https://www.romanzolotarev.com/jekyll/
#
# Jekyll is a program which could convert our markdown notes into webpages.
# We could read the latter in firefox.

# TODO: Study this plugin:
#
# https://github.com/vim-pandoc/vim-rmarkdown
# https://rmarkdown.rstudio.com/lesson-1.html
# https://rmarkdown.rstudio.com/authoring_pandoc_markdown.html#philosophy
#
# And maybe these ones:
#
# https://github.com/jalvesaq/Nvim-R
# https://github.com/gaalcaras/ncm-R
# https://github.com/SidOfc/mkdx
#
# You may need to read these 2 books:
#
# https://www.amazon.com/Dynamic-Documents-knitr-Second-Chapman/dp/1498716962/
# https://www.amazon.com/Data-Science-Transform-Visualize-Model/dp/1491910399/
#
# We've already downloaded them.
#
# Also read this:
# https://medium.freecodecamp.org/turning-vim-into-an-r-ide-cd9602e8c217

# Commands {{{1

com -bar -buffer -nargs=1 -range=% -complete=custom,markdown#check#punctuationComplete
    \ CheckPunctuation echo markdown#check#punctuation(<q-args>, <line1>, <line2>)
    #                  │{{{
    #                  └ useful to erase the command from the command-line after its execution
    #}}}

com -bar -buffer -nargs=? -range=% -complete=custom,markdown#commitHash2link#completion
    \ CommitHash2Link markdown#commitHash2link#main(<line1>, <line2>, <q-args>)

# Warning: Don't call this command `:Fix`.  It wouldn't work as expected with `:argdo`.
com -bar -buffer FixFormatting markdown#fixFormatting()

com -bar -buffer -range=% FoldSortBySize markdown#fold#sort#bySize(<line1>, <line2>)

# Purpose: Convert inline link:{{{
#
#     [text](url)
#
# ...  to reference link:
#
#     [text][ref]
#     ...
#     # Reference
#     [ref]: link
#}}}
com -bar -buffer -range=% LinkInline2Ref markdown#linkInline2ref#main()

com -bar -buffer Preview markdown#preview#main()

# Mappings {{{1

nno <buffer><nowait> cof <cmd>call markdown#fold#foldexpr#toggle()<cr>
# Increase/decrease  'fdl' when folds are nested.{{{
#
# Use it to quickly see the titles up to an arbitrary depth.
# Useful  to get  an overview  of  the contents  of  the notes  of an  arbitrary
# precision.
#}}}
nno <buffer><nowait> [of <cmd>call markdown#fold#option#fdl('less')<cr>
nno <buffer><nowait> ]of <cmd>call markdown#fold#option#fdl('more')<cr>
sil! repmap#make#repeatable({
    mode: 'n',
    buffer: true,
    from: expand('<sfile>:p') .. ':' .. expand('<slnum>'),
    motions: [
        {bwd: '[of', fwd: ']of'},
    ]})

nno <buffer><nowait> gd <cmd>call markdown#getDefinition#main()<cr>
xno <buffer><nowait> gd <cmd>call markdown#getDefinition#main('vis')<cr>
nno <buffer><nowait> gl <cmd>call markdown#fold#howMany#print()<cr>

nno <buffer><nowait> +[# <cmd>call markdown#fold#put#main(v:false)<cr>
nno <buffer><nowait> +]# <cmd>call markdown#fold#put#main()<cr>

nno <buffer><expr><nowait> =rb sh#breakLongCmd()
nno <buffer><expr><nowait> =r- markdown#hyphens2hashes()
nno <buffer><expr><nowait> =r-- markdown#hyphens2hashes() .. '_'
xno <buffer><expr><nowait> =r- markdown#hyphens2hashes()

xno <buffer><expr><nowait> H markdown#fold#promote#setup('less')
xno <buffer><expr><nowait> L markdown#fold#promote#setup('more')

# Options {{{1
var afile: string = expand('<afile>:p')
# ai {{{2

# There's no indent plugin in `$VIMRUNTIME/indent/`, so we use `'autoindent'` as
# a poor-man's solution.
setl ai

# cms {{{2

# template for a comment (taken from html);  will be used by `gc` (could also be
# used by `zf` &friends, if `&l:fdm = 'manual'`)
setl cms=>\ %s

# comments {{{2

#        ┌ Only the first line has the comment leader.{{{
#        │ Do not repeat comment on the next line, but preserve indentation:
#        │ useful for bullet-list.
#        │
#        │┌ Blank (Space, Tab or EOL) required after the comment leader.
#        ││ So here, '- hello' would be recognized as a comment, but not '-hello'.
#        ││
#        ││┌ Nested comment.
#        │││ Nesting with mixed parts is allowed.
#        │││ Ex: if 'comments' is "n:*,n:-", a line starting with "* -" is a comment.
#        │││                                                       ├─┘
#        │││                                                       └ mixed
#        │││}}}
setl com=fbn:-,fb:*,fb:+

# What's the purpose of 'com'? {{{
#
# 'comments' contains a list of strings which can start a commented line.
# Vim needs to know what the comment leader is in various occasions:
#
#    - if 'fo' contains the flag `r`, and we open a new line, hitting CR
#      from insert mode, Vim needs to know what to prepend at the
#      beginning
#
#      same thing if 'fo' contains the flag `o`, and we open a new line,
#      hitting o O from normal mode
#
#    - if 'fo' contains the flag `c`, Vim automatically wraps a long
#      commented line; when it breaks the current line, and open a new
#      one, it must know what to prepend at the beginning
#
#    - when we format a comment with the `gw` operator, Vim needs to know
#      what the comment leader is, to be able to remove / add it when it
#      joins / splits lines

# We aren't limited to single-line comments.
# We can make Vim recognize multi-line ones too.
# Doing so lets us format them with `gw`.
#}}}
# Don't confuse 'com' with 'cms'.{{{
#
# `'cms'` is just a template used by  folding commands (ex: `zf`) when they have
# to (un)comment a  marker which they need to add/remove  on the starting/ending
# line of a fold.
# We often use it to infer what a comment looks like, because it's easier than
# parsing 'com', but that's it.
#
#             ┌ %s is replaced by "{{_{ and "}}_}  at the end of resp.
#             │ the starting line of the fold and the ending line of the fold
#             ├──────────┐
#     "%s  →  "{{_{  "}}_}
#     ├─┘
#     └ template
#}}}
# What's the meaning of the 'f' flag? {{{

# Here's a long line:
#
#     - some very long comment some very long comment some very long comment some very long comment

# If we type this line in a markdown buffer, or if it has already been typed and
# we press `gwip`:
#
# Without the `f` flag and with `&l:tw = 80`, we get:
#
#     - some very long comment some very long comment some very long comment some
#     - very long comment
#
# With the `f` flag and `&l:tw = 80`, we get:
#
#     - some very long comment some very long comment some very long comment some
#       very long comment
#
# This shows  why `f` is important  for a comment  leader used as a  bullet list
# marker.  The  meaning of a  comment leader depends  on the context  where it's
# used.  It means that all the text between it and the next comment leader:
#
#    - is commented in a regular paragraph
#    - belongs to a same item in a bullet list
#
# So, you  can break/join the  lines of a  regular paragraph, however  you like,
# without changing its meaning.  But you can't do the same for a bullet list.
#
# Technically, if `f` is absent, Vim will add a marker every time it has to
# break down a line, which is wrong in a bullet list.
# }}}
# What's the meaning of the 'n' flag? {{{
#
# It's useful to let  Vim know that 2 comment leaders  can be nested.  Otherwise
# `gw` won't set the proper indentation level for all the lines.
#
# MWE:
#
#     * - some very long comment some very long comment some very long comment some very long comment
#
# Without `n`:
#
#       ┌ interpreted as a part of the comment
#       │
#     * - some very long comment some very long comment some very long comment some
#       very long comment
#
# With `n`:
#
#       ┌ recognized as a (nested) comment leader
#       │
#     * - some very long comment some very long comment some very long comment
#         some very long comment
#
# }}}

# compiler {{{2

try
    compiler pandoc
catch /^Vim\%((\a\+)\)\=:E666:/
endtry

# folding + conceal {{{2

# Do  *not*  remove this  function  call;  see  our  comment in  `Fold()`  (from
# `lg/styledComment.vim`) for an explanation.
markdown#window#settings()

augroup MarkdownWindowSettings
    au! * <buffer>
    # Why `#compute()`?{{{
    #
    # `vim-fold`  automatically  resets the  value  of  `'fde'` from  `expr`  to
    # `manual`, because the latter is less costly.
    # But  it does  so only  on `FileType`;  the next  `BufWinEnter` will  reset
    # `'fde'` again from `manual` to `expr`.
    #
    # So, we need to reset `'fde'` *again*:
    #
    #     expr → manual → expr → manual
    #     │      │        │      │
    #     │      │        │      └ our ftplugin via #compute() on BufWinEnter <buffer>
    #     │      │        └ our ftplugin on BufWinEnter <buffer>
    #     │      └ vim-fold on FileType *
    #     └ our ftplugin on FileType markdown
    #}}}
    au BufWinEnter,FileChangedShellPost <buffer> markdown#window#settings()
        | sil! fold#lazy#compute(false)
augroup END

# fp  tw {{{2

setl tw=80

# We want `gq` to use par in a markdown buffer.
&l:fp = 'par -w' .. &l:tw .. 'rjeq'

# inex {{{2

if afile =~ '/wiki/'
    setlocal includeexpr=markdown#note2code()
endif

# kp {{{2

if afile =~ '/wiki/vim/'
    setl kp=:help
else
    setl kp=:Man
endif

# spl {{{2

setl spl=en

# wrap {{{2

# It's nice to have when we're reading the wiki of a github project.
setl wrap
# }}}1
# Variables {{{1
# cr_command {{{2

# When we hit `CR`, we want the cursor to move on the 100th column.
# By default, it moves on the 80th column.

const b:cr_command = 'norm! 100|'

# exchange_indent {{{2

# We've set up `vim-exchange` to re-indent linewise exchanges with `==`.
# But we don't want that for markdown buffers.
# For more info: `:h g:exchange_indent`.

const b:exchange_indent = ''

# markdown_highlight {{{2

# We want  syntax highlighting  in fenced  blocks, but  only for  certain files,
# because  the more  you  add syntax  plugins,  the  more it  has  an impact  on
# performance.

if search('^```\S\+', 'n') > 0
    const b:markdown_highlight = getline(1, '$')
        ->filter((_, v: string): bool => v =~ '^```\S\+')
        ->sort()
        ->uniq()
        ->map((_, v: string): string => v->matchstr('```\zs[a-z]\+'))
endif

# mc_chain {{{2

# Do not include the `tags` method here.{{{
#
# Right now, the tags generated by `ctags(1)` are the title of the fold markers.
# Those are too long.  With those kind of tags, the tags method looks a bit like
# the line method (C-x C-l); too  disruptive, because once the method complete a
# long text, you can no longer cycle to the next or previous method.
#}}}
b:mc_chain =<< trim END
    file
    keyn
    ulti
    abbr
    c-n
    dict
END

# sandwich_recipes {{{2

# Let us conceal the answer to a question by pressing `sa {text-object} c`.
b:sandwich_recipes = get(g:, 'sandwich#recipes', get(g:, 'sandwich#default_recipes', []))->deepcopy()
    + [{
        buns: ['↣ ', ' ↢'],
        input: ['c'],
        command: [
            "']mark z",
            "keepj keepp '[s/^\\s*↣\\s*$/↣/e",
            "keepj keepp 'zs/^\\s*↢\\s*$/↢/e",
    ]}]

# did_ftplugin {{{2

# We don't want other ftplugins to be sourced.
# The less code, the faster we can reload our notes.
b:did_ftplugin = 1
# }}}1
# Teardown {{{1

b:undo_ftplugin = get(b:, 'undo_ftplugin', 'exe')
    .. '| call markdown#undoFtplugin()'

