fu! markdown#check#punctuation(type, lnum1, lnum2) abort "{{{1
    if a:type is# '-help'
        h markdown-punctuation
        return ''
    elseif a:type isnot# '-comma'
        return ''
    endif

    let view = winsaveview()
    let &l:fen = 0

    " make sure any coordinating conjunction is preceded by a comma
    " > She wanted to study but she was tired. (✘)
    " > She wanted to study, but she was tired. (✔)
    let fanboys = ['for', 'and', 'nor', 'but', 'or', 'yet', 'so']
    let pat = join(fanboys, '\|')
    let pat = '\C[^,; \t]\zs\ze\_s\+\%('.pat.'\)\_s\+'

    let range = a:lnum1.','.a:lnum2
    call cursor(1,1)
    let loclist = []
    let bufnr = bufnr('%')
    let g = 0
    while search(pat, 'W') && g <= 1000
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
    let &l:fen = 1
    call winrestview(view)
    return ''
endfu

fu! markdown#check#punctuation_complete(arglead, _cmdline, _pos) abort "{{{1
    return join(['-comma', '-help'], "\n")
endfu
