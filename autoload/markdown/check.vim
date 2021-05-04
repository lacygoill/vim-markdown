vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#check#punctuation( #{{{1
    type: string,
    lnum1: number,
    lnum2: number
): string

    if type == '-help'
        h markdown-punctuation
        return ''
    elseif type != '-comma'
        return ''
    endif

    view = winsaveview()
    var fen_save: bool = &l:fen
    var winid: number = win_getid()
    var bufnr: number = bufnr('%')
    &l:fen = false

    try
        # make sure any coordinating conjunction is preceded by a comma
        #    > She wanted to study but she was tired. (✘)
        #    > She wanted to study, but she was tired. (✔)
        var fanboys: list<string> =<< trim END
            for
            and
            nor
            but
            or
            yet
            so
        END
        var pat: string = fanboys->join('\|')
        pat = '\C[^,; \t]\zs\ze\_s\+\%(' .. pat .. '\)\_s\+'

        var range: string = ':' .. lnum1 .. ',' .. lnum2
        cursor(1, 1)
        var items: list<dict<any>>
        var flags: string = 'cW'
        var g: number = 0 | while search(pat, flags) > 0 && g < 999 | ++g
            flags = 'W'
            items += [{
                lnum: line('.'),
                col: col('.'),
                bufnr: bufnr,
                text: getline('.'),
            }]
        endwhile
        # populate the command-line with `:ldo s/\%#/,/c` when we press `C-g s`
        setloclist(0, [], ' ', {
            items: items,
            title: ':CheckPunctuation -comma',
            context: {populate: 'ldo s/\%#/,/c'}
        })
        lw
    finally
        if winbufnr(winid) == bufnr
            var tabnr: number
            var winnr: number
            [tabnr, winnr] = win_id2tabwin(winid)
            settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
        win_execute(winid, 'winrestview(view)')
    endtry
    return ''
enddef
var view: dict<number>

def markdown#check#punctuationComplete(_, _, _) #{{{1
    return ['-comma', '-help']->join("\n")
enddef
