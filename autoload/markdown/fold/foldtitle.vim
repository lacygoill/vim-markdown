vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#fold#foldtitle#get(): string #{{{1
    var foldstartline: string = getline(v:foldstart)
    # get the desired level of indentation for the title
    var level: number = markdown#fold#foldexpr#headingDepth(v:foldstart)
    var indent: string = repeat(' ', (level - 1) * 3)
    # remove noise
    var title: string = foldstartline->substitute('^#\+\s*\|`', '', 'g')
    if get(b:, 'foldtitle_full', false)
        var foldsize: number = (v:foldend - v:foldstart)
        var linecount: string = '[' .. foldsize .. ']' .. repeat(' ', 4 - strlen(foldsize))
        return indent .. (foldsize > 1 ? linecount : '') .. title
    else
        return indent .. title
    endif
enddef

