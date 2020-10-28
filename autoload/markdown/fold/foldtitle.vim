fu markdown#fold#foldtitle#get() abort "{{{1
    let foldstartline = getline(v:foldstart)
    " get the desired level of indentation for the title
    let level = markdown#fold#foldexpr#heading_depth(v:foldstart)
    let indent = repeat(' ', (level - 1) * 3)
    " remove noise
    let title = substitute(foldstartline, '^#\+\s*\|`', '', 'g')
    if get(b:, 'foldtitle_full', 0)
        let foldsize = (v:foldend - v:foldstart)
        let linecount = '[' .. foldsize .. ']' .. repeat(' ', 4 - strlen(foldsize))
        return indent .. (foldsize > 1 ? linecount : '') .. title
    else
        return indent .. title
    endif
endfu

