vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#foldtitle#get(): string #{{{1
    var foldstartline = getline(v:foldstart)
    # get the desired level of indentation for the title
    var level = markdown#fold#foldexpr#headingDepth(v:foldstart)
    var indent = repeat(' ', (level - 1) * 3)
    # remove noise
    var title = substitute(foldstartline, '^#\+\s*\|`', '', 'g')
    if get(b:, 'foldtitle_full', false)
        var foldsize = (v:foldend - v:foldstart)
        var linecount = '[' .. foldsize .. ']' .. repeat(' ', 4 - strlen(foldsize))
        return indent .. (foldsize > 1 ? linecount : '') .. title
    else
        return indent .. title
    endif
enddef

