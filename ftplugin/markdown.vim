setl fdm=expr fde=Markdown_fold() fdt=Markdown_fold_text()

fu! Markdown_fold_text() abort
    let hash_indent = s:hash_indent(v:foldstart)
    let title       = substitute(getline(v:foldstart), '^#\+\s*', '', '')
    let foldsize    = (v:foldend - v:foldstart + 1)
    let linecount   = '['.foldsize.' lines]'
    return hash_indent.' '.title.' '.linecount
endfu

fu! Markdown_fold() abort
    let line = getline(v:lnum)

    " Regular headers
    let depth = match(line, '\(^#\+\)\@<=\( .*$\)\@=')
    if depth > 0
        return '>'.depth
    endif

    " Setext style headings
    let nextline = getline(v:lnum + 1)
    if (line =~ '^.\+$') && (nextline =~ '^=\+$')
        return '>1'
    endif

    if (line =~ '^.\+$') && (nextline =~ '^-\+$')
        return '>2'
    endif

    return '='
endfu

fu! s:hash_indent(lnum) abort
    let hash_header = matchstr(getline(a:lnum), '^#\{1,6}')
    if len(hash_header) > 0
        " hashtag header
        return hash_header
    else
        " == or -- header
        let nextline = getline(a:lnum + 1)
        if nextline =~ '^=\+\s*$'
            return repeat('#', 1)
        elseif nextline =~ '^-\+\s*$'
            return repeat('#', 2)
        endif
    endif
endfu
