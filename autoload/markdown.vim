" Core {{{1
fu! markdown#define_include_clusters() abort "{{{2
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the  languages mentioned in `b:markdown_embed`,  and for each
    " of them, include the corresponding syntax plugin.
    "}}}
    " If `b:markdown_embed` contains `javascript=js`, what does it mean?{{{
    "
    " It means we want any fenced block beginning with the line:
    "
    "     ```javascript
    "
    " ... to be highlighted with the `js` syntax plugin.
    "
    " https://github.com/ixandidu/vim-markdown/commit/16157135e794598c46f38b2167f41c124c7dcccb#commitcomment-20485418
    "}}}
    " Why `map(..., ... matchstr() ...)`?{{{
    "
    " If the text contains an equal sign:
    "
    "       js=javascript
    "
    " ... we're only interested in what's after (here `javascript`).
    " Because that's the name of the syntax plugin we need to source.
    "}}}
    let done_include = {}
    let filetypes = map(copy(get(b:, 'markdown_embed', [])), {i,v -> matchstr(v, '[^=]*$')})
    for ft in filetypes
        " If by accident, we wrote the  same embedded language several times, we
        " want to include the corresponding syntax plugin only once.
        if has_key(done_include, ft)
            continue
        endif

        " What's the effect of `:syn include`?{{{
        "
        " If you execute:
        "
        "     syn include @markdownEmbedhtml syntax/html.vim
        "
        " Vim will install all items from  all html syntax plugins, and for each
        " of them, it will add the argument `contained`.
        " It means  that the item will  only match if it's  contained in another
        " one, which has the argument `contains=@markdownEmbedhtml`.
        "}}}
        exe 'syn include @markdownEmbed'.ft.' syntax/'.ft.'.vim'

        " We need to remove `b:current_syntax` to be sure the next syntax plugin
        " can be sourced, even if it has a guard.
        unlet! b:current_syntax
        let done_include[ft] = 1
    endfor
endfu

fu! markdown#highlight_embedded_languages() abort "{{{2
    let done_include = {}
    for item in get(b:, 'markdown_embed', [])
        if has_key(done_include, item)
            continue
        endif
        let ft = matchstr(item,'[^=]*$')
        let delim = matchstr(item,'[^=]*')
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
        let done_include[item] = 1
    endfor
endfu

fu! markdown#link_inline_2_ref() abort "{{{2
    let view = winsaveview()
    let &l:fen = 0

    if !search('^# Reference')
        " Why assigning `0` instead of `line('$')`?{{{
        "
        " The last  line address may change  between now and the  moment when we
        " need `last_line`.
        "}}}
        let last_line = 0
        let last_id = 0
    else
        call search('\%$')
        call search('^\[\d\+\]:', 'bW')
        let last_line = line('.')
        let last_id = matchstr(getline('.'), '^\[\zs\d\+\ze\]:')
    endif
    let orig_last_id = last_id

    call cursor(1,1)

    let g = 0
    let links = []
    " describe an inline link:
    "
    "     [description](url)
    let pat1 = '\[\_.\{-1,}\](\_.\{-1,})'
    let pat2 = '\[\_.\{-1,}\]\zs(\_.\{-1,})'
    while search(pat1, 'W')
     \ && s:is_a_real_link()
     \ && g <= 100
        " beginning of the url
        let lnum1 = line('.')
        " end of the url
        let lnum2 = search('(\_.\{-1,})\zs', 'W')

        let lines = getline(lnum1, lnum2)
        let text = join(lines, "\n")
        let link = substitute(matchstr(text, pat2), '[() \t\n]', '', 'g')
        let links += [link]
        let new_text = substitute(text, pat2, '['.(last_id+1).']', '')
        if lnum2 > lnum1
            sil! exe lnum1.','.(lnum2 - 1).'d_'
        endif
        let new_lines = split(new_text, '\n')
        call setline(lnum1, new_lines)
        let g:debug = 'norm '.lnum1.','.(lnum1 + len(new_lines)).'gqq'
        exe 'norm '.lnum1.'Ggq'.(len(new_lines) - 1).'j'
        let last_id += 1
        let g += 1
    endwhile

    if !empty(links)
        if !search('^# Reference')
            call append('$', ['##', '# Reference', ''])
        endif
        call map(links, {i,v -> '['.(i+1+orig_last_id).']: '.v})
        call append(last_line ? last_line : line('$'), links)
    endif

    let &l:fen = 1
    call winrestview(view)
endfu

" Util {{{1
fu! s:is_a_real_link() abort "{{{2
    return !empty(filter(reverse(map(synstack(line('.'), col('.')),
    \                            {i,v -> synIDattr(v, 'name')})),
    \             {i,v -> v =~# '^markdownLink'}))
endfu

