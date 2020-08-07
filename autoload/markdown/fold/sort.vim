fu markdown#fold#sort#by_size(lnum1,lnum2) abort "{{{1
    " get the level of the first fold
    let lvl = getline(a:lnum1)->matchstr('^#*')->strlen()
    if lvl == 0
        return 'echoerr "the first line is not a fold title"'
    endif

    " disable folding, because it could badly interfere when we move lines with `:m`
    let [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
    let &l:fen = 0
    try
        " What's this?{{{
        "
        " A pattern describing the end of a fold.
        " To be more accurate, its last newline or the end of the buffer.
        "}}}
        " Why \{1,lvl}?{{{
        "
        " We mustn't stop when we find a fold whose level is bigger than `lvl`.
        " Those are children folds; they should be ignored.
        " Thus, the quantifier must NOT go beyond `lvl`.
        "
        " Also, we must stop if we find a fold whose level is smaller.
        " Those are parents.
        " Thus, the quantifier *must* go below `lvl`.
        "
        "}}}
        let pat = '\n\%(#\{1,' .. lvl .. '}#\@!\)\|\%$'

        call cursor(a:lnum1, 1)

        " search the end of the first fold
        let foldend = search(pat, 'W', a:lnum2)
        if foldend == 0 | return '' | endif
        " What's this?{{{
        "
        " We begin populating the list `folds`.
        " Each item in this list is a dictionary with three keys:
        "
        "    - foldstart:    first line in the fold
        "    - foldend:      last line in the fold
        "    - size:         size of the fold
        "}}}
        let folds = [{'foldstart': a:lnum1, 'foldend': foldend, 'size': foldend - a:lnum1 + 1}]
        " What does the loop do?{{{
        "
        "    1. it looks for the end of the next fold with the same level
        "
        "    2. it populates the list `folds` with info about this new current fold
        "
        "    3. every time it finds a previous fold which is bigger
        "       than the current one:
        "
        "        - it moves the latter above
        "        - it re-calls the function to continue the process
        "}}}
        while foldend > 0
            for f in folds
                " if you find a previous fold which is bigger
                if f.size > folds[-1].size
                    " move last fold above
                    sil exe printf('%d,%dm %d',
                        \ folds[-1].foldstart,
                        \ folds[-1].foldend,
                        \ f.foldstart - 1)
                    return markdown#fold#sort#by_size(a:lnum1,a:lnum2)
                endif
            endfor

            let orig_lnum = line('.')
            let foldend = search(pat, 'W', a:lnum2)
            "                                        ┌ stop if you've found a fold whose level is < `lvl`
            "                                        │
            if foldend == 0 || getline(orig_lnum+1)->match('^\%(#\{' .. (lvl-1) .. '}#\@!\)') == 0
                break
            endif
            let folds += [{'foldstart': orig_lnum + 1, 'foldend': foldend, 'size': foldend - orig_lnum}]
        endwhile
    finally
        if winbufnr(winid) == bufnr
            let [tabnr, winnr] = win_id2tabwin(winid)
            call settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
    endtry
    return ''
endfu

