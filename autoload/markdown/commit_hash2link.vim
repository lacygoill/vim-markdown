fu markdown#commit_hash2link#main(line1, line2, pgm) abort
    let pgm2url = {
        \ 'vim' : 'https://github.com/vim/vim/commit/',
        \ 'tmux': 'https://github.com/tmux/tmux/commit/',
        \ }
    if !has_key(pgm2url, a:pgm)
        echom 'CommitHash2Link: ' .. a:pgm .. ' is not supported'
        return
    endif
    let url = pgm2url[a:pgm]
    let range = a:line1 .. ',' .. a:line2
    exe range .. 's;\(\x\{7}\)\x\+;[`\1`](' .. url .. '&);'
endfu

fu markdown#commit_hash2link#completion(_a, _l, _p) abort
    return join(['tmux', 'vim'], "\n")
endfu

