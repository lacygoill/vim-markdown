" Interface {{{1
fu! markdown#define_include_clusters() abort "{{{2
    " What's the purpose of this `for` loop?{{{
    "
    " Iterate over the  languages mentioned in `b:markdown_embed`,  and for each
    " of them, include the corresponding syntax plugin.
    "}}}
    " If `b:markdown_embed` contains `javascript=js`, what does it mean?{{{
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
    let filetypes = map(copy(get(b:, 'markdown_embed', [])), {i,v -> matchstr(v, '[^=]*$')})
    for ft in filetypes
        " If by accident, we wrote the  same embedded language several times, we
        " want to include the corresponding syntax plugin only once.
        if has_key(done_include, ft)
            continue
        endif

        " What's the effect of `:syn include`?{{{
        "
        " If you execute:
        "
        "     syn include @markdownEmbedhtml syntax/html.vim
        "
        " Vim will install all items from  all html syntax plugins, and for each
        " of them, it will add the argument `contained`.
        " It means  that the item will  only match if it's  contained in another
        " one, which has the argument `contains=@markdownEmbedhtml`.
        "}}}
        " Why `:silent!`?{{{
        "
        " Necessary if you write something like this in `ftplugin/markdown.vim`:
        "
        "     :let b:markdown_embed = ['js=javascript']
        "}}}
        sil! exe 'syn include @markdownEmbed'.ft.' syntax/'.ft.'.vim'

        " We need to remove `b:current_syntax` to be sure the next syntax plugin
        " can be sourced, even if it has a guard.
        unlet! b:current_syntax
        let done_include[ft] = 1
    endfor
endfu

fu! markdown#highlight_embedded_languages() abort "{{{2
    let done_include = {}
    for item in get(b:, 'markdown_embed', [])
        if has_key(done_include, item)
            continue
        endif
        let ft = matchstr(item,'[^=]*$')
        let delim = matchstr(item,'[^=]*')
        " Note that the name of the region is identical to the name of the cluster:{{{
        "
        "     'markdownEmbed'.ft
        "
        " But there's no conflict.
        " Probably because a cluster name is always prefixed by `@`.
        "}}}
        exe 'syn region markdownEmbed'.ft
        \ . ' matchgroup=markdownCodeDelimiter'
        \ . ' start="^\s*````*\s*'.delim.'\S\@!.*$"'
        \ . ' end="^\s*````*\ze\s*$"'
        \ . ' keepend'
        \ . ' concealends'
        \ . ' contains=@markdownEmbed'.ft
        let done_include[item] = 1
    endfor
endfu

