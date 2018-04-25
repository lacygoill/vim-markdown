" TODO:
" The following is stolen from tpope's vim-markdown
" Study how it works.
"
" # Vim Markdown runtime files

" This is the development version of Vim's included syntax highlighting and
" filetype plugins for Markdown.  Generally you don't need to install these if
" you are running a recent version of Vim.

" One difference between this repository and the upstream files in Vim is that
" the former forces `*.md` as Markdown, while the latter detects it as Modula-2,
" with an exception for `README.md`.  If you'd like to force Markdown without
" installing from this repository, add the following to your vimrc:

"     autocmd BufNewFile,BufReadPost *.md set filetype=markdown

" If you want to enable fenced code block syntax highlighting in your markdown
" documents you can enable it in your `.vimrc` like so:

"     let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']

" To disable markdown syntax concealing add the following to your vimrc:

"     let g:markdown_syntax_conceal = 0

" Syntax highlight is synchronized in 50 lines. It may cause collapsed
" highlighting at large fenced code block.
" In the case, please set larger value in your vimrc:

"     let g:markdown_minlines = 100

" Note that setting too large value may cause bad performance on highlighting.

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


if !exists('main_syntax')
  let main_syntax = 'markdown'
endif

runtime! syntax/html.vim
unlet! b:current_syntax

" If you want to enable fenced code block syntax highlighting in your markdown
" documents you can enable it in your .vimrc like so:
"
"         let g:markdown_fenced_languages = ['html', 'python', 'bash=sh']
"                                                               └─────┤
" FIXME:                                                              └ what does this mean?

if !exists('g:markdown_fenced_languages')
  let g:markdown_fenced_languages = []
endif
let s:done_include = {}
for s:type in map(copy(g:markdown_fenced_languages), { i,v -> matchstr(v, '[^=]*$') })
  if has_key(s:done_include, matchstr(s:type,'[^.]*'))
    continue
  endif
  if s:type =~ '\.'
    let b:{matchstr(s:type,'[^.]*')}_subtype = matchstr(s:type,'\.\zs.*')
  endif
  exe 'syn include @markdownHighlight'.substitute(s:type,'\.','','g').' syntax/'.matchstr(s:type,'[^.]*').'.vim'
  unlet! b:current_syntax
  let s:done_include[matchstr(s:type,'[^.]*')] = 1
endfor
unlet! s:type
unlet! s:done_include

" Syntax highlight is synchronized in 50 lines. It may cause collapsed
" highlighting at large fenced code block. In this case, set a larger value
" in your vimrc.
if !exists('g:markdown_minlines')
  let g:markdown_minlines = 50
endif
execute 'syn sync minlines=' . g:markdown_minlines
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
syn match markdownBlockquote ">\%(\s\|$\)" contained nextgroup=@markdownBlock

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

" To disable markdown syntax concealing add the following to your vimrc:
"         let g:markdown_syntax_conceal = 0

let s:concealends = ''
if has('conceal') && get(g:, 'markdown_syntax_conceal', 1) ==# 1
  let s:concealends = ' concealends'
endif
exe 'syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=\*\|\*\S\@=" end="\S\@<=\*\|\*\S\@=" keepend contains=markdownLineStart,@Spell' . s:concealends
exe 'syn region markdownItalic matchgroup=markdownItalicDelimiter start="\S\@<=_\|_\S\@=" end="\S\@<=_\|_\S\@=" keepend contains=markdownLineStart,@Spell' . s:concealends
exe 'syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=\*\*\|\*\*\S\@=" end="\S\@<=\*\*\|\*\*\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell' . s:concealends
exe 'syn region markdownBold matchgroup=markdownBoldDelimiter start="\S\@<=__\|__\S\@=" end="\S\@<=__\|__\S\@=" keepend contains=markdownLineStart,markdownItalic,@Spell' . s:concealends
exe 'syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=\*\*\*\|\*\*\*\S\@=" end="\S\@<=\*\*\*\|\*\*\*\S\@=" keepend contains=markdownLineStart,@Spell' . s:concealends
exe 'syn region markdownBoldItalic matchgroup=markdownBoldItalicDelimiter start="\S\@<=___\|___\S\@=" end="\S\@<=___\|___\S\@=" keepend contains=markdownLineStart,@Spell' . s:concealends

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

if main_syntax is# 'markdown'
  let s:done_include = {}
  for s:type in g:markdown_fenced_languages
    if has_key(s:done_include, matchstr(s:type,'[^.]*'))
      continue
    endif
    exe 'syn region markdownHighlight'.substitute(matchstr(s:type,'[^=]*$'),'\..*','','').' matchgroup=markdownCodeDelimiter start="^\s*````*\s*'.matchstr(s:type,'[^=]*').'\S\@!.*$" end="^\s*````*\ze\s*$" keepend contains=@markdownHighlight'.substitute(matchstr(s:type,'[^=]*$'),'\.','','g')
    let s:done_include[matchstr(s:type,'[^.]*')] = 1
  endfor
  unlet! s:type
  unlet! s:done_include
endif

syn match markdownEscape "\\[][\\`*_{}()<>#+.!-]"
syn match markdownError "\w\@<=_\w\@="

hi def link markdownH1                    Title
hi def link markdownH2                    Title
hi def link markdownH3                    Title
hi def link markdownH4                    Title
hi def link markdownH5                    Title
hi def link markdownH6                    Title
hi def link markdownHeadingRule           markdownRule
hi def link markdownH1Delimiter           markdownHeadingDelimiter
hi def link markdownH2Delimiter           markdownHeadingDelimiter
hi def link markdownH3Delimiter           markdownHeadingDelimiter
hi def link markdownH4Delimiter           markdownHeadingDelimiter
hi def link markdownH5Delimiter           markdownHeadingDelimiter
hi def link markdownH6Delimiter           markdownHeadingDelimiter
hi def link markdownHeadingDelimiter      Delimiter
hi def link markdownOrderedListMarker     markdownListMarker
hi def link markdownListMarker            Statement
hi def link markdownBlockquote            Comment
hi def link markdownRule                  PreProc

hi def link markdownFootnote              Typedef
hi def link markdownFootnoteDefinition    Typedef

" TODO:
" Originally, it was linked to `Underlined`, but in my current colorscheme,
" it's pink and underlined: too noisy.
" Create your own  HG for links, because I'm not  sure `Conditional` will always
" be a good choice if you change your colorscheme.
hi def link markdownLinkText              Conditional
hi def link markdownIdDeclaration         Typedef
hi def link markdownId                    Type
hi def link markdownAutomaticLink         markdownUrl
hi def link markdownUrl                   Float
hi def link markdownUrlTitle              String
hi def link markdownIdDelimiter           markdownLinkDelimiter
hi def link markdownUrlDelimiter          Function
hi def link markdownUrlTitleDelimiter     Delimiter

hi def link markdownItalic                htmlItalic
hi def link markdownItalicDelimiter       markdownItalic
hi def link markdownBold                  htmlBold
hi def link markdownBoldDelimiter         markdownBold
hi def link markdownBoldItalic            htmlBoldItalic
hi def link markdownBoldItalicDelimiter   markdownBoldItalic
hi def link markdownCodeDelimiter         Delimiter

hi def link markdownEscape                Special
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
if main_syntax is# 'markdown'
  unlet main_syntax
endif
