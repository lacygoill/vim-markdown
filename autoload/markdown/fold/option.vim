fu markdown#fold#option#fdl(choice) abort
    if &l:fde !~# 'nested'
        echo "the folds are not nested; change 'fde' first"
        return
    endif

    if a:choice is# 'more'
        let &l:fdl += 1
    else
        let &l:fdl = (&l:fdl == 0 ? 0 : &l:fdl - 1)
    endif
    echo "'fdl' = "..&l:fdl
endfu

