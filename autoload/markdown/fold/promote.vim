" Interface {{{1
fu markdown#fold#promote#main(_) abort "{{{2
    let cnt = v:count1
    for i in range(1, cnt)
        call s:promote()
    endfor
    norm! gv
endfu

fu markdown#fold#promote#set(choice) abort "{{{2
    let s:choice = a:choice
endfu
"}}}1
" Core {{{1
fu s:promote() abort "{{{2
    let range = line("'<").','.line("'>")
    if s:choice is# 'more'
        sil exe 'keepj keepp '.range.'s/^\(#\+\)/\1#/e'
    else
        sil exe 'keepj keepp '.range.'s/^\(#\+\)#/\1/e'
    endif
endfu

