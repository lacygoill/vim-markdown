vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#commit_hash2link#main(...l: list<any>)
    if l[0] == 1 && l[1] == line('$') && l[2] == ''
        var help =<< trim END
            While the cursor is on a line such as:

                5a2db4c7e8ba94fadb31075e6813cf53b87b5366

            Execute ":CommitHash2Link tmux", and you should get:

                [`5a2db4c`](https://github.com/tmux/tmux/commit/5a2db4c7e8ba94fadb31075e6813cf53b87b5366)
        END
        echom help->join("\n")
        return
    endif

    var line1 = l[0]
    var line2 = l[1]
    var pgm = l[2]

    if pgm == ''
        echom 'Need to provide the name of a program (e.g. tmux)'
        echom 'Run ":CommitHash2Link" without arguments for more help'
        return
    endif

    var pgm2url = {
        vim: 'https://github.com/vim/vim/commit/',
        tmux: 'https://github.com/tmux/tmux/commit/',
        }
    if !has_key(pgm2url, pgm)
        echom 'CommitHash2Link: ' .. pgm .. ' is not supported'
        return
    endif
    var url = pgm2url[pgm]
    var range = ':' .. line1 .. ',' .. line2
    exe range .. 's;\(\x\{7}\)\x\+;[`\1`](' .. url .. '&);e'
enddef

def markdown#commit_hash2link#completion(...l: any): string
    return join(['tmux', 'vim'], "\n")
enddef

