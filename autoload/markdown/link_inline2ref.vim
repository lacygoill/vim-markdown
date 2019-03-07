" Init

" `:LinkInline2Ref` won't work as expected if the buffer contains more than `s:GUARD` links.
" This guard is useful to avoid being stuck in an infinite loop.
let s:GUARD = 1000
let s:LINK_IN_REFERENCE = '^\[\d\+\]:'

" Interface {{{1
fu! markdown#link_inline2ref#main() abort "{{{2
    let view = winsaveview()
    let fen_save = &l:fen

    try
        let &l:fen = 0
        " Make sure syntax highlighting is enabled.
        " `:argdo`, `:bufdo`, ... could disable it.
        let &ei = '' | do Syntax

        " We're going to inspect the syntax highlighting under the cursor.
        " Sometimes, it's wrong.
        " We must be sure it's correct.
        syn sync fromstart

        " Make sure there's no link whose description span multiple lines.
        " Those kind of links are too difficult to handle.
        if s:find_multi_line_links()
            return
        endif

        let ref_links = s:get_ref_links()
        call s:make_sure_reference_section_exists(ref_links)

        " If there're already reference links in the buffer, get the numerical id of
        " the biggest one; we need it to correctly number the new links we may find.
        let [last_id, last_id_lnum] = s:get_last_id(ref_links)
        let last_id_old = last_id

        call cursor(1,1)
        let [links, last_id] = s:collect_links(last_id)
        if empty(links)
            return
        endif

        call s:put_links(links, last_id_old, last_id_lnum)

        " if we've  just added a new  link before the  first one, our links  will be
        " numbered in a non-increasing way; re-number all the links
        call s:renumber_links(last_id)
    finally
        let &l:fen = fen_save
        call winrestview(view)
    endtry
endfu
" }}}1
" Core {{{1
fu! s:find_multi_line_links() abort "{{{2
    call cursor(1,1)
    let g = 0
    let pat = '\[[^]]*\n\_.\{-}\](.*)'
    while search(pat) && g <= s:GUARD
        if s:is_a_real_link()
            exe 'lvim /'.pat.'/gj %'
            call setloclist(0, [], 'a',
                \ {'title': 'some descriptions of links span multiple lines; make them mono-line'})
            return 1
        endif
        let g += 1
    endwhile
    return 0
endfu

fu! s:make_sure_reference_section_exists(ref_links) abort "{{{2
    if !search('^# Reference$') && !empty(a:ref_links)
        call append('$', ['##', '# Reference', ''])
        " Move the existing reference links  which were not in a `Reference`
        " section, inside the latter.
        exe 'keepj keepp g/'.s:LINK_IN_REFERENCE.'/m$'
    endif
endfu

fu! s:get_last_id(ref_links) abort "{{{2
    if !search('^# Reference$')
        " Why assigning `0` instead of `line('$')`?{{{
        "
        " The last  line address may change  between now and the  moment we need
        " `last_id_lnum`.
        "}}}
        let last_id_lnum = 0
        if empty(a:ref_links)
            let last_id = 0
        else
            let last_id = max(map(copy(a:ref_links), {i,v -> matchstr(v, '^\[\zs\d\+')}))
        endif
    else
        call search('\%$')
        call search(s:LINK_IN_REFERENCE, 'bW')
        let last_id_lnum = line('.')
        let last_id = matchstr(getline('.'), s:LINK_IN_REFERENCE)
        let last_id = substitute(last_id, '^\[\|\]:', '', 'g')
    endif
    return [last_id, last_id_lnum]
endfu

fu! s:collect_links(last_id) abort "{{{2
    let last_id = a:last_id

    let g = 0
    let links = []
    " describe an inline link:
    "
    "     [description](url)
    let pat = '\[.\{-}\]\zs(.\{-})'
    while search(pat, 'W') && g <= s:GUARD
        if !s:is_a_real_link()
            continue
        endif

        norm! %
        let line = getline('.')
        let link = matchstr(line, '\[.\{-}\](\zs.*\%'.col('.').'c')
        let link = substitute(link, '\s', '', 'g')

        let links += [link]
        let new_line = substitute(line, '('.link.')', '['.(last_id+1).']', '')

        " put the new link
        call setline('.', new_line)
        " There could be several links on the same line, and `setline()` doesn't
        " reset the position of the cursor; so, the new cursor position could be
        " *after* a second link, and in that case, we would miss it.
        call cursor('.', 1)

        let last_id += 1
        let g += 1
    endwhile
    return [links, last_id]
endfu

fu! s:put_links(links, last_id_old, last_id_lnum) abort "{{{2
    let links = a:links
    " Put the links at the bottom of the buffer.
    if !empty(links)
        if !search('^# Reference$')
            call append('$', ['', '##', '# Reference', ''])
            "                 ├┘{{{
            "                 └ necessary if the last line of the buffer is a list item;
            "                   otherwise the reference section would be wrongly highlighted
            "                   as a list
            "}}}
        endif
        call map(links, {i,v -> '['.(i+1 + a:last_id_old).']: '.v})
        call append(a:last_id_lnum ? a:last_id_lnum : line('$'), links)
    endif
endfu

fu! s:renumber_links(last_id) abort "{{{2
    " Iterate over the ids of the links.
    " Search for `[some text][some id]`.
    " If the id is not `i`:
    "
    "    - replace it with `i`
    "    - search for `^[this id]:` after `# Reference` and replace it with `i`
    "
    " Finally, sort the links in `# Reference`.

    call cursor(1, 1)
    let pat1 = '\[[^]]*\]\[\d\+\]'
    for i in range(1, a:last_id)
        call search(pat1, 'W')
        let pos = getcurpos()
        if s:is_a_real_link()
            let line = getline('.')
            let pat2 = '\%'.col('.').'c\&'.'\[[^]]*\]\[\zs\d\+\ze\]'
            let id = matchstr(line, pat2)
            if id != i
                " replace `id` with `i`
                let new_line = substitute(line, pat2, i, '')
                call setline('.', new_line)

                " search for `^[id]:` after `# Reference`
                call search('\%$')
                call search('^\['.id.'\]:', 'bW')
                " again replace the id with `i`
                let line = getline('.')
                " Why the `C-a` character?{{{
                "
                " Suppose our buffer  contains two links; the first  one has the
                " id `2`, while the second one has the id `1`.
                "
                " During the first iteration of this loop, our function replaces
                " the id `2` with `1` in the link, and in the reference section.
                " But now, we have two `[1]:` inside our reference section.
                " So, in the  next iteration, when we'll search  `^[1]:`, we may
                " find the wrong one.
                "
                " We  need   a  way   to  temporarily  distinguish   between  an
                " UNprocessed id, and a processed one.
                " That's what `C-a` is for.
                "}}}
                let new_line = substitute(line, '^\[\zs\d\+\ze\]:', "\<c-a>".i, '')
                call setline('.', new_line)
                call setpos('.', pos)
            endif
        endif
    endfor
    " remove the temporarily added `C-a` characters
    keepj keepp %s/^\[\zs\%x01\ze\d\+\]://e

    " sort the links in `# Reference`
    let range = search('^# Reference$').','.line('$')
    exe range.'sort n'
endfu
" }}}1
" Util {{{1
fu! s:get_ref_links() abort "{{{2
    return filter(getline(1, '$'), {i,v -> v =~# s:LINK_IN_REFERENCE})
endfu

fu! s:is_a_real_link() abort "{{{2
    return !empty(filter(reverse(map(synstack(line('.'), col('.')),
        \ {i,v -> synIDattr(v, 'name')})),
        \ {i,v -> v =~# '^markdownLink'}))
endfu

