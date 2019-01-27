" Interface {{{1
fu! markdown#highlight_embedded_languages() abort "{{{2
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the  languages mentioned in `b:markdown_embed`,  and for each
    " of them, include the corresponding syntax plugin.
    "}}}
    let done_include = {}
    let delims = get(b:, 'markdown_embed', [])
    for delim in delims
        " If by accident, we manually  assign a value to `b:markdown_embed`, and
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

        " What's the effect of `:syn include`?{{{
        "
        " If you execute:
        "
        "     syn include @markdownEmbedpython syntax/python.vim
        "
        " 1. Vim will define all groups from  all python syntax plugins, but for
        " each of them, it will add the argument `contained`.
        "
        " 2. Vim will  define the cluster `@markdownEmbedpython`  which contains
        " all the syntax groups define in python syntax plugins.
        "
        " Note that if `b:current_syntax` is set, Vim won't define the contained
        " python syntax groups; the cluster will be defined but contain nothing.
        "}}}
        exe 'syn include @markdownEmbed'.ft.' syntax/'.ft.'.vim'
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
        "     'markdownEmbed'.ft
        "
        " But there's no conflict.
        " Probably because a cluster name is always prefixed by `@`.
        "}}}
        exe 'syn region markdownEmbed'.ft
        \ . ' matchgroup=markdownCodeDelimiter'
        \ . ' start=/^\s*````*\s*'.delim.'\S\@!.*$/'
        \ . ' end=/^\s*````*\ze\s*$/'
        \ . ' keepend'
        \ . ' concealends'
        \ . ' contains=@markdownEmbed'.ft
        let done_include[delim] = 1
    endfor
endfu

fu! markdown#fix_wrong_headers() abort "{{{2
    " Make sure syntax highlighting is enabled.{{{
    "
    " This function is called by `:FixWrongHeaders`.
    " If we invoke the latter via `:argdo`:
    "
    "     argdo FixWrongHeaders
    "
    " The syntax highlighting will be disabled.
    " See `:h :bufdo`.
    "}}}
    let &ei = '' | do Syntax

    let view = winsaveview()
    call cursor(1, 1)
    let g = 0
    while search('^#', 'W') && g < 1000
        let item = get(map(synstack(line('.'), col('.')), {i,v -> synIDattr(v, 'name')}), -1, '')
        " Why `''` in addition to `Delimiter`?{{{
        "
        " Just in case there's still no syntax highlighting.
        "}}}
        if index(['', 'Delimiter'], item) == -1
            let line = getline('.')
            let new_line = ' ' . line
            call setline('.', new_line)
        endif
        let g += 1
    endwhile
    call winrestview(view)
endfu

" }}}1
" Utilities {{{1
fu! s:get_filetype(ft) abort "{{{2
    let ft = a:ft
    if filereadable($VIMRUNTIME.'/syntax/'.ft.'.vim')
        return ft
    else
        let ft = matchstr(get(filter(split(execute('autocmd filetypedetect'), '\n'),
            \ {i,v -> v =~# '\m\C\*\.'.ft.'\>'}), 0, ''), '\m\Csetf\%[iletype]\s*\zs\S*')
        if filereadable($VIMRUNTIME.'/syntax/'.ft.'.vim')
            return ft
        endif
    endif
    return ''
endfu

