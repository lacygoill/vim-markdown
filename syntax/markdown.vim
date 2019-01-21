if exists('b:current_syntax')
    finish
endif

" TODO: integrate most of the comments from this file in our notes

" TODO: support a url inside a quote (do the same for comments in other filetypes)
" Also, should we change the color of a codespan, and use sth less visible?
" Maybe `Constant`.

" TODO: look for this pattern:
"
"     \%( \\{\| \*\)
"
" Check whether sometimes  you should have allowed a tab  character, in addition
" to a space.
" Read official spec to be sure.
" Do the same thing for `~/.vim/plugged/vim-lg-lib/autoload/lg/styled_comment.vim`.

" TODO: When should we prefer `containedin` vs `contained`?
" Once you take a decision, apply your choice here and in:
"
"     ~/.vim/plugged/vim-lg-lib/autoload/lg/styled_comment.vim
"
" Update:
" We need `containedin`,  for example, to allow `xCommentTitle`  to be contained
" in `xComment`.
" TODO:
"
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

" Should I source the html syntax plugin?{{{
"
" The default markdown syntax plugin does it:
"
"     runtime! syntax/html.vim syntax/html/*.vim
"     unlet! b:current_syntax
"
" And it uses some of the html HGs and syntax groups:
"
"    • syntax group: htmlSpecialChar
"    • syntax cluster: @htmlTop
"    • HG: htmlItalic
"    • HG: htmlBold
"    • HG: htmlBoldItalic
"
" But I don't source it, because it  adds a lot of syntax groups, which probably
" has an impact on performance.
"
" It  also makes  the  code of  the  markdown syntax  plugin  more difficult  to
" understand.
"
" Finally, I don't care about html in a markdown file.
" I like markdown because it's easy to read.
" Html is not easy to read, hence goes against markdown philosophy.
" If I  really want  html syntax highlighting,  I can always  use a  fenced code
" block.
"}}}

" Syntax highlight is synchronized in 50 lines.
" It may cause collapsed highlighting at large fenced code block.
" In this case, set a larger value.
" Note that setting a too large value may cause bad performance on highlighting.
syn sync minlines=50
syn case ignore

exe 'syn cluster markdownSpanElements contains='
    \ . 'markdownLinkText,'
    \ . 'markdownItalic,'
    \ . 'markdownBold,'
    \ . 'markdownCodeSpan,'
    \ . 'markdownEscape,'
    \ . 'markdownError'

" Header {{{1

syn match markdownHeadingRule '^[=-]\+$' contained

exe 'syn region markdownHeader'
    \ . ' matchgroup=Delimiter'
    \ . ' start=/^#\{1,6}#\@!/'
    \ . ' end=/$/'
    \ . ' keepend'
    \ . ' oneline'
    \ . ' contains=@markdownSpanElements,markdownAutomaticLink'

exe 'syn match markdownHeader'
    \ . ' /^.\+\n=\+$/'
    \ . ' contains=@markdownSpanElements,markdownHeadingRule,markdownAutomaticLink'

exe 'syn match markdownHeader'
    \ . ' /^.\+\n-\+$/'
    \ . ' contains=@markdownSpanElements,markdownHeadingRule,markdownAutomaticLink'
" }}}1

" Don't change the order of `Italic`, `Bold` and `Bold+Italic`!{{{
"
" It would break the syntax highlighting of some style (italic, bold, bold+italic).
"}}}
"    Italic {{{1

" TODO: explain that  we need `oneline`, otherwise, there would  be issues for a
" list item whose leader is `*`.
" The alternative would probably consist of refining the regexes to tell Vim
" to look for a non-whitespace before or after `*`:
"
"     \S\@<=\*\|\*\S\@=
"
" I think that's what tpope does, and I think he does it for the same reason.
"
" Btw, should we use `oneline` whenever it's possible?

