vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# To install the web server:{{{
#
#     $ sudo aptitude install git nodejs npm
#     $ git clone https://github.com/lacygoill/instant-markdown-d
#     $ cd instant-markdown-d
#     $ npm install
#}}}
const WEB_SERVER: string = $HOME .. '/Vcs/instant-markdown-d/instant-markdown-d'
if !executable(WEB_SERVER)
    echom 'cannot find the web server:   ' .. WEB_SERVER
endif
# If you have an issue, to debug it, you could change the assignment like this:{{{
#
#     var REDIRECTION: string = '>/tmp/log 2>&1 &'
#}}}
const REDIRECTION: string = '>/dev/null 2>&1 &'

def Getlines(): list<string> #{{{1
    var lines: list<string> = getline(1, '$')
    # Inject an invisible marker.{{{
    #
    # The web server will use it to  scroll the window where we've made our last
    # edit.
    # Source:
    #     https://github.com/suan/vim-instant-markdown/pull/74#issue-37422001
    #     https://github.com/suan/instant-markdown-d/pull/26
    #}}}
    lines[line('.') - 1] ..= ' <a name="#marker" id="marker"></a>'
    return lines
enddef

def KillDaemon() #{{{1
    #                 ┌ silent: don't show progress meter or error messages{{{
    #                 │
    #                 │  ┌ specifies  a custom  request method  to use
    #                 │  │ when communicating with the HTTP server
    #                 │  │
    #                 │  │ The  specified request  method  will be  used
    #                 │  │ instead of  the method otherwise  used (which
    #                 │  │ defaults to GET).
    #                 │  │}}}
    sil system('curl -s -X DELETE http://localhost:8090 ' .. REDIRECTION)
    # What's the meaning of the `DELETE` method?{{{
    #
    #    > The DELETE method requests that  the origin server delete the resource
    #    > identified by the Request-URI.
    #
    # Source: https://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html
    #}}}
enddef

def markdown#preview#main() #{{{1
    getline(1, '$')->StartDaemon()
    aug InstantMarkdown
        au! * <buffer>
        au CursorHold,BufWrite,InsertLeave <buffer> Refresh()
        au BufUnload <buffer> KillDaemon()
    aug END
enddef

def Refresh() #{{{1
    if !exists('b:changedtick_last')
        b:changedtick_last = b:changedtick

    elseif b:changedtick_last != b:changedtick
        b:changedtick_last = b:changedtick
        sil system('curl -X PUT -T - http://localhost:8090 ' .. REDIRECTION, Getlines())
        #                    │ │{{{
        #                    │ └ use stdin instead of a given file
        #                    │
        #                    └ transfer the specified local file to the remote URL
        # }}}
    endif
enddef

def StartDaemon(initial_lines: list<string>) #{{{1
    # The markdown preview server can be configured via several environment variables:{{{
    #
    #    ┌─────────────────────────────────────────┬─────────────────────────────────────────────────────────────┐
    #    │ INSTANT_MARKDOWN_OPEN_TO_THE_WORLD=1    │ By default, the server only listens on localhost.           │
    #    │                                         │ To make the server available to others in your network,     │
    #    │                                         │ set this environment variable to a non-empty value.         │
    #    │                                         │ Only use this setting on trusted networks!                  │
    #    ├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
    #    │ INSTANT_MARKDOWN_ALLOW_UNSAFE_CONTENT=1 │ By default, scripts are blocked.                            │
    #    │                                         │ Use this preference to allow scripts.                       │
    #    ├─────────────────────────────────────────┼─────────────────────────────────────────────────────────────┤
    #    │ INSTANT_MARKDOWN_BLOCK_EXTERNAL=1       │ By default, external resources such as images, stylesheets, │
    #    │                                         │ frames and plugins are allowed.                             │
    #    │                                         │ Use this setting to block such external content.            │
    #    └─────────────────────────────────────────┴─────────────────────────────────────────────────────────────┘
    # Source: https://github.com/suan/instant-markdown-d#environment-variables
    #}}}
    # Is it necessary to set this variable?{{{
    #
    # For Vimium to be allowed to work, yes.
    #}}}
    var env: string = 'INSTANT_MARKDOWN_ALLOW_UNSAFE_CONTENT=1'
    var cmd: string = env .. ' ' .. WEB_SERVER .. ' ' .. REDIRECTION
    sil system(cmd, initial_lines)
enddef

