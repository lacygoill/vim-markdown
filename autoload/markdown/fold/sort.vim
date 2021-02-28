vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#sort#by_size(lnum1: number, lnum2: number) #{{{1
    # get the level of the first fold
    var lvl: number = getline(lnum1)->matchstr('^#*')->strlen()
    if lvl == 0
        echohl ErrorMsg
        echo 'The first line is not a fold title'
        echohl NONE
        return
    endif

    # disable folding, because it could badly interfere when we move lines with `:m`
    var fen_save: bool = &l:fen
    var winid: number = win_getid()
    var bufnr: number = bufnr('%')
    [fen_save, winid, bufnr] = [&l:fen, win_getid(), bufnr('%')]
    &l:fen = false
    try
        # What's this?{{{
        #
        # A pattern describing the end of a fold.
        # To be more accurate, its last newline or the end of the buffer.
        #}}}
        # Why \{1,lvl}?{{{
        #
        # We mustn't stop when we find a fold whose level is bigger than `lvl`.
        # Those are children folds; they should be ignored.
        # Thus, the quantifier must NOT go beyond `lvl`.
        #
        # Also, we must stop if we find a fold whose level is smaller.
        # Those are parents.
        # Thus, the quantifier *must* go below `lvl`.
        #
        #}}}
        var pat: string = '\n\%(#\{1,' .. lvl .. '}#\@!\)\|\%$'

        cursor(lnum1, 1)

        # search the end of the first fold
        var foldend: number = search(pat, 'W', lnum2)
        if foldend == 0
            return
        endif
        # What's this?{{{
        #
        # We begin populating the list `folds`.
        # Each item in this list is a dictionary with three keys:
        #
        #    - foldstart:    first line in the fold
        #    - foldend:      last line in the fold
        #    - size:         size of the fold
        #}}}
        var folds: list<dict<number>> = [{
            foldstart: lnum1,
            foldend: foldend,
            size: foldend - lnum1 + 1,
            }]
        # What does the loop do?{{{
        #
        #    1. it looks for the end of the next fold with the same level
        #
        #    2. it populates the list `folds` with info about this new current fold
        #
        #    3. every time it finds a previous fold which is bigger
        #       than the current one:
        #
        #        - it moves the latter above
        #        - it re-calls the function to continue the process
        #}}}
        while foldend > 0
            for f in folds
                # if you find a previous fold which is bigger
                if f.size > folds[-1]['size']
                    # move last fold above
                    sil exe printf(':%d,%dm %d',
                        folds[-1]['foldstart'],
                        folds[-1]['foldend'],
                        f.foldstart - 1)
                    markdown#fold#sort#by_size(lnum1, lnum2)
                    return
                endif
            endfor

            var orig_lnum: number = line('.')
            foldend = search(pat, 'W', lnum2)
            #                                          ┌ stop if you've found a fold whose level is < `lvl`
            #                                          │
            if foldend == 0 || getline(orig_lnum + 1)->match('^\%(#\{' .. (lvl - 1) .. '}#\@!\)') == 0
                break
            endif
            folds += [{
                foldstart: orig_lnum + 1,
                foldend: foldend,
                size: foldend - orig_lnum,
                }]
        endwhile
    finally
        if winbufnr(winid) == bufnr
            var tabnr: number
            var winnr: number
            [tabnr, winnr] = win_id2tabwin(winid)
            settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
    endtry
enddef

