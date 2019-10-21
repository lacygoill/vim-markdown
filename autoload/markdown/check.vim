fu markdown#check#punctuation(type, lnum1, lnum2) abort "{{{1
    if a:type is# '-help'
        h markdown-punctuation
        return ''
    elseif a:type isnot# '-comma'
        return ''
    endif

    let view = winsaveview()
    let [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
    let &l:fen = 0

    try
        " make sure any coordinating conjunction is preceded by a comma
        " > She wanted to study but she was tired. (✘)
        " > She wanted to study, but she was tired. (✔)
        let fanboys =<< trim END
            for
            and
            nor
            but
            or
            yet
            so
        END
        let pat = join(fanboys, '\|')
        let pat = '\C[^,; \t]\zs\ze\_s\+\%('.pat.'\)\_s\+'

        let range = a:lnum1.','.a:lnum2
        call cursor(1,1)
        let loclist = []
        let g = 0
        let flags = 'cW'
        while search(pat, flags) && g <= 1000
            let flags = 'W'
            let loclist += [{
                \ 'lnum': line('.'),
                \ 'col': col('.'),
                \ 'bufnr': bufnr,
                \ 'text': getline('.'),
                \ }]
            let g += 1
        endwhile
        call setloclist(0, loclist)
        " populate the command-line with `:ldo s/\%#/,/c` when we press `C-g s`
        call setloclist(0, [], 'a', {
            \ 'title': ':CheckPunctuation -comma',
            \ 'context': {'populate': 'ldo s/\%#/,/c'}
            \ })
        lw
    finally
        if winbufnr(winid) == bufnr
            let [tabnr, winnr] = win_id2tabwin(winid)
            call settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
        call winrestview(view)
    endtry
    return ''
endfu

fu markdown#check#punctuation_complete(_a, _l, _p) abort "{{{1
    return join(['-comma', '-help'], "\n")
endfu
