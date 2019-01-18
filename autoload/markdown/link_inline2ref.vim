" Init

" `:LinkInline2Ref` won't work as expected if the buffer contains more than `s:GUARD` links.
" This guard is useful to avoid being stuck in an infinite loop.
let s:GUARD = 100

" Interface {{{1
fu! markdown#link_inline2ref#main() abort "{{{2
    let view = winsaveview()
    let &l:fen = 0
    " We're going to inspect the syntax highlighting under the cursor.
    " Sometimes, it's wrong.
    " We must be sure it's correct.
    syn sync fromstart

    " Make sure there's no link whose description span multiple lines.
    " Those kind of links are too difficult to handle.
    if s:find_multi_line_links()
        return
    endif

    " If there're already reference links in the buffer, get the numerical id of
    " the biggest one; we need it to correctly number the new links we may find.
    let [last_id_new, last_lnum] = s:get_last_id()
    let last_id_old = last_id_new

    call cursor(1,1)
    let [links, last_id_new] = s:collect_links(last_id_new)

    call s:put_links(links, last_id_old, last_lnum)

    " TODO: if we've just added a new  link before the first one, our links will
    " be numbered in a non-increasing way; find a way to re-number all the links.
    call s:renumber(last_id_new)

    let &l:fen = 1
    call winrestview(view)
endfu

" }}}1
" Core {{{1
fu! s:find_multi_line_links() abort "{{{2
    call cursor(1,1)
    let g = 0
    let pat = '\[[^]]\{-}\n\_.\{-}\](.*)'
    while search(pat) && g <= s:GUARD
        if s:is_a_real_link()
            exe 'lvim /'.pat.'/gj %'
            call setloclist(0, [], 'a', {'title': 'some links span multiple lines; make them mono-line'})
            return 1
        endif
        let g += 1
    endwhile
    return 0
endfu

fu! s:get_last_id() abort "{{{2
    if !search('^# Reference')
        " Why don't you put the `# Reference` line now?{{{
        "
        " There's no guarantee that we'll find any link in the buffer.
        "}}}
        " Why assigning `0` instead of `line('$')`?{{{
        "
        " The last  line address may change  between now and the  moment when we
        " need `last_lnum`.
        "}}}
        let last_lnum = 0
        let ref_links = filter(getline(1, '$'), {i,v -> v =~# '^[\d\+\]:'})
        if !empty(ref_links)
            let last_id_new = max(map(ref_links, {i,v -> matchstr(v, '^\[\zs\d\+')}))
            call append('$', ['##', '# Reference', ''])
            " Move the existing reference links  which were not in a `Reference`
            " section, inside the latter.
            keepj keepp g/^\[\d\+\]:/m$
        else
            let last_id_new = 0
        endif
    else
        call search('\%$')
        call search('^\[\d\+\]:', 'bW')
        let last_lnum = line('.')
        let last_id_new = matchstr(getline('.'), '^\[\zs\d\+\ze\]:')
    endif
    return [last_id_new, last_lnum]
endfu

fu! s:collect_links(last_id_new) abort "{{{2
    let last_id_new = a:last_id_new

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
        let new_line = substitute(line, '('.link.')', '['.(last_id_new+1).']', '')

        " put the new link
        call setline('.', new_line)

        let last_id_new += 1
        let g += 1
    endwhile
    return [links, last_id_new]
endfu

fu! s:put_links(links, last_id_old, last_lnum) abort "{{{2
    let links = a:links
    " Put the links at the bottom of the buffer.
    if !empty(links)
        if !search('^# Reference')
            call append('$', ['##', '# Reference', ''])
        endif
        call map(links, {i,v -> '['.(i+1 + a:last_id_old).']: '.v})
        call append(a:last_lnum ? a:last_lnum : line('$'), links)
    endif
endfu
fu! s:renumber(last_id_new) abort "{{{2
    for i in range(1, last_id_new)
        " search for [some text][some number]
        " if the number is not `i`:
        "
        "    - replace it with `i`
        "    - search for `^[this number]:` after `# Reference` and replace it with `i`
        "
        " Finally, sort the links in `# Reference`.
    endfor
endfu
" }}}1
" Util {{{1
fu! s:is_a_real_link() abort "{{{2
    return !empty(filter(reverse(map(synstack(line('.'), col('.')),
        \ {i,v -> synIDattr(v, 'name')})),
        \ {i,v -> v =~# '^markdownLink'}))
endfu

