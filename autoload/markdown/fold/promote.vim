vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def markdown#fold#promote#main(_: any) #{{{2
    var cnt = v:count1
    for i in range(1, cnt)
        Promote()
    endfor
    getpos("'[")[1 : 2]->cursor()
enddef

def markdown#fold#promote#setup(arghow: string): string #{{{2
    how = arghow
    &opfunc = 'markdown#fold#promote#main'
    return 'g@'
enddef
var how: string
#}}}1
# Core {{{1
def Promote() #{{{2
    var range = ':' .. line("'[") .. ',' .. line("']")
    if how == 'more'
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)/\1#/e'
    else
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)#/\1/e'
    endif
enddef

