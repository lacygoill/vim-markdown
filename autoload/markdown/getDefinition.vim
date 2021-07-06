vim9script noclear

def markdown#getDefinition#main()
    var word: string
    if mode() =~ "^[vV\<C-V>]$"
        normal! gvy
        word = @"
    else
        word = expand('<cWORD>')
    endif
    word = word
        ->substitute('[“(]\|[”)].*\|[.?s]\{,2}$', '', 'g')
    var fname: string = expand('%:p:t')
    if fname != 'glossary.md'
        var cwd: string = getcwd()
        execute 'split ' .. cwd .. '/glossary.md'
    endif
    var pat: string = '^#.*\c\V' .. escape(word, '\')
    var items: list<dict<any>> = getline(1, '$')
        ->mapnew((i: number, v: string): dict<any> =>
                    ({bufnr: bufnr('%'), lnum: i + 1, text: v}))
        ->filter((_, v: dict<any>): bool => v.text =~ pat)
    if empty(items)
        echomsg 'no definition for ' .. word
        if fname != 'glossary.md'
            quit
        endif
        return
    else
        # erase possible previous 'no definition for' message
        redraw!
    endif
    setloclist(0, [], ' ', {items: items, title: word})
    lwindow
    if &filetype == 'qf'
        lfirst
        normal! zMzvzz
    endif
enddef

