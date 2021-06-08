vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#window#settings()
    &l:foldminlines = 0
    &l:foldmethod = 'expr'
    &l:foldtext = 'markdown#fold#foldtitle#get()'
    &l:foldexpr = 'markdown#fold#foldexpr#stacked()'
    &l:conceallevel = 2
    &l:concealcursor = 'nc'
enddef

