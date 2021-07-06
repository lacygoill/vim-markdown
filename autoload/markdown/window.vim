vim9script noclear

def markdown#window#settings()
    &l:foldminlines = 0
    &l:foldmethod = 'expr'
    &l:foldtext = 'markdown#fold#foldtitle#get()'
    &l:foldexpr = 'markdown#fold#foldexpr#stacked()'
    &l:conceallevel = 2
    &l:concealcursor = 'nc'
enddef

