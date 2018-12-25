if exists('b:current_syntax')
    finish
endif

" TODO:
" Read:
"     https://daringfireball.net/projects/markdown/syntax
"     https://daringfireball.net/projects/markdown/basics
"
" `markdown` provides some  useful syntax which our syntax  plugin don't emulate
" yet.
"
" Like the fact that a list item can include a blockquote or a code block.  Make
" some tests on github, stackexchange, reddit,  and with `:Preview`, to see what
" the current syntax is (markdown has evolved I guess...).
"
" And try to emulate every interesting syntax you find.

" TODO:
" read and take inspiration from:
"         https://github.com/vim-pandoc/vim-pandoc-syntax
"         http://pandoc.org/MANUAL.html#pandocs-markdown
"         https://github.com/junegunn/vim-journal/blob/master/syntax/journal.vim

" Why do you enable html syntax plugins?{{{
"
" We use some of their HGs and syntax groups, in our markdown syntax plugin.
" Namely:
"
"     • syntax group: htmlSpecialChar
"     • syntax cluster: @htmlTop
"     • HG: htmlItalic
"     • HG: htmlBold
"     • HG: htmlBoldItalic
"
" That's what the original plugin does:
"
"     $VIMRUNTIME/syntax/markdown.vim
"}}}
" Is `syntax/html_*.vim` a valid file pattern for an html syntax plugin?{{{
"
" No.
"
" Vim doesn't use it when we do `:set syn=foobar`:
"
"     :2Verbose set syn=foo
"         → Searching for "syntax/foo.vim syntax/foo/*.vim" in ...
"           not found in 'runtimepath': "syntax/foobar.vim syntax/foobar/*.vim"
"}}}
runtime! syntax/html.vim syntax/html/*.vim
unlet! b:current_syntax

" Syntax highlight is synchronized in 50 lines.
" It may cause collapsed highlighting at large fenced code block.
" In this case, set a larger value.
" Note that setting a too large value may cause bad performance on highlighting.
syn sync minlines=50
syn case ignore

" Why?{{{
"
" Sometimes we need to separate some blocks of VimL code in our notes.
" But we still want to be able to source them with a simple `+sip`.
" So we separate them with empty commented lines.
"}}}
syn match markdownHideVimlSeparations '^\s*"$' conceal containedin=markdownCodeBlock

" TODO: Explain why `markdownValid` is necessary?{{{
"
" To understand, insert this at the beginning of a line:
"
"     <'abc
"
" Also read this: https://github.com/tpope/vim-markdown/pull/31
"}}}
syn match markdownValid '[<>]\c[a-z/$!]\@!'
syn match markdownValid '&\%(#\=\w*;\)\@!'

syn match markdownLineStart "^[<@]\@!" nextgroup=@markdownBlock,htmlSpecialChar

" TODO: How to include italics inside a hidden answer?{{{
" We could add `contains=markdownItalic`.
" But the text in italics would not be concealed...
" We probably have the same issue with other styles (bold, ...).
"}}}
" TODO: Instead of inventing a weird ad-hoc system, you should rely on some existing html tags:{{{
"
"     <details><summary>
"     question</summary>
"     hidden answer</details>
"
" Update:
" Here's some code implementing the idea:
"
"     syn match markdownHideAnswer '<details>\n\=<summary>' conceal containedin=markdownCodeBlock
"     syn region markdownShowAnswer matchgroup=Ignore start='</summary>' end='</details>' conceal containedin=markdownCodeBlock
"     hi link markdownHideAnswer Ignore
"     hi link markdownShowAnswer PreProc
"
" However, sometimes, it's too cumbersome to use to hide inline answers.
" Have a look at the answers we hide in:
"
"     ~/Dropbox/wiki/vim/command.md
"     ~/Dropbox/wiki/vim/exception.md
"
" Maybe we  should keep our  ad-hoc system to hide  inline answers, and  use the
" html tags to hide blocks of lines...
"}}}
syn region markdownHideAnswer start='^↣' end='^↢.*' conceal cchar=? containedin=markdownCodeBlock keepend
syn match markdownHideAnswer '↣.\{-}↢' conceal cchar=? containedin=markdownCodeBlock

syn cluster markdownBlock contains=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6,markdownBlockquote,markdownList,markdownOrderedListMarker,markdownCodeBlock,markdownRule
syn cluster markdownInline contains=markdownLineBreak,markdownLinkText,markdownItalic,markdownBold,markdownCode,markdownEscape,@htmlTop,markdownError

syn match markdownH1 "^.\+\n=\+$" contained contains=@markdownInline,markdownHeadingRule,markdownAutomaticLink
syn match markdownH2 "^.\+\n-\+$" contained contains=@markdownInline,markdownHeadingRule,markdownAutomaticLink

syn match markdownHeadingRule "^[=-]\+$" contained

syn region markdownH1 matchgroup=markdownH1Delimiter start="##\@!"      end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained
syn region markdownH2 matchgroup=markdownH2Delimiter start="###\@!"     end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained
syn region markdownH3 matchgroup=markdownH3Delimiter start="####\@!"    end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained
syn region markdownH4 matchgroup=markdownH4Delimiter start="#####\@!"   end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained
syn region markdownH5 matchgroup=markdownH5Delimiter start="######\@!"  end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained
syn region markdownH6 matchgroup=markdownH6Delimiter start="#######\@!" end="#*\s*$" keepend oneline contains=@markdownInline,markdownAutomaticLink contained

" Why is `keepend` important here?{{{
"
" Suppose you emphasize some text in bold, while quoting a sentence.
" But you forget to add `**` at the end of the emphasized text.
" The `markdownBold` region will go on until the end of the quoted sentence.
"
" This is expected, and *not* avoidable.
"
" But, it will also consume the  end of `markdownBlockquote`, which will have to
" be extended, as well as `markdownBold`.
" As a  result, after your quoted  sentence, the following text  will be wrongly
" highlighted by the stack of items `markdownBold markdownBlockquote`.
" IOW, the text will be in bold, even *after* you've finished writing your quote.
"
" This is UNexpected, but *avoidable*.
" `keepend`  prevents a  possible broken  contained region  from being  extended
" outside the initial containing region.
"}}}
syn match markdownBlockquote "^>\+\%(\s.*\|$\)" contained contains=markdownBold,markdownCode,markdownItalic,markdownBlockquoteLeadingChar keepend nextgroup=@markdownBlock
syn match markdownBlockquoteLeadingChar "^>\+\s" contained conceal

" TODO:
" Comment on the fact that the  region must be contained because of `contained`,
" and yet, in practice, it doesn't seem to be contained in anything.
" Press `!s`  on a  codeblock, and  you won't  see a  containing item,  in which
" `markdownCodeBlock` would be contained.
" I think it's contained in the cluster `@markdownBlock`.
" Is it necessary for `markdownCodeBlock` to be contained?
" Or is it just because `@markdownBlock` is convenient...
" Once you  understand, have a  look at  what we did  for our comments  in other
" filetypes.
" Maybe we should use a cluster too...
syn region markdownCodeBlock start="    \|\t" end="$" contained contains=@Spell keepend
"                                                                         │{{{
" When we enable 'spell', errors aren't highlighted inside a code block.  ┘
" So we add the @Spell cluster. See `:h spell-syntax`
"}}}

" TODO: real nesting
" TODO: other styles should be included inside a list (bold, italic, bold+italic, codespan ...)
" Why did you add `•` in the collection `[-*+•]`?{{{
"
" It makes the bullets prettier, because they're highlighted.
" When we indent  a list with 4 spaces or  more, it prevents `markdownCodeBlock`
" to match, which in turn allows `markdownCode` to match.
"}}}
" TODO: We should remove `•`, and instead use `-` to format our lists.{{{
"
" `•` is not recognized as the beginning of a list item by the markdown spec.
"
" Also, this would give us the benefit of having our bulleted list recognized by a markdown viewer/parser.
"
"     syn match markdownListMarkerPretty "\%(\t\| \{0,4\}\)\@<=[-*+]\%(\s\+\S\)\@=" contained containedin=markdownList conceal cchar=•
"
" Also, when  we would read  a markdown file written  by someone else,  we would
" automatically see `•` instead of `-`.
" No need of reformatting.
"
" If we do this, we would need to conceal `-`, and replace it with `•`.
" And we would need to make `hl-Conceal` less visible:
"
"     hi! link Conceal Statement
"                      │
"                      └ HG used by markdownList
"
" And  we  would  need  to  refactor   `coc`  so  that  it  temporarily  resets
" `hl-Conceal` with its old attributes (more visible):
"
"     Conceal        xxx ctermfg=237 ctermbg=254 guifg=#4B4B4B guibg=#E9E9E9
"
" And we would need to refactor `vim-bullet-list`.
" And we would need to replace `•` with `-` everywhere:
"
"     noa vim /•/gj ~/.vim/**/*.{vim,md} ~/.vim/**/*.snippets ~/.vim/template/** ~/.vim/vimrc ~/Dropbox/wiki/**/*.md ~/.zsh/** ~/.config/** ~/.zshrc ~/.zshenv ~/.Xresources ~/.tmux.conf ... | cw
"
" Also,  should we  add the  same  kind of  conceal  in all  filetypes, but  for
" comments only?
"}}}
" FIXME: Originally, there were 2 items (ordered + unordered lists), and they used the quantifier `\{0,4\}`.{{{
"
" But it seems too much.
" Try to write a list indented with 4 spaces, and run `:Preview`.
" The list is formatted as a codeblock, instead of a list!
" So, why did tpope used 4 spaces, instead of 3?
" Also, it included a tab, which causes the same issue:
"
"     syn match markdownList "\%(\t\| \{0,3\}\)[-*+•]\%(\s\+\S\)\@=" contained
"}}}
" The regex can be broken down like this:{{{
"
" First Part:
"
"     ^ \{,3\}\%([-*+]\|\d\+\.\)\s\+\S\_.\{-}\n
"
" This describes the first line of a list item.
"
" Second Part:
"
"     \%( \{,3}[-*+]\| \{,3}\d\+\.\|\s*\n\S\| \{8}\|\%$\)\@=
"
" This describes when a list item should stop.
" It can be broken down further:
"
"     \%( \{,3}[-*+]\| \{,3}\d\+\.\|\s*\n\S\| \{8}\|\%$\)\@=
"        ├─────────┘  ├──────────┘  ├─────┘  ├───┘  ├─┘
"        │            │             │        │      └ the end of the buffer
"        │            │             │        │
"        │            │             │        └ a codeblock inside a list item
"        │            │             │
"        │            │             └ the beginning of a paragraph
"        │            └ the beginning of another ordered list item
"        └ the beginning of another unordered list item
"}}}
syn match markdownList "^ \{,3\}\%([-*+•]\|\d\+\.\)\s\+\S\_.\{-}\n\%( \{,3}[-*+•]\| \{,3}\d\+\.\|\s*\n\S\| \{8}\|\%$\)\@=" contained

syn match markdownRule "\* *\* *\*[ *]*$" contained
syn match markdownRule "- *- *-[ -]*$" contained

syn match markdownLineBreak " \{2,\}$"

syn region markdownIdDeclaration matchgroup=markdownLinkDelimiter start="^ \{0,3\}!\=\[" end="\]:" oneline keepend nextgroup=markdownUrl skipwhite
syn match markdownUrl "\S\+" nextgroup=markdownUrlTitle skipwhite contained
syn region markdownUrl matchgroup=markdownUrlDelimiter start="<" end=">" oneline keepend nextgroup=markdownUrlTitle skipwhite contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+"+ end=+"+ keepend contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+'+ end=+'+ keepend contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+(+ end=+)+ keepend contained

" We add the  `concealends` argument to hide the square  brackets [] surrounding
" the text describing the url.
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\_[^]]*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends keepend
" We add the `conceal` argument to hide the url of a link.
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
syn region markdownId matchgroup=markdownIdDelimiter start="\[" end="\]" keepend contained
syn region markdownAutomaticLink matchgroup=markdownUrlDelimiter start="<\%(\w\+:\|[[:alnum:]_+-]\+@\)\@=" end=">" keepend oneline

syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=\*\|\*\S\@=" end="\S\@<=\*\|\*\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=_\|_\S\@=" end="\S\@<=_\|_\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=\*\*\|\*\*\S\@=" end="\S\@<=\*\*\|\*\*\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell concealends
syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=__\|__\S\@=" end="\S\@<=__\|__\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell concealends
syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=\*\*\*\|\*\*\*\S\@=" end="\S\@<=\*\*\*\|\*\*\*\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=___\|___\S\@=" end="\S\@<=___\|___\S\@=" keepend contains=markdownLineStart,@Spell concealends

syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend contains=markdownLineStart concealends
syn region markdownCode matchgroup=markdownCodeDelimiter start="`` \=" end=" \=``" keepend contains=markdownLineStart
syn region markdownCode matchgroup=markdownCodeDelimiter start="^\s*````*.*$" end="^\s*````*\ze\s*$" keepend

syn match markdownFootnote "\[^[^\]]\+\]"
syn match markdownFootnoteDefinition "^\[^[^\]]\+\]:"

syn match markdownEscape "\\[][\\`*_{}()<>#+.!-]"
syn match markdownError "\w\@<=_\w\@="

syn match markdownPointer "^\s*[v^✘✔]\+$"

syn match markdownCommentTitle /^\s\{0,2}\u\w*\(\s\+\u\w*\)*:/ contains=markdownTodo
"                                  ├────┘
"                                  └ Why?
" Because:{{{
"
" We don't want  `markdownCommentTitle` to match in a codeblock,  nor in an item
" list.
" It would break the highlighting of the text which follows on the line.
" So, we can't allow more than 2 leading spaces.
"}}}
syn match markdownTodo  /\CTODO\|FIXME/ contained

" inspired from `helpHeader`
syn match markdownOutput /\s*\zs.\{-}\ze\s\=\~$/ contained containedin=markdownCodeBlock nextgroup=markdownIgnore
syn match markdownIgnore /.$/ contained containedin=markdownOutput conceal

syn match markdownTable /^\s\{4}[│─┌└├].*/

