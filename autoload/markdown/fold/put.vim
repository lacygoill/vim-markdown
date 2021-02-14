vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#put#main(below = true) #{{{1
    var header: string = search('^#', 'bnW')->getline()->matchstr('^#\+')
    if header == ''
        header = '#'
    endif

    if below
        append('.', ['', header, '', ''])
        norm! 4j
    else
        append(line('.') - 1, [header, '', '', ''])
        norm! 2k
    endif
    startinsert!
enddef

