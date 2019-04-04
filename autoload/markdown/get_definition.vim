fu! markdown#get_definition#main(...) abort
    if a:0
        norm! gvy
        let word = @"
    else
        let word = expand('<cWORD>')
    endif
    let word = substitute(word, '[“(]\|[”)].*\|[.?s]\{,2}$', '', 'g')
    let fname = expand('%:p:t')
    if fname isnot# 'glossary.md'
        let cwd = getcwd()
        exe 'sp ' . cwd . '/glossary.md'
    endif
    let lines = getline(1, '$')
    call map(lines, {i,v -> {'bufnr': bufnr('%'), 'lnum': i+1, 'text': v}})
    let pat = '^#.*\c\V' . escape(word, '\')
    call filter(lines, {i,v -> v.text =~# pat})
    if empty(lines)
        echom 'no definition for ' . word
        if fname isnot# 'glossary.md'
            close
        endif
        return
    else
        " erase possible previous 'no definition for' message
        redraw!
    endif
    call setloclist(0, lines)
    call setloclist(0, [], 'a', {'title': word})
    lwindow
    if &ft is# 'qf'
        lfirst
        norm! zMzvzz
    endif
endfu