" Why don't you support the syntax using underscores?{{{
"
"    1. I don't use underscores
"    2. it has an impact on performance
"}}}
" I want to add support for it!{{{
"
" Duplicate each statement, replacing each escaped asterisk with an underscore.
"
" Or tweak the  existing regions to include the `\z()`  item and capture `[*_]`,
" `\*\*\|__`, `\*\*\*\|___` in  the start pattern, and refer to  it via `\z1` in
" the end pattern.
" Note that when I tried `\z()`, the time taken for `markdownItalic` was doubled.
" And for `markdownBold`, `markdownBoldItalic` the time was tripled.
" So, I don't think that `\z()` reduces the time taken to parse the syntax.
" It just makes the latter more concise/readable.
"
" ---
"
" Do the same for:
"
"    • `markdownListItemItalic`
"    • `markdownListItemBold`
"    • `markdownListItemBoldItalic`
"}}}
exe 'syn region markdownItalic'
    \ . ' matchgroup=markdownItalicDelimiter'
    \ . ' start=/\*/'
    \ . ' end=/\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contains=@Spell'
    \ . ' concealends'

" TODO: improve performance{{{
"
" Sometimes, moving in a buffer is slow, when there are many lists.
" We could try to eliminate `\@<=` and `@=` as frequently as possible.
"
" Btw:
" Shouldn't we use `_` instead of `*` to  avoid a conflict with `*` when used as
" an item leader.
"}}}
exe 'syn region markdownListItemItalic'
    \ . ' matchgroup=markdownItalicDelimiter'
    \ . ' start=/\*/'
    \ . ' end=/\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' contains=@Spell'
    \ . ' concealends'

exe 'syn region markdownBlockquoteItalic'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/\*/'
    \ . ' end=/\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' concealends'
" }}}1
"    Bold {{{1

exe 'syn region markdownBold'
    \ . ' matchgroup=markdownBoldDelimiter'
    \ . ' start=/\*\*/'
    \ . ' end=/\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contains=markdownItalic,@Spell'
    \ . ' concealends'

exe 'syn region markdownListItemBold'
    \ . ' matchgroup=markdownBoldDelimiter'
    \ . ' start=/\*\*/'
    \ . ' end=/\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' contains=markdownItalic,@Spell'
    \ . ' concealends'

" `markdownBlockquoteBold` must be defined *after* `markdownItalic`
exe 'syn region markdownBlockquoteBold'
    \ . ' matchgroup=markdownBoldDelimiter'
    \ . ' start=/\*\*/'
    \ . ' end=/\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' concealends'
" }}}1
"    Bold+Italic {{{1

exe 'syn region markdownBoldItalic'
    \ . ' matchgroup=markdownBoldItalicDelimiter'
    \ . ' start=/\*\*\*/'
    \ . ' end=/\*\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contains=@Spell'
    \ . ' concealends'

exe 'syn region markdownListItemBoldItalic'
    \ . ' matchgroup=markdownBoldItalicDelimiter'
    \ . ' start=/\*\*\*/'
    \ . ' end=/\*\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' contains=@Spell'
    \ . ' concealends'

exe 'syn region markdownBlockquoteBoldItalic'
    \ . ' matchgroup=markdownBoldItalicDelimiter'
    \ . ' start=/\*\*\*/'
    \ . ' end=/\*\*\*/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' contained'
    \ . ' contains=@Spell'
    \ . ' concealends'
" }}}1

" Codespan {{{1

" Why `oneline`?{{{
"
" Without it, if you insert a backtick, all the following text is highlighted.
" Even on the next lines.
" It can continue on a whole screen, until you insert the closing backtick.
" This is distracting.
"}}}
" If you change the name of `markdownCodeDelimiter`, update
" `./autoload/markdown.vim`
exe 'syn region markdownCodeSpan'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/`/'
    \ . ' end=/`/'
    \ . ' keepend'
    \ . ' containedin=markdownBold'
    \ . ' concealends'
    \ . ' oneline'

exe 'syn region markdownCodeSpan'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/`` \=/'
    \ . ' end=/ \=``/'
    \ . ' keepend'
    \ . ' containedin=markdownBold'
    \ . ' concealends'
    \ . ' oneline'

exe 'syn region markdownCodeSpan'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/^\s*````*.*$/'
    \ . ' end=/^\s*````*\ze\s*$/'
    \ . ' keepend'
    \ . ' oneline'

exe 'syn region markdownBlockquoteCodeSpan'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/`/'
    \ . ' end=/`/'
    \ . ' keepend'
    \ . ' contained'
    \ . ' concealends'

