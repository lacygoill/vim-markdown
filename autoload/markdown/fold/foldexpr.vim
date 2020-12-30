vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Old but can still be useful {{{1
#     fu s:has_surrounding_fencemarks(lnum) abort {{{2
#         let pos = [line('.'), col('.')]
#         call cursor(a:lnum, 1)
#
#         let start_fence = '\%^```\|^\n\zs```'
#         let end_fence = '```\n^$'
#         let fence_position = searchpairpos(start_fence, '', end_fence, 'W')
#
#         call cursor(pos)
#         return fence_position != [0, 0]
#     endfu
#
#     fu s:has_syntax_group(lnum) abort {{{2
#         let syntax_groups = synstack(a:lnum, 1)->map({_, v -> synIDattr(v, 'name')})
#         for value in syntax_groups
#             if value =~? 'markdown\%(Code\|Highlight\)'
#                 return 1
#             endif
#         endfor
#     endfu
#
#     fu s:line_is_fenced(lnum) abort {{{2
#         if get(b:, 'current_syntax', '') is# 'markdown'
#             " It's cheap to check if the current line has 'markdownCode' syntax group
#             return s:has_syntax_group(a:lnum)
#         else
#             " Using `searchpairpos()` is expensive, so only do it if syntax highlighting is not enabled
#             return s:has_surrounding_fencemarks(a:lnum)
#         endif
#     endfu
" }}}1

def markdown#fold#foldexpr#toggle(): #{{{1
    var &l:fde = &l:fde == 'markdown#fold#foldexpr#stacked()'
        ? 'markdown#fold#foldexpr#nested()'
        : 'markdown#fold#foldexpr#stacked()'
    # Why?{{{
    #
    # We set `'fdm'` to `manual` by default, because `expr` can be much more expensive.
    # As a consequence, if we change  the value of `'fde'`, Vim won't re-compute
    # the folds; we want it to; that's why we need to execute `#compute()`.
    #}}}
    sil! call fold#lazy#compute('force')
enddef
"}}}1
def markdown#fold#foldexpr#headingDepth(lnum: number): number #{{{1
    var thisline = getline(lnum)
    var level = matchstr(thisline, '^#\{1,6}')->strlen()
    if !level && thisline != '' && thisline != '```'
        var nextline = getline(lnum + 1)
        if nextline =~# '^=\+\s*$'
            return 1
        # Why `\{2,}` and not just `\+`?{{{
        #
        # Indeed, according to the markdown spec would parse, a single hyphen at
        # the  start of  a line  is enough  to start  a heading.   However, it's
        # *very* annoying for Vim to parse a  single hyphen as a heading when we
        # put a diff in a markdown file.
        #}}}
        elseif nextline =~# '^-\{2,}\s*$'
            return 2
        endif
    endif
    # Temporarily commented because it makes us gain 0.5 seconds when loading Vim notes:{{{
    #
    #     if level > 0 && s:line_is_fenced(lnum)
    #         # Ignore # or === if they appear within fenced code blocks
    #         return 0
    #     endif
    #
    # If  you uncomment it, in  the previous block, replace  `return {1|2}` with
    # `var level = {1|2}`.
    #}}}
    return level
enddef

def markdown#fold#foldexpr#nested(): string #{{{1
    var depth = markdown#fold#foldexpr#headingDepth(v:lnum)
    return depth > 0 ? '>' .. depth : '='
enddef

def markdown#fold#foldexpr#stacked(): string #{{{1
    # Why would it be useful to return `1` instead of `'='`?{{{
    #
    # Run this shell command:
    #
    #     $ vim -Nu <(cat <<'EOF'
    #         setl fdm=expr fde=Heading_depth(v:lnum)>0?'>1':'='
    #         fu Heading_depth(lnum)
    #             let level = getline(a:lnum)->matchstr('^#\{1,6}')->strlen()
    #             if !level
    #                 if getline(a:lnum + 1) =~ '^=\+\s*$'
    #                     let level = 1
    #                 endif
    #             endif
    #             return level
    #         endfu
    #         ino <expr> <c-k><c-k> repeat('<del>', 300)
    #     EOF
    #     ) +"%d | put='text' | norm! yy300pG300Ax" /tmp/md.md
    #
    # Vim starts up after about 3 seconds.
    # Next, press `I C-k C-k`; Vim removes 300 characters after about 3 seconds.
    #
    # Now, replace  `'='` with `1` and  re-run the same command:  this time, Vim
    # starts up immediately; similarly, it removes 300 characters immediately.
    #}}}
    #   Why is it possible here, but not in `#nested()`?{{{
    #
    # Because this function is meant for files with only level-1 folds.
    # OTOH, we can't in `#nested()`, because  the latter is meant for files with
    # up to level-6 folds.
    #}}}
    #   Why don't you return `1` then?{{{
    #
    # If you write some lines before the first heading line, they will be folded.
    # I don't want such lines to be folded.
    # A line should be folded only if it's somewhere below a heading line.
    #
    # See also our comments in:
    #
    #     ~/.vim/plugged/vim-git/after/ftplugin/git.vim
    #
    # One of them illustrates how `'='` is preferable to `1`.
    # Folding too much can have unexpected results.
    #}}}
    #     But doesn't it make the performance worse?{{{
    #
    # No, because – in  big enough files – as soon as Vim  creates the folds, we
    # reset `'fdm'` to `manual` which is less costly.
    #}}}
    return markdown#fold#foldexpr#headingDepth(v:lnum) > 0 ? '>1' : '='
enddef

