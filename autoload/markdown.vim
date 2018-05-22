fu! markdown#include() abort "{{{1
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the names mentioned in `b:markdown_fenced_languages`,
    " and for each of them, include the corresponding syntax plugin.
    "}}}
    " If `b:markdown_fenced_languages` contains `javascript=js`, what does it mean?{{{
    "
    " It means we want any fenced block beginning with the line:
    "
    "     ```javascript
    "
    " ... to be highlighted with the `js` syntax plugin.
    "
    " https://github.com/ixandidu/vim-markdown/commit/16157135e794598c46f38b2167f41c124c7dcccb#commitcomment-20485418
    "}}}
    " Why `map(..., ... matchstr() ...)`?{{{
    "
    " If the text contains an equal sign:
    "
    "       javascript=js
    "
    " ... we're only interested in what's after (here `js`).
    " Because the name of the syntax plugin we need to source is after.
    "}}}
    let done_include = {}
    for item in map(copy(get(b:, 'markdown_fenced_languages', [])), {i,v -> matchstr(v, '[^=]*$')})
        let ft = matchstr(item,'[^.]*')
        if has_key(done_include, ft)
            continue
        endif
        exe 'syn include @markdownHighlight'.substitute(item,'\.','','g').' syntax/'.ft.'.vim'
        unlet! b:current_syntax
        let done_include[ft] = 1
    endfor
endfu