exe 'syn region markdownListItemCodeSpan'
    \ . ' matchgroup=markdownCodeDelimiter'
    \ . ' start=/`/'
    \ . ' end=/`/'
    \ . ' keepend'
    \ . ' contained'
    \ . ' concealends'
" }}}1

" Codeblock {{{1

" Why `contains=@Spell`?{{{
"
" When we enable 'spell', errors aren't highlighted inside a code block.
" So we add the @Spell cluster.
" See `:h spell-syntax`
"}}}
exe 'syn region markdownCodeBlock'
    \ . ' start=/^    \|^\t/'
    \ . ' end=/$/'
    \ . ' contains=@Spell'
    \ . ' keepend'

exe 'syn region markdownListItemCodeBlock'
    \ . ' start=/^        \|^\t\t/'
    \ . ' end=/$/'
    \ . ' contained'
    \ . ' contains=@Spell'
    \ . ' keepend'
" }}}1

" Blockquote {{{1

exe 'syn cluster markdownBlockquoteSpanElements contains='
    \ . 'markdownBlockquoteItalic,'
    \ . 'markdownBlockquoteBold,'
    \ . 'markdownBlockquoteBoldItalic,'
    \ . 'markdownBlockquoteCodeSpan'

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
exe 'syn match markdownBlockquote'
    \ . ' /^ \{,3}>\+\%(\s.*\|$\)/'
    \ . ' contains=@markdownBlockquoteSpanElements,markdownBlockquoteLeadingChar'
    \ . ' keepend'

exe 'syn match markdownBlockquoteLeadingChar'
    \ . ' /\%(^ \{,3}\)\@3<=>\+\s\=/'
    \ . ' contained'
    \ . ' conceal'

exe 'syn match markdownListItemBlockquote'
    \ . ' /^ \{4}>\+\%(\s.*\|$\)/'
    \ . ' contained'
    \ . ' contains=@markdownBlockquoteSpanElements,markdownListItemBlockquoteLeadingChar'
    \ . ' keepend'

exe 'syn match markdownListItemBlockquoteLeadingChar'
    \ . ' /\%(^ \{4}\)\@4<=>\+\s\=/'
    \ . ' contained'
    \ . ' conceal'
" }}}1

" Horizontal rule {{{1

" A horizontal rule must contain at least 3 asterisks or hyphens.
" They may be separated by whitespace.
syn match markdownRule '^\* *\* *\*[ *]*$'
syn match markdownRule '^- *- *-[ -]*$'
" }}}1

" List Item {{{1

exe 'syn cluster markdownListItemElements contains='
    \ . 'markdownListItemItalic,'
    \ . 'markdownListItemBold,'
    \ . 'markdownListItemBoldItalic,'
    \ . 'markdownListItemCodeSpan,'
    \ . 'markdownListItemCodeBlock,'
    \ . 'markdownListItemBlockquote,'
    \ . 'markdownListItemOutput'

" Why did you add `•` in the collection `[-*+•]`?{{{
"
" It makes the bullets prettier, because they're highlighted.
" When we indent  a list with 4 spaces or  more, it prevents `markdownCodeBlock`
" to match, which in turn allows `markdownCodeSpan` to match.
"}}}
" TODO: We should remove `•`, and instead use `-` to format our lists.{{{
"
" `•` is not recognized as the beginning of a list item by the markdown spec.
"
" Also, this would give us the benefit of having our bulleted list recognized by
" a markdown viewer/parser.
"
"     syn match markdownListItemMarkerPretty "\%(\t\| \{,4\}\)\@4<=[-*+]\%(\s\+\S\)\@=" contained containedin=markdownListItem conceal cchar=•
"
" Also, when  we would read  a markdown file written  by someone else,  we would
" automatically see `•` instead of `-`.
" No need of reformatting.
"
" If we do this, we would need to conceal `-`, and replace it with `•`.
" And we would need to make `hl-Conceal` less visible:
"
"     hi! link Conceal Repeat
"                      │
"                      └ HG used by markdownListItem
"
" And  we  would  need  to  refactor   `coc`  so  that  it  temporarily  resets
" `hl-Conceal` with its old attributes (more visible):
"
"     Conceal        xxx ctermfg=237 ctermbg=254 guifg=#4B4B4B guibg=#E9E9E9
"
" And we would need to refactor `vim-bullet-list`.
" And we would need to replace `•` with `-` everywhere:
"
"     noa vim /•/gj ~/.vim/**/*.{vim,md} ~/.vim/**/*.snippets ~/.vim/template/** ~/.vim/vimrc ~/wiki/**/*.md ~/.zsh/** ~/.config/** ~/.zshrc ~/.zshenv ~/.Xresources ~/.tmux.conf ... | cw
"
" Also,  should we  add the  same  kind of  conceal  in all  filetypes, but  for
" comments only?
"}}}
" Don't remove `keepend`!{{{
"
" Without, if  you forget to  write the closing backtick  of an italic  word, it
" could go on beyond the end of `markdownListItem`, which would cause the latter
" to be extended.
"
" In reality, it depends on whether you define `markdownItalic` with `oneline`.
" But the point is, we want a list to stop where we expect it to.
" We don't want a buggy contained item to make a list continue way beyond its end.
"}}}

