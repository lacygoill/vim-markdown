" Init

" `:LinkInline2Ref` won't work as expected if the buffer contains more than `s:GUARD` links.
" This guard is useful to avoid being stuck in an infinite loop.
let s:GUARD = 1000
let s:REF_SECTION = '# Reference'

" Interface {{{1
fu markdown#link_inline2ref#main() abort "{{{2
    let view = winsaveview()
    let syntax_was_enabled = exists('g:syntax_on')
    if !syntax_was_enabled | syn enable | endif

    let [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
    let &l:fen = 0

    try
        " Make sure syntax highlighting is enabled.
        " `:argdo`, `:bufdo`, ... could disable it (e.g. `:argdo LinkInline2Ref`).
        let &ei = '' | do Syntax

        " We're going to inspect the syntax highlighting under the cursor.
        " Sometimes, it's wrong.
        " We must be sure it's correct.
        syn sync fromstart

        " Make sure there's no link whose description span multiple lines.
        " Those kind of links are too difficult to handle.
        if s:multi_line_links()
            return
        endif

        if !s:markdown_link_syntax_group_exists()
            echohl ErrorMsg
            echom 'The function relies on the syntax group ‘markdownLink’; but it doesn''t exist'
            echohl NONE
            return
        endif

        call s:make_sure_reference_section_exists()
        if s:id_outside_reference_section()
            return
        endif

        let id2url = s:create_reflinks()
        call s:populate_reference_section(id2url)
    finally
        if winbufnr(winid) == bufnr
            let [tabnr, winnr] = win_id2tabwin(winid)
            call settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
        if !syntax_was_enabled | syn off | endif
        call winrestview(view)
    endtry
endfu
" }}}1
" Core {{{1
fu s:create_reflinks() abort "{{{2
    call cursor(1, 1)
    let id = 1
    let id2url = {}
    let flags = 'cW'
    while search('\[.\{-}]\zs\%(\[\d\+]\|(.\{-})\)', flags) && id < s:GUARD
        let flags = 'W'
        let line = getline('.')
        let col = col('.')
        let char_under_cursor = matchstr(line, '\%' .. col .. 'c.')
        " [some text][some id]
        if char_under_cursor is# '['
            let old_id = matchstr(line, '\%' .. col .. 'c\[\zs\d\+\ze]')
            let url = s:get_url(old_id)
            " update id{{{
            "
            " For example, if the first reference link we find is:
            "
            "     [some text][3]
            "
            " We should renumber it with 1:
            "
            "     [some text][1]
            "}}}
            let new_line = substitute(line, '\%' .. col .. 'c\[\d\+', '[' .. id, '')
            " Do *not* use `:s`!{{{
            "
            " It would make the cursor move which would fuck everything up.
            "}}}
            call setline('.', new_line)
            let id2url[id] = url

        " [some text](some url)
        elseif char_under_cursor is# '('
            if !s:is_a_real_link()
                continue
            endif
            let url = s:get_url()
            norm! %
            let col_end = col('.')
            norm! %
            let new_line = substitute(line, '\%' .. col .. 'c(.*\%' .. col_end .. 'c)', '[' .. id .. ']', '')
            call setline('.', new_line)
            let id2url[id] = url
        endif
        let id += 1
    endwhile
    return id2url
endfu

fu s:populate_reference_section(id2url) abort "{{{2
    call search('^' .. s:REF_SECTION .. '$')
    if !search('^\[\d\+]:')
        norm! G
    endif
    sil keepj keepp .,$g/^\[\d\+]:/d_
    " Why don't you simply use `n` as the second argument of `sort()`, to get a numerical sort?{{{
    "
    " From `:h sort()`:
    "
    "    > Implementation detail: This  uses the strtod() function  to parse numbers,
    "    > **Strings**, Lists, Dicts and Funcrefs **will be considered as being 0**.
    "}}}
    let lines = mapnew(a:id2url, {k, v -> '[' .. k .. ']: ' .. v})
        \ ->values()
        \ ->sort({a,b -> matchstr(a, '\d\+') - matchstr(b, '\d\+')})
    call append('.', lines)
    sil exe 'keepj keepp %s/^' .. s:REF_SECTION .. '\n\n\zs\n//e'
endfu
" }}}1
" Util {{{1
fu s:get_url(...) abort "{{{2
    if a:0
        let id = a:1
        return search('^\[' .. id .. ']:', 'n')->getline()->matchstr(':\s*\zs.*')
    else
        " Do *not* use `norm! %`!{{{
        "
        " It would make the cursor move, which could cause an issue.
        " Suppose there're two inline links on the same line.
        "
        "     [text](long url) [other text](other url)
        "                    ^
        "                    cursor position, because of `%`
        "
        " Later, we'll convert the first link into a reference:
        "
        "     [text][123] [other text](other url)
        "                    ^
        "                    cursor position, same as before, thanks to `setline()`
        "
        " Since  the  absolute  cursor  position  didn't  change,  the  position
        " relative to the second link will  change, and it's possible that we're
        " now after its start; in that case, we'll miss it.
        "}}}
        norm! v%y
        return substitute(@", '^(\|)$\|\s', '', 'g')
    endif
endfu

fu s:id_outside_reference_section() abort "{{{2
    let ref_section_lnum = search('^' .. s:REF_SECTION .. '$', 'n')
    if search('^\[\d\+]:', 'n', ref_section_lnum)
        sil exe 'lvim /^\[\d\+]:\%<' .. ref_section_lnum .. 'l/j %'
        echom "There're id declarations outside the Reference section"
        call setloclist(0, [], 'a', {'title': 'move them inside or remove/edit them'})
        return 1
    endif
endfu

fu s:is_a_real_link() abort "{{{2
    return synstack('.', col('.'))
        \ ->map({_, v -> synIDattr(v, 'name')})
        \ ->reverse()
        \ ->match('^markdownLink') >= 0
endfu

fu s:make_sure_reference_section_exists() abort "{{{2
    let ref_section_lnum = search('^' .. s:REF_SECTION .. '$', 'n')
    if !ref_section_lnum
        call append('$', ['', '##', s:REF_SECTION, ''])
        "                 ├┘{{{
        "                 └ necessary if the last line of the buffer is a list item;
        "                   otherwise the reference section would be wrongly highlighted
        "                   as a list
        "}}}
    endif
endfu

fu s:markdown_link_syntax_group_exists() abort "{{{2
    try
        sil syn list markdownLink
    catch /^Vim\%((\a\+)\)\=:E28:/
        return 0
    endtry
    return 1
endfu

fu s:multi_line_links() abort "{{{2
    call cursor(1, 1)
    let pat = '\[[^][]*\n\_[^][]*](.*)'
    let flags = 'cW'
    let g = 0 | while search(pat, flags) && g <= s:GUARD | let g += 1
        let flags = 'W'
        if s:is_a_real_link()
            exe 'lvim /' .. pat .. '/gj %'
            call setloclist(0, [], 'a',
                \ {'title': 'some descriptions of links span multiple lines; make them mono-line'})
            return 1
        endif
    endwhile
    return 0
endfu

