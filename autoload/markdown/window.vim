vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

def markdown#window#settings()
    setl fml=0
    setl fdm=expr
    setl fdt=markdown#fold#foldtitle#get()
    setl fde=markdown#fold#foldexpr#stacked()
    setl cole=2
    setl cocu=nc
enddef

