vim9 noclear

if exists('loaded') | finish | endif
var loaded = true

# Init

# `:LinkInline2Ref` won't work as expected if the buffer contains more than `GUARD` links.
# This guard is useful to avoid being stuck in an infinite loop.
const GUARD = 1000
const REF_SECTION = '# Reference'

# Interface {{{1
def markdown#link_inline2ref#main() #{{{2
    var view = winsaveview()
    var syntax_was_enabled = exists('g:syntax_on')
    if !syntax_was_enabled
        syn enable
    endif

    var fen_save = &l:fen
    var winid = win_getid()
    var bufnr = bufnr('%')
    &l:fen = false

    try
        # Make sure syntax highlighting is enabled.
        # `:argdo`, `:bufdo`, ... could disable it (e.g. `:argdo LinkInline2Ref`).
        &ei = ''
        do Syntax

        # We're going to inspect the syntax highlighting under the cursor.
        # Sometimes, it's wrong.
        # We must be sure it's correct.
        syn sync fromstart

        # Make sure there's no link whose description span multiple lines.
        # Those kind of links are too difficult to handle.
        if MultiLineLinks()
            return
        endif

        if !MarkdownLinkSyntaxGroupExists()
            echohl ErrorMsg
            echom 'The function relies on the syntax group ‘markdownLink’; but it doesn''t exist'
            echohl NONE
            return
        endif

        MakeSureReferenceSectionExists()
        if IdOutsideReferenceSection()
            return
        endif

        var id2url = CreateReflinks()
        PopulateReferenceSection(id2url)
    finally
        if winbufnr(winid) == bufnr
            var tabnr: number
            var winnr: number
            [tabnr, winnr] = win_id2tabwin(winid)
            settabwinvar(tabnr, winnr, '&fen', fen_save)
        endif
        if !syntax_was_enabled
            syn off
        endif
        winrestview(view)
    endtry
enddef
# }}}1
# Core {{{1
def CreateReflinks(): dict<string> #{{{2
    cursor(1, 1)
    var id = 1
    var id2url: dict<string> = {}
    var flags = 'cW'
    while search('\[.\{-}]\zs\%(\[\d\+]\|(.\{-})\)', flags) > 0 && id < GUARD
        flags = 'W'
        var line = getline('.')
        var col = col('.')
        var char_under_cursor = matchstr(line, '\%' .. col .. 'c.')
        # [some text][some id]
        if char_under_cursor == '['
            var old_id = matchstr(line, '\%' .. col .. 'c\[\zs\d\+\ze]')
            var url = GetUrl(old_id)
            # update id{{{
            #
            # For example, if the first reference link we find is:
            #
            #     [some text][3]
            #
            # We should renumber it with 1:
            #
            #     [some text][1]
            #}}}
            var new_line = substitute(line, '\%' .. col .. 'c\[\d\+', '[' .. id, '')
            # Do *not* use `:s`!{{{
            #
            # It would make the cursor move which would fuck everything up.
            #}}}
            setline('.', new_line)
            id2url[id] = url

        # [some text](some url)
        elseif char_under_cursor == '('
            if !IsARealLink()
                continue
            endif
            var url = GetUrl()
            norm! %
            var col_end = col('.')
            norm! %
            var new_line = substitute(line, '\%' .. col .. 'c(.*\%' .. col_end .. 'c)', '[' .. id .. ']', '')
            setline('.', new_line)
            id2url[id] = url
        endif
        id += 1
    endwhile
    return id2url
enddef

def PopulateReferenceSection(id2url: dict<string>) #{{{2
    search('^' .. REF_SECTION .. '$')
    if search('^\[\d\+]:') == 0
        norm! G
    endif
    sil keepj keepp :.,$g/^\[\d\+]:/d _
    # Why don't you simply use `n` as the second argument of `sort()`, to get a numerical sort?{{{
    #
    # From `:h sort()`:
    #
    #    > Implementation detail: This  uses the strtod() function  to parse numbers,
    #    > **Strings**, Lists, Dicts and Funcrefs **will be considered as being 0**.
    #}}}
    var lines = mapnew(id2url, (k: string, v: string) => '[' .. k .. ']: ' .. v)
        ->values()
        ->sort((a: string, b: string) =>
            matchstr(a, '\d\+')->str2nr() - matchstr(b, '\d\+')->str2nr())
    append('.', lines)
    sil exe 'keepj keepp :%s/^' .. REF_SECTION .. '\n\n\zs\n//e'
enddef
# }}}1
# Util {{{1
def GetUrl(id = 0): string #{{{2
    if id != 0
        return search('^\[' .. id .. ']:', 'n')
            ->getline()
            ->matchstr(':\s*\zs.*')
    else
        # Do *not* use `norm! %`!{{{
        #
        # It would make the cursor move, which could cause an issue.
        # Suppose there're two inline links on the same line.
        #
        #     [text](long url) [other text](other url)
        #                    ^
        #                    cursor position, because of `%`
        #
        # Later, we'll convert the first link into a reference:
        #
        #     [text][123] [other text](other url)
        #                    ^
        #                    cursor position, same as before, thanks to `setline()`
        #
        # Since  the  absolute  cursor  position  didn't  change,  the  position
        # relative to the second link will  change, and it's possible that we're
        # now after its start; in that case, we'll miss it.
        #}}}
        norm! v%y
        return substitute(@", '^(\|)$\|\s', '', 'g')
    endif
enddef

def IdOutsideReferenceSection(): bool #{{{2
    var ref_section_lnum = search('^' .. REF_SECTION .. '$', 'n')
    if search('^\[\d\+]:', 'n', ref_section_lnum)
        sil exe 'lvim /^\[\d\+]:\%<' .. ref_section_lnum .. 'l/j %'
        echom 'There are id declarations outside the Reference section'
        setloclist(0, [], 'a', {title: 'move them inside or remove/edit them'})
        return true
    endif
    return false
enddef

def IsARealLink(): bool #{{{2
    return synstack('.', col('.'))
        ->mapnew((_, v) => synIDattr(v, 'name'))
        ->reverse()
        ->match('^markdownLink') >= 0
enddef

def MakeSureReferenceSectionExists() #{{{2
    var ref_section_lnum = search('^' .. REF_SECTION .. '$', 'n')
    if ref_section_lnum == 0
        append('$', ['', '##', REF_SECTION, ''])
        #            ├┘{{{
        #            └ necessary if the last line of the buffer is a list item;
        #              otherwise the reference section would be wrongly highlighted
        #              as a list
        #}}}
    endif
enddef

def MarkdownLinkSyntaxGroupExists(): bool #{{{2
    try
        sil syn list markdownLink
    catch /^Vim\%((\a\+)\)\=:E28:/
        return false
    endtry
    return true
enddef

def MultiLineLinks(): bool #{{{2
    cursor(1, 1)
    var pat = '\[[^][]*\n\_[^][]*](.*)'
    var flags = 'cW'
    var g = 0 | while search(pat, flags) > 0 && g <= GUARD | g += 1
        flags = 'W'
        if IsARealLink()
            exe 'lvim /' .. pat .. '/gj %'
            setloclist(0, [], 'a',
                {title: 'some descriptions of links span multiple lines; make them mono-line'})
            return true
        endif
    endwhile
    return false
enddef