syn region markdownOption matchgroup=markdownCodeDelimiter start="`'" end="'`" concealends keepend oneline

call markdown#define_include_clusters()
call markdown#highlight_embedded_languages()

hi link markdownH1                    Title
hi link markdownH2                    Title
hi link markdownH3                    Title
hi link markdownH4                    Title
hi link markdownH5                    Title
hi link markdownH6                    Title
hi link markdownHeadingRule           markdownRule
hi link markdownH1Delimiter           markdownHeadingDelimiter
hi link markdownH2Delimiter           markdownHeadingDelimiter
hi link markdownH3Delimiter           markdownHeadingDelimiter
hi link markdownH4Delimiter           markdownHeadingDelimiter
hi link markdownH5Delimiter           markdownHeadingDelimiter
hi link markdownH6Delimiter           markdownHeadingDelimiter
hi link markdownHeadingDelimiter      Delimiter
" Originally, it was linked to `Statement`, but I find `Repeat` more readable.
hi link markdownList                  Repeat
hi link markdownBlockquote            CommentBlockQuote
hi link markdownRule                  Comment

hi link markdownFootnote              Typedef
hi link markdownFootnoteDefinition    Typedef

" TODO:
" We should  not link `markdownLinkText`  and `markdownUrl` to  `Underlined` and
" `Float`.
" We should link them to `CommentLinkText` and `CommentUrl`, and define
" the latter in:
"
"     ~/.vim/autoload/colorscheme.vim
"     /s:styled_comments(
"
" This way our global theme will be consistent.
" If we change the colors of links in the customizations of our colorscheme, the
" change will be reflected in our markdown notes.
hi link markdownLinkText              Underlined
"                                     │{{{
"                                     └ From `:h group-name`:
"
"                                         *Underlined text that stands out, HTML links
"}}}
hi link markdownIdDeclaration         Typedef
hi link markdownId                    Type
hi link markdownAutomaticLink         markdownUrl
hi link markdownUrl                   Float
hi link markdownUrlTitle              String
hi link markdownIdDelimiter           markdownLinkDelimiter
hi link markdownUrlDelimiter          Function
hi link markdownUrlTitleDelimiter     Delimiter