" Why ` \{,3}` in the `start` pattern?{{{
"
" From: https://daringfireball.net/projects/markdown/syntax#list
"
" > List markers typically start  at the left margin, but may  be indented by up
" > to three spaces.
" }}}
" Why ` \{,3}` in the `end` pattern?{{{
"
" If  there are  4  spaces between  the  beginning  of the  line  and the  first
" non-whitespace, then we've found the first  line of a new paragraph inside the
" current list item.
"
" If there are 5,6,7 spaces, I guess it's the same thing.
"
" If there are  8 spaces, we've found  the first line of a  codeblock inside the
" current list item.
"
" In any case, more than 4 spaces means that we're still in the current list item.
" So, we need 3 spaces or less to end the latter.
"}}}
exe 'syn region markdownListItem'
    \ . ' start=/^ \{,3\}\%([-*+•]\|\d\+\.\)\s\+\S/'
    \ . ' end=/^\s*\n\%( \{,3}\S\)\@=/'
    \ . ' keepend'
    \ . ' contains=@markdownListItemElements'
" }}}1

" Output {{{1

" vaguely inspired from `helpHeader`
exe 'syn match markdownOutput'
    \ . ' /^.*\~$/'
    \ . ' contained'
    \ . ' containedin=markdownCodeBlock'
    \ . ' nextgroup=markdownIgnore'

exe 'syn match markdownIgnore'
    \ . ' /.$/'
    \ . ' contained'
    \ . ' containedin=markdownOutput'
    \ . ' conceal'

exe 'syn match markdownListItemOutput'
    \ . ' /^.*\~$/'
    \ . ' contained'
    \ . ' containedin=markdownListItemCodeBlock'
    \ . ' nextgroup=markdownListItemIgnore'

exe 'syn match markdownListItemIgnore'
    \ . ' /.$/'
    \ . ' contained'
    \ . ' containedin=markdownListItemOutput'
    \ . ' conceal'
" }}}1

" HideAnswer {{{1

" Is there a more conventional way of hiding text in markdown?{{{
"
" Yes.
"
" The default spec for markdown supports html.
" And in html, you can use the `<details>` tag:
"
"     <details><summary>
"     question</summary>
"     hidden answer</details>
"}}}
"    How could I use implement it?{{{
"
"     syn match markdownHideAnswer '<details>\n\=<summary>' conceal containedin=markdownCodeBlock
"     syn region markdownShowAnswer matchgroup=Ignore start='</summary>' end='</details>' conceal containedin=markdownCodeBlock
"     hi link markdownHideAnswer Ignore
"     hi link markdownShowAnswer PreProc
"}}}
"    Why don't you use it?{{{
"
" It's too cumbersome to hide inline answers.
" Have a look at the answers we hide in:
"
"     ~/wiki/vim/command.md
"     ~/wiki/vim/exception.md
"
" So, for the moment, we keep our  ad-hoc system to hide inline answers.
"
" To hide blocks of lines, do what you want:
"
"    - use `<details>`
"    - use `↣ ↢`
"}}}
exe 'syn region markdownHideAnswer'
    \ . ' start=/^↣/'
    \ . ' end=/^↢.*/'
    \ . ' conceal'
    \ . ' cchar=?'
    \ . ' contains=markdownOutput,markdownCodeSpan'
    \ . ' containedin=markdownCodeBlock'
    \ . ' keepend'

