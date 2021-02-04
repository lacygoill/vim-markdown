vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def markdown#fold#how_many#print() #{{{2
    if foldclosed('.') == -1
        var first_line: number = search('^#', 'bcnW')
        var last_line: number = search('^#\|\%$', 'cnW')
        echo last_line - first_line - 1
        return
    endif

    var view: dict<number> = winsaveview()
    current_lvl = GetCurrentLvl()

    # get the number of folds with the same level,
    # and in the same block of consecutive folds
    MoveToFirstFold(1)
    var msg_first_part: number = GetNumberOfFolds(1)
    winrestview(view)

    # get the number of folds with the same level,
    # and the same parent fold
    MoveToFirstFold(2)
    var msg_second_part: number = GetNumberOfFolds(2)
    winrestview(view)

    echo msg_first_part .. ', ' .. msg_second_part
enddef
var current_lvl: number
# }}}1
# Core {{{1
def MoveToFirstFold(n: number) #{{{2
    var pat: string
    if n == 1
        pat = current_lvl == 1
            ? '^#\+$\n\zs\|\%^'
            : '^#\+$\n\zs\|^#\{' .. (current_lvl - 1) .. '}#\@!\s\S\+.*\n\zs\|\%^'
    else
        pat = current_lvl == 1
            ? '^\%(#\+\n\|\%^\)\zs#\s\S\+'
            : '^#\{' .. (current_lvl - 1) .. '}#\@!'
    endif
    search(pat, 'bcW')
enddef

def GetNumberOfFolds(n: number): number #{{{2
    var pat: string = current_lvl == 1
        ? '^#\+$\|\%$'
        : (n == 1 ? '^#\+$\|' : '') .. '^#\{' .. (current_lvl - 1) .. '}#\@!\|\%$'

    var first_line_last_fold: number = search(pat, 'nW')
    var cnt: number = 0
    while cnt < 999 && line('.') < first_line_last_fold
        search('^#\{' .. current_lvl .. '}#\@!\s\S\+\|\%$', 'W')
        cnt += 1
    endwhile

    return (n == 1 ? cnt : cnt - 1)
enddef
#}}}1
# Utility {{{1
def GetCurrentLvl(): number #{{{2
    var pat: string = '^#\+\ze\s\+'
    var first_line: number = search(pat, 'bcnW')
    return getline(first_line)->matchstr(pat)->strlen()
enddef

