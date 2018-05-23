fu! markdown#define_cluster() abort "{{{1
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
    "       js=javascript
    "
    " ... we're only interested in what's after (here `javascript`).
    " Because that's the name of the syntax plugin we need to source.
    "}}}
    let done_include = {}
    " `item` is the text after a possible equal sign.
    for item in map(copy(get(b:, 'markdown_fenced_languages', [])), {i,v -> matchstr(v, '[^=]*$')})
        let ft = matchstr(item,'[^.]*')
        if has_key(done_include, ft)
            continue
        endif
        exe 'syn include @markdownHighlight'.item.' syntax/'.ft.'.vim'
        " We need to remove `b:current_syntax` to be sure the next syntax plugin
        " can be sourced, even if it has a guard.
        unlet! b:current_syntax
        let done_include[ft] = 1
    endfor
endfu

fu! markdown#use_cluster() abort "{{{1
    let done_include = {}
    for type in get(b:, 'markdown_fenced_languages', [])
        if has_key(done_include, matchstr(type,'[^.]*'))
            continue
        endif
        exe 'syn region markdownHighlight'.substitute(matchstr(type,'[^=]*$'),'\..*','','')
        \ . ' matchgroup=markdownCodeDelimiter'
        \ . ' start="^\s*````*\s*'.matchstr(type,'[^=]*').'\S\@!.*$"'
        \ . ' end="^\s*````*\ze\s*$"'
        \ . ' keepend'
        \ . ' contains=@markdownHighlight'.substitute(matchstr(type,'[^=]*$'),'\.','','g')
        let done_include[matchstr(type,'[^.]*')] = 1
    endfor
endfu