exe 'syn match markdownHideAnswer'
    \ . ' /↣.\{-}↢/'
    \ . ' conceal'
    \ . ' cchar=?'
    \ . ' containedin=markdownCodeBlock'

" TODO: How to include italics inside a hidden answer?{{{
" We could add `contains=markdownItalic`.
" But the text in italics would not be concealed...
" We probably have the same issue with other styles (bold, ...).
"}}}
" }}}1

exe 'syn region markdownIdDeclaration'
    \ . ' matchgroup=markdownLinkDelimiter'
    \ . ' start=/^ \{,3\}!\=\[/'
    \ . ' end=/\]:/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' nextgroup=markdownUrl'
    \ . ' skipwhite'

exe 'syn match markdownUrl /\S\+/'
    \ . ' nextgroup=markdownLinkRefTitle'
    \ . ' skipwhite'
    \ . ' contained'

exe 'syn region markdownUrl'
    \ . ' matchgroup=markdownUrlDelimiter'
    \ . ' start=/</'
    \ . ' end=/>/'
    \ . ' oneline'
    \ . ' keepend'
    \ . ' nextgroup=markdownLinkRefTitle'
    \ . ' skipwhite'
    \ . ' contained'

" in  addition to double  quotes, the official  spec supports single  quotes and
" parentheses too
exe 'syn region markdownLinkRefTitle'
    \ . ' matchgroup=markdownUrlTitleDelimiter'
    \ . ' start=/"/'
    \ . ' end=/"/'
    \ . ' keepend'
    \ . ' contained'

" Break down the `start` pattern:{{{
"
"          ┌ optional subpattern
"          ├─────────────────────┐
"     !\=\[\%(\_[^]]*] \=[[(]\)\@=
"     ├─┘├┘   ├─────┘│├─┘├──┘
"     │  │    │      ││  └ an opening square bracket or parenthesis
"     │  │    │      │└ an optional space
"     │  │    │      └ a closing square bracket
"     │  │    │
"     │  │    └ a newline and any other character,
"     │  │      except a closing square bracket,
"     │  │      as many as possible
"     │  │
"     │  └ an opening square bracket
"     └ an optional bang
"}}}
exe 'syn region markdownLinkText'
    \ . ' matchgroup=markdownLinkTextDelimiter'
    \ . ' start=/!\=\[\%(\_[^]]*] \=[[(]\)\@=/'
    \ . ' end=/\]\%( \=[[(]\)\@=/'
    \ . ' nextgroup=markdownLink,markdownId'
    \ . ' skipwhite'
    \ . ' contains=@markdownSpanElements'
    \ . ' concealends'
    \ . ' keepend'

" If  you  change the  name  the  items  beginning with  `markdownLink`,  update
" `s:is_real_link()` in `./autoload/markdown/link_inline_to_ref.vim`.
exe 'syn region markdownLink'
    \ . ' matchgroup=markdownLinkDelimiter'
    \ . ' start=/(/'
    \ . ' end=/)/'
    \ . ' contains=markdownUrl'
    \ . ' keepend'
    \ . ' contained'
    \ . ' conceal'

exe 'syn region markdownId'
    \ . ' matchgroup=markdownIdDelimiter'
    \ . ' start=/\[/'
    \ . ' end=/\]/'
    \ . ' keepend'
    \ . ' contained'

exe 'syn region markdownAutomaticLink'
    \ . ' matchgroup=markdownUrlDelimiter'
    \ . ' start=/<\%(\w\+:\|[[:alnum:]_+-]\+@\)\@=/'
    \ . ' end=/>/'
    \ . ' keepend'
    \ . ' oneline'

syn match markdownFootnote '\[^[^\]]\+\]'
syn match markdownFootnoteDefinition '^\[^[^\]]\+\]:'

syn match markdownEscape '\\[][\\`*_{}()<>#+.!-]'
syn match markdownError '\w\@1<=_\w\@='

syn match markdownPointer '^\s*\%([v^✘✔]\+\s*\)\+$'

syn region markdownKey matchgroup=Special start=/<kbd>/ end=/<\/kbd>/ concealends