hi link markdownItalic                htmlItalic
hi link markdownItalicDelimiter       markdownItalic
hi link markdownBold                  htmlBold
hi link markdownBoldDelimiter         markdownBold
hi link markdownBoldItalic            htmlBoldItalic
hi link markdownBoldItalicDelimiter   markdownBoldItalic
hi link markdownCodeDelimiter         Delimiter

hi link markdownEscape                Special
"         foo_bar "{{{
"            ^
"            └ markdownError → red
"
" We don't want that. We could get rid of `markdownError`, but it doesn't work
" in a title, and it would cause other syntax rules to start an italic section
" on some `_` chars.
"
" We could also add a syntax group, linked to no HG:
"
"         syntax match markdownIgnore '\w_\w'
"
" But again, it doesn't work in titles.
"
" Solution:
" }}}
hi link markdownError                 Normal
" Source: {{{
"
"     http://stackoverflow.com/a/19137899
"
" FIXME:
"
" Also, read this:
"     https://github.com/tpope/vim-markdown/issues/85#issuecomment-149206804
"
" What is an inline code block? How to write one? `inline code block`
" Would this get rid of ugly red on underscores?
" If so, can we conceal the backticks?
" If yes, then link back `markdownError` to `Error`, and conceal backticks.
" If no, how to get rid of `markdownError` entirely, without any side-effect
" (italic)?
"}}}
hi link markdownCode                  CodeSpan
hi link markdownCodeBlock             Comment

hi link markdownPointer               Title
hi link markdownCommentTitle          PreProc
hi link markdownTodo Todo

hi link markdownOutput                PreProc
hi link markdownIgnore                Ignore
hi link markdownTable                 Structure

hi link markdownOption                Type

let b:current_syntax = 'markdown'

