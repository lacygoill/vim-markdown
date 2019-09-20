if exists('g:autoloaded_markdown#preview')
    finish
endif
let g:autoloaded_markdown#preview = 1

" To install the web server:{{{
"
"     $ sudo aptitude install git nodejs npm
"     $ git clone https://github.com/lacygoill/instant-markdown-d
"     $ cd instant-markdown-d
"     $ npm install
"}}}
let s:web_server = $HOME.'/Vcs/instant-markdown-d/instant-markdown-d'
if !executable(s:web_server)
    echom 'cannot find the web server:   '.s:web_server
endif
" If you have an issue, to debug it, you could change the assignment like this:{{{
"
"     let s:redirection = '>/tmp/log 2>&1 &'
"}}}
let s:redirection = '>/dev/null 2>&1 &'

fu! s:getlines() abort "{{{1
    let lines = getline(1, '$')
    " Inject an invisible marker.{{{
    "
    " The web server will use it to  scroll the window where we've made our last
    " edit.
    " Source:
    "     https://github.com/suan/vim-instant-markdown/pull/74#issue-37422001
    "     https://github.com/suan/instant-markdown-d/pull/26
    "}}}
    let lines[line('.')-1] .= ' <a name="#marker" id="marker"></a>'
    return lines
endfu

fu! s:kill_daemon() abort "{{{1
    "                      ┌ silent: don't show progress meter or error messages{{{
    "                      │
    "                      │  ┌ specifies  a custom  request method  to use
    "                      │  │ when communicating with the HTTP server
    "                      │  │
    "                      │  │ The  specified request  method  will be  used
    "                      │  │ instead of  the method otherwise  used (which
    "                      │  │ defaults to GET).
    "                      │  │}}}
    sil call system('curl -s -X DELETE http://localhost:8090 '.s:redirection)
    " What's the meaning of the `DELETE` method?{{{
    "
    " >   The DELETE method requests that  the origin server delete the resource
    " >   identified by the Request-URI.
    "
    " Source:
    "     https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    "}}}
endfu

fu! markdown#preview#main() abort "{{{1
    call s:start_daemon(getline(1, '$'))
    aug instant-markdown
        au! * <buffer>
        au CursorHold,BufWrite,InsertLeave <buffer> call s:refresh()
        au BufUnload <buffer> call s:kill_daemon()
    aug END
endfu

fu! s:refresh() abort "{{{1
    if !exists('b:changedtick_last')
        let b:changedtick_last = b:changedtick

    elseif b:changedtick_last != b:changedtick
        let b:changedtick_last = b:changedtick
        sil call system('curl -X PUT -T - http://localhost:8090 '.s:redirection, s:getlines())
        "                         │ │{{{
        "                         │ └ use stdin instead of a given file
        "                         │
        "                         └ transfer the specified local file to the remote URL
        " }}}
    endif
endfu

fu! s:start_daemon(initial_lines) abort "{{{1
    " The markdown preview server can be configured via several environment variables:{{{
    "
    "   ┌─────────────────────────────────────────┬─────────────────────────────────────────────────────────────┐
    "   │ INSTANT_MARKDOWN_OPEN_TO_THE_WORLD=1    │ By default, the server only listens on localhost.           │
    "   │                                         │ To make the server available to others in your network,     │
    "   │                                         │ set this environment variable to a non-empty value.         │
    "   │                                         │ Only use this setting on trusted networks!                  │
    "   ├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
    "   │ INSTANT_MARKDOWN_ALLOW_UNSAFE_CONTENT=1 │ By default, scripts are blocked.                            │
    "   │                                         │ Use this preference to allow scripts.                       │
    "   ├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
    "   │ INSTANT_MARKDOWN_BLOCK_EXTERNAL=1       │ By default, external resources such as images, stylesheets, │
    "   │                                         │ frames and plugins are allowed.                             │
    "   │                                         │ Use this setting to block such external content.            │
    "   └─────────────────────────────────────────┴─────────────────────────────────────────────────────────────┘
    " Source:
    "     https://github.com/suan/instant-markdown-d#environment-variables
    "
"}}}
    " Is it necessary to set this variable?{{{
    "
    " For Vimium to be allowed to work, yes.
    "}}}
    let env = 'INSTANT_MARKDOWN_ALLOW_UNSAFE_CONTENT=1'
    sil call system(env.' '.s:web_server.' '.s:redirection, a:initial_lines)
endfu

