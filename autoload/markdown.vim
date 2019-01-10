" Interface {{{1
fu! markdown#highlight_embedded_languages() abort "{{{2
    return
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the  languages mentioned in `b:markdown_embed`,  and for each
    " of them, include the corresponding syntax plugin.
    "}}}
    let done_include = {}
    let filetypes = get(b:, 'markdown_embed', [])
    for delim in filetypes
        " If by accident, we wrote the  same embedded language several times, we
        " want to include the corresponding syntax plugin only once.
        if has_key(done_include, delim)
            continue
        endif
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
        \ . ' start="^\s*````*\s*'.delim.'\S\@!.*$"'
        \ . ' end="^\s*````*\ze\s*$"'
        \ . ' keepend'
        \ . ' concealends'
        \ . ' contains=@markdownEmbed'.ft
        let done_include[delim] = 1
    endfor
endfu
" }}}1
" Utilities {{{1
fu! s:get_filetype(ft) abort "{{{2
    let ft = a:ft
    if filereadable($VIMRUNTIME.'/syntax/'.ft.'.vim')
        return ft
    else
        let ft = matchstr(get(filter(split(execute('autocmd filetypedetect'), '\n'),
            \ {i,v -> v =~ '\*\.'.ft.'\>'}), 0, ''), 'setf\%[iletype]\s*\zs\S*')
        if filereadable($VIMRUNTIME.'/syntax/'.ft.'.vim')
            return ft
        endif
    endif
    return ''
endfu