syn match markdownCommentTitle /^ \{,2}\u\w*\(\s\+\u\w*\)*:/ contains=markdownTodo
"                                 ├───┘
"                                 └ Why?
" We don't want `markdownCommentTitle` to match in a code block, nor in an item list.{{{
" It would break the highlighting of the text which follows on the line.
" So, we can't allow more than 2 leading spaces.
"}}}

exe 'syn match markdownTodo  /\CTO'.'DO\|FIX'.'ME/ contained'

" FIXME: This diagram, written in a code block, is highlighted as a table:{{{
"
"     rbbb rrr bbbr
"     │  │
"     │  └ blue
"     └ red
"
" Maybe it's an argument in favor of using 8 spaces to indent code blocks.
" This would leave us indentations of 3 spaces up to 7 spaces for other usage...
"
" Alternative:
" Use a literal tab character to indent a table.
" We  could distinguish  code from  a  table by  looking  at whether  a line  is
" indented with spaces or tabs.
" We would need to tweak `:RemoveTabs` so that it doesn't remove a tab character
" at the beginning of a line when it's followed by a table.
"}}}
syn match markdownTable /^    [│─┌└├].*/

syn match markdownOption /`\@1<='[a-z]\{2,}'`\@=/ contained containedin=markdownCodeSpan,markdownListItemCodeSpan

call markdown#highlight_embedded_languages()

" HG {{{1

" TODO:
" Make sure that the HG used by any style  that we use in a markdown buffer + in
" the  comments  of  other  filetypes  is  always  defined  in  our  colorscheme
" customizations.
" This  way,  we have  a  central  location from  which  we  can change  the
" highlighting of *all* the filetypes.
"
" Also, some of our syntax items in comments rely on a markdown syntax group.
" Example, `markdownListItemBlockquote`.
" If we define  the latter here, our comments wouldn't  be correctly highlighted
" as long as a markdown buffer hasn't been loaded.

hi markdownItalic     term=italic      cterm=italic      gui=italic
hi markdownBold       term=bold        cterm=bold        gui=bold
hi markdownBoldItalic term=bold,italic cterm=bold,italic gui=bold,italic

hi link markdownHeader                Title
hi link markdownHeadingRule           markdownRule

hi link markdownFootnote              Typedef
hi link markdownFootnoteDefinition    Typedef

hi link markdownId                    Type
hi link markdownAutomaticLink         markdownUrl
hi link markdownLinkRefTitle          String
hi link markdownIdDelimiter           markdownLinkDelimiter
hi link markdownUrlDelimiter          Function
hi link markdownUrlTitleDelimiter     Delimiter

hi link markdownItalicDelimiter       markdownItalic
hi link markdownBoldDelimiter         markdownBold
hi link markdownBoldItalicDelimiter   markdownBoldItalic
hi link markdownCodeDelimiter         Delimiter

hi link markdownEscape                Special
" Why do you highlight some underscores as errors, and how to avoid them?{{{
"
" According  to tpope,  we should  always wrap a  word containing  an underscore
" inside a code span:
"
" > There's no such thing as an underscore in natural language.
" > What you want is an inline code block, no two ways about it.
"
" > Different  markdown  engines  have  different tolerance  levels  for  inline
" > underscores.
" > Many will screw  you over with a  giant block of emphasized  text the second
" > you use 2 in one paragraph.
" > I flag them  as errors because they  *are* errors, even if  some engines are
" > more forgiving about them.
"
" Source:
"
"     https://github.com/tpope/vim-markdown/issues/85#issuecomment-149206804
"}}}
" Are there other ways to eliminate them?{{{
"
" You could get rid  of `markdownError`, but it doesn't work in  a title, and it
" would cause other syntax rules to start an italic section on some underscores.
"
" You could also add a syntax group, linked to no HG:
"
"     syntax match markdownIgnore '\w_\w'
"
" But again, it doesn't work in titles.
"}}}
hi link markdownError                 Error

hi link markdownCommentTitle          PreProc
hi link markdownTodo                  Todo
hi link markdownOutput                PreProc
hi link markdownListItemOutput        markdownOutput
hi link markdownIgnore                Ignore
hi link markdownTable                 Structure
" }}}1

let b:current_syntax = 'markdown'

