vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#get_definition#main()
    var word: string
    if mode() =~ "^[vV\<c-v>]$"
        norm! gvy
        word = @"
    else
        word = expand('<cWORD>')
    endif
    word = substitute(word, '[“(]\|[”)].*\|[.?s]\{,2}$', '', 'g')
    var fname = expand('%:p:t')
    if fname != 'glossary.md'
        var cwd = getcwd()
        exe 'sp ' .. cwd .. '/glossary.md'
    endif
    var pat = '^#.*\c\V' .. escape(word, '\')
    var items = getline(1, '$')
        ->mapnew((i, v) => ({bufnr: bufnr('%'), lnum: i + 1, text: v}))
        ->filter((_, v) => v.text =~ pat)
    if empty(items)
        echom 'no definition for ' .. word
        if fname != 'glossary.md'
            q
        endif
        return
    else
        # erase possible previous 'no definition for' message
        redraw!
    endif
    setloclist(0, [], ' ', {items: items, title: word})
    lw
    if &ft == 'qf'
        lfirst
        norm! zMzvzz
    endif
enddef

