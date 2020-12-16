" Interface {{{1
fu markdown#highlight_languages() abort "{{{2
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the  languages mentioned in `b:markdown_highlight`,  and for each
    " of them, include the corresponding syntax plugin.
    "}}}
    let done_include = {}
    let delims = get(b:, 'markdown_highlight', [])
    for delim in delims
        " If by accident, we manually  assign a value to `b:markdown_highlight`, and
        " we write duplicate values, we want to include the corresponding syntax
        " plugin only once.
        if has_key(done_include, delim)
            continue
        endif
        " We can't blindly rely on the delim:{{{
        "
        "     " ✔
        "     ```python
        "     " here, we indeed want the python syntax plugin
        "
        "     " ✘
        "     ```js
        "     " there's no js syntax plugin
        "     " we want the javascript syntax plugin
        "}}}
        let ft = s:get_filetype(delim)
        if empty(ft) | continue | endif

        " Warning: do *not* use a different prefix than `markdownHighlight` in the cluster name{{{
        "
        " That's the  prefix used by the  default markdown plugin; as  a result,
        " that's the one assumed by other default syntax plugins such as the zsh
        " one:
        "
        " https://github.com/chrisbra/vim-zsh/blob/25c49bd61b8e82fd8f002c0ef21416d6550f79ea/syntax/zsh.vim#L22-L24
        "
        " If  you change  the prefix,  an embedded fenced  codeblock may  not be
        " correctly highlighted.
        "}}}
        " What's the effect of `:syn include`?{{{
        "
        " If you execute:
        "
        "     syn include @markdownHighlightpython syntax/python.vim
        "
        " 1. Vim will define all groups from  all python syntax plugins, but for
        " each of them, it will add the argument `contained`.
        "
        " 2. Vim will  define the cluster `@markdownHighlightpython`  which contains
        " all the syntax groups define in python syntax plugins.
        "
        " Note that if `b:current_syntax` is set, Vim won't define the contained
        " python syntax groups; the cluster will be defined but contain nothing.
        "}}}
        exe 'syn include @markdownHighlight' .. ft .. ' syntax/' .. ft .. '.vim'
        " Why?{{{
        "
        " The previous `:syn  include` has caused `b:current_syntax`  to bet set
        " to the value stored in `ft`.
        " If more than one language is embedded, the next time that we run
        " `:syn include`, the resulting cluster will contain nothing.
        "}}}
        unlet! b:current_syntax

        " Note that the name of the region is identical to the name of the cluster:{{{
        "
        "     'markdownHighlight' .. ft
        "
        " But there's no conflict.
        " Probably because a cluster name is always prefixed by `@`.
        "}}}
        exe 'syn region markdownHighlight' .. ft
            \ .. ' matchgroup=markdownCodeDelimiter'
            \ .. ' start=/^\s*````*\s*' .. delim .. '\S\@!.*$/'
            \ .. ' end=/^\s*````*\ze\s*$/'
            \ .. ' keepend'
            \ .. ' concealends'
            \ .. ' contains=@markdownHighlight' .. ft
        let done_include[delim] = 1
    endfor
    if !empty(delims) | syn sync ccomment markdownHeader | endif
    " TODO: The previous line is necessary to fix an issue.  But is it the right fix?{{{
    "
    " Here is the issue:
    "
    "     $ vim +"%d|pu=['# x', '', '\`\`\`vim']+repeat([''], 9)+['\`\`\`']+repeat([''], 109)+['# x', '', 'some text']" +x /tmp/md.md
    "     $ vim +'norm! Gzo' /tmp/md.md
    "
    " Without the  previous `:syn sync`,  `some text` is wrongly  highlighted by
    " `markdownFencedCodeBlock`.  Study `:h 44.10` then `:h :syn-sync`.
    "
    " ---
    "
    " Note that whenever  we run a `:syn  include`, there is a risk  that it has
    " changed how  the synchronization is  performed (by sourcing a  `:syn sync`
    " directive).
    "
    " ---
    "
    " Is there a risk that a `:syn include` resets a `:syn iskeyword`?
    " Or some other syntax-specific setting?
    " If so, should  we try to save its value before  `:syn include` and restore
    " it afterward?
    "}}}
endfu

