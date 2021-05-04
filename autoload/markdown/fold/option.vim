vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#option#fdl(choice: string)
    if &l:fde !~ 'nested'
        echo "the folds are not nested; change 'fde' first"
        return
    endif

    if choice == 'more'
        ++&l:fdl
    else
        &l:fdl = (&l:fdl == 0 ? 0 : &l:fdl - 1)
    endif
    echo "'fdl' = " .. &l:fdl
enddef

