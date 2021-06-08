vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#option#foldlevel(choice: string)
    if &l:foldexpr !~ 'nested'
        echo "the folds are not nested; change 'foldexpr' first"
        return
    endif

    if choice == 'more'
        ++&l:foldlevel
    else
        &l:foldlevel = (&l:foldlevel == 0 ? 0 : &l:foldlevel - 1)
    endif
    echo "'foldlevel' = " .. &l:foldlevel
enddef