fu markdown#fix_formatting() abort "{{{2
    let view = winsaveview()

    " A page may have an embedded codeblock which is not properly ended with ```` ``` ````.{{{
    "
    " As an example, look at the very bottom of this page:
    " https://github.com/junegunn/fzf/wiki/Examples
    "
    " In  this case,  the highlighting  of the  reference links  we're going  to
    " create may be wrong.
    " And the rest of the function  relies on the syntax highlighting, which may
    " have additional unexpected side effects.
    "}}}
    if synstack('$', 1)
        \ ->map({_, v -> synIDattr(v, 'name')})
        \ ->get(0, '') =~# '^markdownHighlight'
        call append('$', ['```', ''])
    endif

    " Why?{{{
    "
    " If a link contains a closing parenthesis, it breaks the highlighting.
    " The latter (and the conceal) stops too early.
    "
    " Besides, on some markdown pages like this one:
    "
    "     https://github.com/junegunn/fzf/wiki/Examples
    "
    " Some links are invisible.
    "
    "     ![](https://github.com/piotryordanov/fzf-mpd/raw/master/demo.gif)
    "       ^
    "       ✘
    " This is because there's no description of the link.
    "
    " We can fix all of these issues by converting inline links to reference links.
    "}}}
    LinkInline2Ref

    " If our file  contains an embedded codeblock, and the  latter contains some
    " comments beginning with `#`, they may be wrongly interpreted as headers.
    " Fix this by adding a space in front of them.
    " Make sure syntax highlighting is enabled.{{{
    "
    " This function is called by `:Fix`.
    " If we invoke the latter via `:argdo`:
    "
    "     argdo Fix
    "
    " The syntax highlighting will be disabled.
    " See `:h :bufdo`.
    "}}}
    let &ei = '' | do Syntax

    call cursor(1, 1)
    let flags = 'cW'
    let g = 0 | while search('^#', flags) && g < 999 | let g += 1
        let flags = 'W'
        let item = synstack('.', col('.'))
            \ ->map({_, v -> synIDattr(v, 'name')})
            \ ->get(-1, '')
        " Why `''` in addition to `Delimiter`?{{{
        "
        " Just in case there's still no syntax highlighting.
        "}}}
        if index(['', 'Delimiter'], item) == -1
            let line = getline('.')
            let new_line = ' ' .. line
            call setline('.', new_line)
        endif
    endwhile
    call winrestview(view)
endfu

fu markdown#undo_ftplugin() abort "{{{2
    set ai< cms< cocu< cole< com< efm< fde< fdm< fdt< flp< fml< fp< kp< mp< spl< tw< wrap<
    unlet! b:cr_command b:exchange_indent b:sandwich_recipes b:markdown_highlight b:mc_chain
    sil! au! InstantMarkdown * <buffer>
    sil! au! MarkdownWindowSettings * <buffer>

    nunmap <buffer> cof
    nunmap <buffer> [of
    nunmap <buffer> ]of
    nunmap <buffer> gd
    xunmap <buffer> gd
    nunmap <buffer> gl

    nunmap <buffer> +[#
    nunmap <buffer> +]#

    nunmap <buffer> =rb
    nunmap <buffer> =r-
    nunmap <buffer> =r--
    xunmap <buffer> =r-

    xunmap <buffer> H
    xunmap <buffer> L

    delc CheckPunctuation
    delc CommitHash2Link
    delc FixFormatting
    delc FoldSortBySize
    delc LinkInline2Ref
    delc Preview
endfu

fu markdown#hyphens2hashes(...) abort "{{{2
    if !a:0
        let &opfunc = 'markdown#hyphens2hashes'
        return 'g@'
    endif
    let range = "'[,']"
    let hashes = search('^#', 'bnW')->getline()->matchstr('^#*')
    if empty(hashes) | return | endif
    sil exe range .. 's/^---/' .. hashes .. ' ?/e'
endfu

fu markdown#fix_fenced_code_block() abort "{{{2
    if execute('syn list @markdownHighlightvim', 'silent!') !~# 'markdownHighlightvim'
        return
    endif
    " Why here?  Why not in our Vim syntax plugin?{{{
    "
    " Well, we do write  it in our Vim syntax plugin  too; it's indeed necessary
    " for Vim files, but it's not enough for markdown files, because `syn clear`
    " is ignored when run from an included syntax file.
    "
    " From `:h 44.9`:
    "
    "    > The `:syntax  include` command is  clever enough  to ignore a  `:syntax clear`
    "    > command in the included file.
    "}}}
    syn clear vimUsrCmd
endfu
" }}}1
" Utilities {{{1
fu s:get_filetype(ft) abort "{{{2
    let ft = a:ft
    if filereadable($VIMRUNTIME .. '/syntax/' .. ft .. '.vim')
        return ft
    else
        let ft = execute('autocmd filetypedetect')
            \ ->split('\n')
            \ ->filter({_, v -> v =~# '\m\C\*\.' .. ft .. '\>'})
            \ ->get(0, '')
            \ ->matchstr('\m\Csetf\%[iletype]\s*\zs\S*')
        if filereadable($VIMRUNTIME .. '/syntax/' .. ft .. '.vim')
            return ft
        endif
    endif
    return ''
endfu

