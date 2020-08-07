fu markdown#fold#put#main(below) abort "{{{1
    let header = search('^#', 'bnW')->getline()->matchstr('^#\+')
    if header == '' | let header = '#' | endif

    if a:below
        call append('.', ['', header, '', ''])
        norm! 4j
    else
        call append(line('.') - 1, [header, '', '', ''])
        norm! 2k
    endif
    startinsert!
endfu

