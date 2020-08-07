" Interface {{{1
fu markdown#fold#promote#main(_) abort "{{{2
    let cnt = v:count1
    for i in range(1, cnt)
        call s:promote()
    endfor
    call getpos("'[")[1:2]->cursor()
endfu

fu markdown#fold#promote#setup(how) abort "{{{2
    let s:how = a:how
    let &opfunc = 'markdown#fold#promote#main'
    return 'g@'
endfu
"}}}1
" Core {{{1
fu s:promote() abort "{{{2
    let range = line("'[") .. ',' .. line("']")
    if s:how is# 'more'
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)/\1#/e'
    else
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)#/\1/e'
    endif
endfu

