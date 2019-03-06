fu! markdown#get_definition#main(...) abort
    if a:0
        norm! gvy
        let word = @"
    else
        let word = expand('<cWORD>')
    endif
    let word = substitute(word, '[“”]', '', 'g')
    let cwd = getcwd()
    exe 'sp ' . cwd . '/glossary.md'
    let lines = getline(1, '$')
    call map(lines, {i,v -> {'bufnr': bufnr('%'), 'lnum': i+1, 'text': v}})
    let pat = '^#.*\V' . escape(word, '\')
    call filter(lines, {i,v -> v.text =~# pat})
    if empty(lines)
        close
        return
    endif
    call setloclist(0, lines)
    call setloclist(0, [], 'a', {'title': word})
    lwindow
    if &ft is# 'qf'
        lfirst
        norm! zv
    endif
endfu

