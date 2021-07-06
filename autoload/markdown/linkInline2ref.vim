vim9script noclear

# Init

# `:LinkInline2Ref` won't work as expected if the buffer contains more than `GUARD` links.
# This guard is useful to avoid being stuck in an infinite loop.
const GUARD: number = 1'000
const REF_SECTION: string = '# Reference'

# Interface {{{1
def markdown#linkInline2ref#main() #{{{2
    var view: dict<number> = winsaveview()
    var syntax_was_enabled: bool = exists('g:syntax_on')
    if !syntax_was_enabled
        syntax enable
    endif

    var foldenable_save: bool = &l:foldenable
    var winid: number = win_getid()
    var bufnr: number = bufnr('%')
    &l:foldenable = false

    try
        # Make sure syntax highlighting is enabled.
        # `:argdo`, `:bufdo`, ... could disable it (e.g. `:argdo LinkInline2Ref`).
        var eventignore_save: string = &eventignore
        &eventignore = ''
        doautocmd Syntax
        &eventignore = eventignore_save

        # We're going to inspect the syntax highlighting under the cursor.
        # Sometimes, it's wrong.
        # We must be sure it's correct.
        syntax sync fromstart

        # Make sure there's no link whose description span multiple lines.
        # Those kind of links are too difficult to handle.
        if MultiLineLinks()
            return
        endif

        if !MarkdownLinkSyntaxGroupExists()
            echohl ErrorMsg
            echomsg 'The function relies on the syntax group ‘markdownLink’; but it doesn''t exist'
            echohl NONE
            return
        endif

        MakeSureReferenceSectionExists()
        if IdOutsideReferenceSection()
            return
        endif

        var id2url: dict<string> = CreateReflinks()
        PopulateReferenceSection(id2url)
    finally
        if winbufnr(winid) == bufnr
            var tabnr: number
            var winnr: number
            [tabnr, winnr] = win_id2tabwin(winid)
            settabwinvar(tabnr, winnr, '&foldenable', foldenable_save)
        endif
        if !syntax_was_enabled
            syntax off
        endif
        winrestview(view)
    endtry
enddef
# }}}1
# Core {{{1
def CreateReflinks(): dict<string> #{{{2
    cursor(1, 1)
    var id: number = 1
    var id2url: dict<string>
    var flags: string = 'cW'
    while search('\[.\{-}]\zs\%(\[\d\+]\|(.\{-})\)', flags) > 0 && id < GUARD
        flags = 'W'
        var line: string = getline('.')
        var col: number = col('.')
        var char_under_cursor: string = line[charcol('.') - 1]
        # [some text][some id]
        if char_under_cursor == '['
            var old_id: string = line->matchstr('\%' .. col .. 'c\[\zs\d\+\ze]')
            var url: string = GetUrl(old_id)
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
            line
                ->substitute('\%' .. col .. 'c\[\d\+', '[' .. id, '')
                # Do *not* use `:s`!{{{
                #
                # It would make the cursor move which would fuck everything up.
                #}}}
                ->setline('.')
            id2url[id] = url

        # [some text](some url)
        elseif char_under_cursor == '('
            if !IsARealLink()
                continue
            endif
            var url: string = GetUrl()
            normal! %
            var col_end: number = col('.')
            normal! %
            var new_line: string = line
                ->substitute(
                    '\%' .. col .. 'c(.*\%' .. col_end .. 'c)',
                    '[' .. id .. ']',
                    ''
                )
            setline('.', new_line)
            id2url[id] = url
        endif
        ++id
    endwhile
    return id2url
enddef

def PopulateReferenceSection(id2url: dict<string>) #{{{2
    search('^' .. REF_SECTION .. '$')
    if search('^\[\d\+]:') == 0
        normal! G
    endif
    silent keepjumps keeppatterns :.,$ global/^\[\d\+]:/delete _
    # Why don't you simply use `n` as the second argument of `sort()`, to get a numerical sort?{{{
    #
    # From `:help sort()`:
    #
    #    > Implementation detail: This  uses the strtod() function  to parse numbers,
    #    > **Strings**, Lists, Dicts and Funcrefs **will be considered as being 0**.
    #}}}
    var lines: list<string> = id2url
        ->mapnew((k: string, v: string) => '[' .. k .. ']: ' .. v)
        ->values()
        ->sort((a: string, b: string): number =>
                a->matchstr('\d\+')->str2nr() - b->matchstr('\d\+')->str2nr())
    append('.', lines)
    execute 'silent keepjumps keeppatterns :% substitute/^' .. REF_SECTION .. '\n\n\zs\n//e'
enddef
# }}}1
# Util {{{1
def GetUrl(id = 0): string #{{{2
    if id != 0
        var line: string = search('^\[' .. id .. ']:', 'n')
            ->getline()
        return line
            ->strpart(line->matchend(':\s*'))
    else
        # Do *not* use `normal! %`!{{{
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
        normal! v%y
        return @"->substitute('^(\|)$\|\s', '', 'g')
    endif
enddef

def IdOutsideReferenceSection(): bool #{{{2
    var ref_section_lnum: number = search('^' .. REF_SECTION .. '$', 'n')
    if search('^\[\d\+]:', 'n', ref_section_lnum) > 0
        execute 'silent lvimgrep /^\[\d\+]:\%<' .. ref_section_lnum .. 'l/j %'
        echomsg 'There are id declarations outside the Reference section'
        setloclist(0, [], 'a', {title: 'move them inside or remove/edit them'})
        return true
    endif
    return false
enddef

def IsARealLink(): bool #{{{2
    return synstack('.', col('.'))
        ->mapnew((_, v: number): string => synIDattr(v, 'name'))
        ->reverse()
        ->match('^markdownLink') >= 0
enddef

def MakeSureReferenceSectionExists() #{{{2
    var ref_section_lnum: number = search('^' .. REF_SECTION .. '$', 'n')
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
        silent syntax list markdownLink
    catch /^Vim\%((\a\+)\)\=:E28:/
        return false
    endtry
    return true
enddef

def MultiLineLinks(): bool #{{{2
    cursor(1, 1)
    var pat: string = '\[[^][]*\n\_[^][]*](.*)'
    var flags: string = 'cW'
    var g: number = 0 | while search(pat, flags) > 0 && g <= GUARD | ++g
        flags = 'W'
        if IsARealLink()
            execute 'lvimgrep /' .. pat .. '/gj %'
            setloclist(0, [], 'a',
                {title: 'some descriptions of links span multiple lines; make them mono-line'})
            return true
        endif
    endwhile
    return false
enddef

