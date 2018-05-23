if exists('b:current_syntax')
    finish
endif

" TODO:
" The following is stolen from tpope's vim-markdown
" Study how it works.

" TODO:
" read and take inspiration from:
"         https://github.com/vim-pandoc/vim-pandoc-syntax
"         http://pandoc.org/MANUAL.html#pandocs-markdown
"
" TODO:
" Learn how to conceal a url:
"
"     [some_text](some_url)
"     →
"     some_text
"
" Update:
" Add the argument:
"
"     • `conceal`     to `syn region markdownLink`     (to hide the url)
"     • `concealends` to `syn region markdownLinkText` (to hide [] surrounding
"                                                       the text describing the url)
"
" Also, if you  want the link to be  concealed even in a block of  code, in `syn
" region markdownCodeBlock`,  tweak the  argument `contains`  so that  its value
" includes `markdownLink` and `markdownLinkText`:
"
"         contains=@Spell,markdownLink,markdownLinkText
"
" Atm,  I  don't  do  it  because  it would  wrongly  conceal  any  text  inside
" parentheses in a block of code.
" Maybe we need to tweak the definition of `markdownLink` so that it checks that
" there is a description of the link just before:  [description](link).
"                                                   ^^^^^^^^^^^
"                                                   if there's NOT a description
"                                                   don't conceal the link


" TODO:
" We've disabled html filetype plugins.
" Should we do the same for html syntax plugins?
ru! syntax/html.vim syntax/html_*.vim syntax/html/*.vim
unlet! b:current_syntax

call markdown#define_fenced_cluster()

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
syn match markdown_hide_VimL_separations '^\s*"$' conceal containedin=markdownCodeBlock

syn match markdownValid '[<>]\c[a-z/$!]\@!'
syn match markdownValid '&\%(#\=\w*;\)\@!'

syn match markdownLineStart "^[<@]\@!" nextgroup=@markdownBlock,htmlSpecialChar

" FIXME:
" Why does this line need to be after the `markdownLineStart` item?
syn region markdown_hide_answers start='^↣' end='^↢.*' conceal cchar=? containedin=markdownCodeBlock
syn match markdown_hide_answers '↣.\{-}↢' conceal cchar=? containedin=markdownCodeBlock

syn cluster markdownBlock contains=markdownH1,markdownH2,markdownH3,markdownH4,markdownH5,markdownH6,markdownBlockquote,markdownListMarker,markdownOrderedListMarker,markdownCodeBlock,markdownRule
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
syn match markdownBlockquote "^>\+\%(\s.*\|$\)" contained contains=markdownBold,markdownItalic nextgroup=@markdownBlock keepend
" TODO: explain why we need `keepend`.
" Hint:
" In ~/Dropbox/wiki/vim/compiler.md, there's a question whose title is:
"
"         What's the “module” name of an entry?
"
" In the answer, we quote some text.
" Inside the quote, there's an underscore in an url.
" Because of it, Vim applies an italic style.
" Without `keepend`, the latter would be applied beyond the quote.
" We would have the same issue (with  the bold style) if, for some reason, there
" were two (unclosed) asterisks in the quote.

syn region markdownCodeBlock start="    \|\t" end="$" contained contains=@Spell
"                                                                         │
" When we enable 'spell', errors aren't highlighted inside a code block.  ┘
" So we add the @Spell cluster. See `:h spell-syntax`

" TODO: real nesting
syn match markdownListMarker "\%(\t\| \{0,4\}\)[-*+]\%(\s\+\S\)\@=" contained
syn match markdownOrderedListMarker "\%(\t\| \{0,4}\)\<\d\+\.\%(\s\+\S\)\@=" contained

syn match markdownRule "\* *\* *\*[ *]*$" contained
syn match markdownRule "- *- *-[ -]*$" contained

syn match markdownLineBreak " \{2,\}$"

syn region markdownIdDeclaration matchgroup=markdownLinkDelimiter start="^ \{0,3\}!\=\[" end="\]:" oneline keepend nextgroup=markdownUrl skipwhite
syn match markdownUrl "\S\+" nextgroup=markdownUrlTitle skipwhite contained
syn region markdownUrl matchgroup=markdownUrlDelimiter start="<" end=">" oneline keepend nextgroup=markdownUrlTitle skipwhite contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+"+ end=+"+ keepend contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+'+ end=+'+ keepend contained
syn region markdownUrlTitle matchgroup=markdownUrlTitleDelimiter start=+(+ end=+)+ keepend contained

" `concealends` is custom (not in original plugin).
syn region markdownLinkText matchgroup=markdownLinkTextDelimiter start="!\=\[\%(\_[^]]*]\%( \=[[(]\)\)\@=" end="\]\%( \=[[(]\)\@=" nextgroup=markdownLink,markdownId skipwhite contains=@markdownInline,markdownLineStart concealends
" `conceal` is custom (not in original plugin).
syn region markdownLink matchgroup=markdownLinkDelimiter start="(" end=")" contains=markdownUrl keepend contained conceal
syn region markdownId matchgroup=markdownIdDelimiter start="\[" end="\]" keepend contained
syn region markdownAutomaticLink matchgroup=markdownUrlDelimiter start="<\%(\w\+:\|[[:alnum:]_+-]\+@\)\@=" end=">" keepend oneline

syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=\*\|\*\S\@=" end="\S\@<=\*\|\*\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=_\|_\S\@=" end="\S\@<=_\|_\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=\*\*\|\*\*\S\@=" end="\S\@<=\*\*\|\*\*\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell concealends
syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=__\|__\S\@=" end="\S\@<=__\|__\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell concealends
syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=\*\*\*\|\*\*\*\S\@=" end="\S\@<=\*\*\*\|\*\*\*\S\@=" keepend contains=markdownLineStart,@Spell concealends
syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=___\|___\S\@=" end="\S\@<=___\|___\S\@=" keepend contains=markdownLineStart,@Spell concealends

syn region markdownCode matchgroup=markdownCodeDelimiter start="`" end="`" keepend contains=markdownLineStart
syn region markdownCode matchgroup=markdownCodeDelimiter start="`` \=" end=" \=``" keepend contains=markdownLineStart
syn region markdownCode matchgroup=markdownCodeDelimiter start="^\s*````*.*$" end="^\s*````*\ze\s*$" keepend
" Why?{{{
"
" It allows us to conceal backticks when they are followed by quotes:
"
"       `'option'`    →     'option'
"
" It reduces noise.
"}}}
syn region markdownBacktickThenQuotes matchgroup=Comment start=/`\ze['"]\S\+['"]`/ end=/['"]\S\+['"]\zs`/ oneline concealends containedin=markdownCode,markdownCodeDelimiter

syn match markdownFootnote "\[^[^\]]\+\]"
syn match markdownFootnoteDefinition "^\[^[^\]]\+\]:"

call markdown#highlight_fenced_languages()

syn match markdownEscape "\\[][\\`*_{}()<>#+.!-]"
syn match markdownError "\w\@<=_\w\@="

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
hi link markdownOrderedListMarker     markdownListMarker
hi link markdownListMarker            Statement
hi link markdownBlockquote            Comment
hi link markdownRule                  PreProc

hi link markdownFootnote              Typedef
hi link markdownFootnoteDefinition    Typedef

" TODO:
" Originally, it was linked to `Underlined`, but in my current colorscheme,
" it's pink and underlined: too noisy.
" Create your own  HG for links, because I'm not  sure `Conditional` will always
" be a good choice if you change your colorscheme.
hi link markdownLinkText              Conditional
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
hi link markdownError                     Normal
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

let b:current_syntax = 'markdown'
