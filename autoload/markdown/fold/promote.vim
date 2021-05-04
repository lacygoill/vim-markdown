vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

var how: string

# Interface {{{1
def markdown#fold#promote#setup(arg_how: string): string #{{{2
    how = arg_how
    &opfunc = expand('<SID>') .. 'Do'
    return 'g@'
enddef
#}}}1
# Core {{{1
def Do(_) #{{{2
    var cnt: number = v:count1
    for i in range(1, cnt)
        Promote()
    endfor
    getpos("'[")[1 : 2]->cursor()
enddef

def Promote() #{{{2
    var range: string = ':' .. line("'[") .. ',' .. line("']")
    if how == 'more'
        exe 'sil keepj keepp ' .. range .. 's/^\(#\+\)/\1#/e'
    else
        exe 'sil keepj keepp ' .. range .. 's/^\(#\+\)#/\1/e'
    endif
enddef

