vim9script noclear

var how: string

# Interface {{{1
def markdown#fold#promote#setup(arg_how: string): string #{{{2
    how = arg_how
    &operatorfunc = expand('<SID>') .. 'Do'
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
        execute 'silent keepjumps keeppatterns ' .. range .. 'substitute/^\(#\+\)/\1#/e'
    else
        execute 'silent keepjumps keeppatterns ' .. range .. 'substitute/^\(#\+\)#/\1/e'
    endif
enddef

