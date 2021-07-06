vim9script noclear

def markdown#commitHash2link#main(...l: list<any>)
    if l[0] == 1 && l[1] == line('$') && l[2] == ''
        var help: list<string> =<< trim END
            While the cursor is on a line such as:

                5a2db4c7e8ba94fadb31075e6813cf53b87b5366

            Execute ":CommitHash2Link tmux", and you should get:

                [`5a2db4c`](https://github.com/tmux/tmux/commit/5a2db4c7e8ba94fadb31075e6813cf53b87b5366)
        END
        echo help->join("\n")
        return
    endif

    var line1: number = l[0]
    var line2: number = l[1]
    var pgm: string = l[2]

    if pgm == ''
        echomsg 'Need to provide the name of a program (e.g. tmux)'
        echomsg 'Run ":CommitHash2Link" without arguments for more help'
        return
    endif

    var pgm2url: dict<string> = {
        vim: 'https://github.com/vim/vim/commit/',
        tmux: 'https://github.com/tmux/tmux/commit/',
    }
    if !pgm2url->has_key(pgm)
        echomsg 'CommitHash2Link: ' .. pgm .. ' is not supported'
        return
    endif
    var url: string = pgm2url[pgm]
    var range: string = ':' .. line1 .. ',' .. line2
    execute range .. ' substitute;\(\x\{7}\)\x\+;[`\1`](' .. url .. '&);e'
enddef

def markdown#commitHash2link#completion(_, _, _): string
    return ['tmux', 'vim']->join("\n")
enddef

