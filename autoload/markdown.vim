fu! markdown#fold_text() abort "{{{1
    let level  = s:heading_depth(v:foldstart)
    let indent = repeat(' ', (level-1)*3)
    let title  = substitute(getline(v:foldstart), '^#\+\s*', '', '')

    if get(b:, 'my_title_full', 0)
        let foldsize  = (v:foldend - v:foldstart)
        let linecount = '['.foldsize.']'.repeat(' ', 4 - strchars(foldsize))
        return indent.' '.linecount.' '.title
    else
        return indent.' '.title
    endif
endfu

" has_surrounding_fencemarks {{{1

" disabled

" fu! s:has_surrounding_fencemarks(lnum) abort
"     let pos = [line('.'), col('.')]
"     call cursor(a:lnum, 1)
"
"     let start_fence    = '\%^```\|^\n\zs```'
"     let end_fence      = '```\n^$'
"     let fence_position = searchpairpos(start_fence, '', end_fence, 'W')
"
"     call cursor(pos)
"     return fence_position != [0,0]
" endfu

" has_syntax_group {{{1

" disabled

" fu! s:has_syntax_group(lnum) abort
"     let syntax_groups = map(synstack(a:lnum, 1), { k,v -> synIDattr(v, 'name') })
"     for value in syntax_groups
"         if value =~ '\vmarkdown%(Code|Highlight)'
"             return 1
"         endif
"     endfor
" endfu

fu! s:heading_depth(lnum) abort "{{{1
    let level     = 0
    let thisline  = getline(a:lnum)
    let hashCount = len(matchstr(thisline, '^#\{1,6}'))

    if hashCount > 0
        let level = hashCount
    else
        if thisline != ''
            let nextline = getline(a:lnum + 1)
            if nextline =~ '^=\+\s*$'
                let level = 1
            elseif nextline =~ '^-\+\s*$'
                let level = 2
            endif
        endif
    endif
    " temporarily commented because it makes us gain 0.5 seconds when loading
    " Vim notes
    "         if level > 0 && s:line_is_fenced(a:lnum)
    "             " Ignore # or === if they appear within fenced code blocks
    "             return 0
    "         endif
    return level
endfu

" line_is_fenced {{{1

" disabled

" fu! s:line_is_fenced(lnum) abort
"     if get(b:, 'current_syntax', '') ==# 'markdown'
"         " It's cheap to check if the current line has 'markdownCode' syntax group
"         return s:has_syntax_group(a:lnum)
"     else
"         " Using searchpairpos() is expensive, so only do it if syntax highlighting
"         " is not enabled
"         return s:has_surrounding_fencemarks(a:lnum)
"     endif
" endfu

fu! markdown#nested() abort "{{{1
    let depth = s:heading_depth(v:lnum)
    if depth > 0
        return '>'.depth
    else
        return '='
    endif
endfu

fu! markdown#stacked() abort "{{{1
    if s:heading_depth(v:lnum) > 0
        return '>1'
    else
        return '='
    endif
endfu

fu! markdown#toggle_foldexpr() abort "{{{1
    if &l:fde ==# 'markdown#stacked()'
        let &l:fde = 'markdown#nested()'
    else
        let &l:fde = 'markdown#stacked()'
    endif
endfu
