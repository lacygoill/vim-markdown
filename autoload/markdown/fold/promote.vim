vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def markdown#fold#promote#main(_) #{{{2
    var cnt: number = v:count1
    for i in range(1, cnt)
        Promote()
    endfor
    getpos("'[")[1 : 2]->cursor()
enddef

def markdown#fold#promote#setup(arg_how: string): string #{{{2
    how = arg_how
    &opfunc = 'markdown#fold#promote#main'
    return 'g@'
enddef
var how: string
#}}}1
# Core {{{1
def Promote() #{{{2
    var range: string = ':' .. line("'[") .. ',' .. line("']")
    if how == 'more'
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)/\1#/e'
    else
        sil exe 'keepj keepp ' .. range .. 's/^\(#\+\)#/\1/e'
    endif
enddef

