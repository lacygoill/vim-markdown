vim9script noclear

if exists('loaded') | finish | endif
var loaded = true

# Interface {{{1
def markdown#highlightLanguages() #{{{2
    # What's the purpose of this `for` loop?{{{
    #
    # Iterate over the  languages mentioned in `b:markdown_highlight`,  and for each
    # of them, include the corresponding syntax plugin.
    #}}}
    var done_include: dict<bool>
    var delims: list<string> = get(b:, 'markdown_highlight', [])
    for delim in delims
        # If by accident, we manually  assign a value to `b:markdown_highlight`, and
        # we write duplicate values, we want to include the corresponding syntax
        # plugin only once.
        if done_include->has_key(delim)
            continue
        endif
        # We can't blindly rely on the delim:{{{
        #
        #     # ✔
        #     ```python
        #     # here, we indeed want the python syntax plugin
        #
        #     # ✘
        #     ```js
        #     # there's no js syntax plugin
        #     # we want the javascript syntax plugin
        #}}}
        var filetype: string = GetFiletype(delim)
        if empty(filetype)
            continue
        endif

        # What's the effect of `:syntax include`?{{{
        #
        # If you execute:
        #
        #     syntax include @markdownHighlightpython syntax/python.vim
        #
        # 1. Vim will define all groups from  all python syntax plugins, but for
        # each of them, it will add the argument `contained`.
        #
        # 2. Vim  will  define   the  cluster  `@markdownHighlightpython`  which
        # contains all the syntax groups defined in python syntax plugins.
        #
        # Note that if `b:current_syntax` is set, Vim won't define the contained
        # python syntax groups; the cluster will be defined but contain nothing.
        #}}}
        # `silent!` is necessary to suppress a possible E403 error.{{{
        #
        # To reproduce, write this text in `/tmp/md.md`:
        #
        #     ```rexx
        #     text
        #     ```
        #     ```vim
        #     text
        #     ```
        #
        # Then, open the `/tmp/md.md` file:
        #
        #     Error detected while processing BufRead Autocommands for "*.md"
        #         ..FileType Autocommands for "*"
        #         ..Syntax Autocommands for "*"
        #         ..function <SNR>22_SynSet[25]
        #         ..script ~/.vim/pack/mine/opt/markdown/syntax/markdown.vim[835]
        #         ..function markdown#highlightLanguages[82]
        #         ..script /usr/local/share/vim/vim82/syntax/vim.vim:
        #     line  838:
        #     E403: syntax sync: line continuations pattern specified twice
        #
        # The issue  is that  the markdown  file contains  2 fenced  code blocks
        # causing Vim to include 2 syntax  plugins, each of which runs this kind
        # of command:
        #
        #     syntax sync linecount {pattern}
        #}}}
        # Warning: do *not* use a different prefix than `markdownHighlight` in the cluster name{{{
        #
        # That's the  prefix used by the  default markdown plugin; as  a result,
        # that's the one assumed by other default syntax plugins such as the zsh
        # one:
        #
        # https://github.com/chrisbra/vim-zsh/blob/25c49bd61b8e82fd8f002c0ef21416d6550f79ea/syntax/zsh.vim#L22-L24
        #
        # If  you change  the prefix,  an embedded fenced  codeblock may  not be
        # correctly highlighted.
        #}}}
        # I have some wrong highlighting in a code block.  An item matches where it should not!{{{
        #
        # The  plugin  author  might  have forgotten  to  use  `contained`  when
        # installing a rule.
        #
        # If an item  is missing "contained", *all* the rules  in the group will
        # match  at the  toplevel of  a  fenced code  block.  Even  if they  are
        # defined with "contained".
        # That's because `:help syn-include` includes  any group for which there
        # is at  least one  item matching  at the top  level, inside  the ad-hoc
        # specified cluster.   The one that you  use later to define  the region
        # highlighting a code block.
        #}}}
        execute 'silent! syntax include @markdownHighlight' .. filetype
            .. ' syntax/' .. filetype .. '.vim'
        # Why?{{{
        #
        # The previous  `:syntax include`  has caused `b:current_syntax`  to bet
        # set to the value stored in `filetype`.
        # If  more than  one language  is embedded,  the next  time that  we run
        # `:syntax include`, the resulting cluster will contain nothing.
        #}}}
        unlet! b:current_syntax

        # Note that the name of the region is identical to the name of the cluster:{{{
        #
        #     'markdownHighlight' .. filetype
        #
        # But there's no conflict.
        # Probably because a cluster name is always prefixed by `@`.
        #}}}
        execute 'syntax region markdownHighlight' .. filetype
            .. ' matchgroup=markdownCodeDelimiter'
            .. ' start=/^\s*````*\s*' .. delim .. '\S\@!.*$/'
            .. ' end=/^\s*````*\ze\s*$/'
            .. ' keepend'
            .. ' concealends'
            .. ' contains=@markdownHighlight' .. filetype
        done_include[delim] = true
    endfor
    if !empty(delims)
        syntax sync ccomment markdownHeader
    endif
    # TODO: The previous line is necessary to fix an issue.  But is it the right fix?{{{
    #
    # Here is the issue:
    #
    #     $ vim +":% delete | put =['# x', '', '\`\`\`vim']+repeat([''], 9)+['\`\`\`']+repeat([''], 109)+['# x', '', 'some text']" +exit /tmp/md.md
    #     $ vim +'normal! Gzo' /tmp/md.md
    #
    # Without the previous `:syntax sync`, `some text` is wrongly highlighted by
    # `markdownFencedCodeBlock`.  Study `:help 44.10` then `:help :syn-sync`.
    #
    # ---
    #
    # Note that whenever we run a `:syntax include`, there is a risk that it has
    # changed how the synchronization is performed (by sourcing a `:syntax sync`
    # directive).
    #
    # ---
    #
    # Is there a risk that a `:syntax include` resets a `:syntax iskeyword`?
    # Or some other syntax-specific setting?
    # If  so, should  we try  to  save its  value before  `:syntax include`  and
    # restore it afterward?
    #}}}
enddef

def markdown#fixFormatting() #{{{2
    var view: dict<number> = winsaveview()

    # A page may have an embedded codeblock which is not properly ended with ```` ``` ````.{{{
    #
    # As an example, look at the very bottom of this page:
    # https://github.com/junegunn/fzf/wiki/Examples
    #
    # In  this case,  the highlighting  of the  reference links  we're going  to
    # create may be wrong.
    # And the rest of the function  relies on the syntax highlighting, which may
    # have additional unexpected side effects.
    #}}}
    if synstack('$', 1)
        ->mapnew((_, v: number): string => synIDattr(v, 'name'))
        ->get(0, '') =~ '^markdownHighlight'
        append('$', ['```', ''])
    endif

    # Why?{{{
    #
    # If a link contains a closing parenthesis, it breaks the highlighting.
    # The latter (and the conceal) stops too early.
    #
    # Besides, on some markdown pages like this one:
    #
    #     https://github.com/junegunn/fzf/wiki/Examples
    #
    # Some links are invisible.
    #
    #     ![](https://github.com/piotryordanov/fzf-mpd/raw/master/demo.gif)
    #       ^
    #       ✘
    # This is because there's no description of the link.
    #
    # We can fix all of these issues by converting inline links to reference links.
    #}}}
    LinkInline2Ref

    # If our file  contains an embedded codeblock, and the  latter contains some
    # comments beginning with `#`, they may be wrongly interpreted as headers.
    # Fix this by adding a space in front of them.
    # Make sure syntax highlighting is enabled.{{{
    #
    # This function is called by `:Fix`.
    # If we invoke the latter via `:argdo`:
    #
    #     argdo Fix
    #
    # The syntax highlighting will be disabled.
    # See `:help :bufdo`.
    #}}}
    var eventignore_save: string = &eventignore
    &eventignore = ''
    doautocmd Syntax
    &eventignore = eventignore_save

    cursor(1, 1)
    var flags: string = 'cW'
    var g: number = 0 | while search('^#', flags) > 0 && g < 999 | ++g
        flags = 'W'
        var item: string = synstack('.', col('.'))
            ->mapnew((_, v: number): string => synIDattr(v, 'name'))
            ->get(-1, '')
        # Why `''` in addition to `Delimiter`?{{{
        #
        # Just in case there's still no syntax highlighting.
        #}}}
        if index(['', 'Delimiter'], item) == -1
            var line: string = getline('.')
            var new_line: string = ' ' .. line
            setline('.', new_line)
        endif
    endwhile
    winrestview(view)
enddef

def markdown#undoFtplugin() #{{{2
    set autoindent<
    set commentstring<
    set concealcursor<
    set conceallevel<
    set comments<
    set errorformat<
    set foldexpr<
    set foldmethod<
    set foldtext<
    set formatlistpat<
    set foldminlines<
    set formatprg<
    set keywordprg<
    set makeprg<
    set spelllang<
    set textwidth<
    set wrap<
    unlet! b:cr_command b:exchange_indent b:sandwich_recipes b:markdown_highlight b:mc_chain
    silent! autocmd! InstantMarkdown * <buffer>
    silent! autocmd! MarkdownWindowSettings * <buffer>

    nunmap <buffer> cof
    nunmap <buffer> [of
    nunmap <buffer> ]of
    nunmap <buffer> gd
    xunmap <buffer> gd
    nunmap <buffer> gl

    nunmap <buffer> +[#
    nunmap <buffer> +]#

    nunmap <buffer> =rb
    nunmap <buffer> =r-
    nunmap <buffer> =r--
    xunmap <buffer> =r-

    xunmap <buffer> H
    xunmap <buffer> L

    delcommand CheckPunctuation
    delcommand CommitHash2Link
    delcommand FixFormatting
    delcommand FoldSortBySize
    delcommand LinkInline2Ref
    delcommand Preview
enddef

def markdown#hyphens2hashes(type = ''): string #{{{2
    if type == ''
        &operatorfunc = 'markdown#hyphens2hashes'
        return 'g@'
    endif
    var range: string = ":'[,']"
    var hashes: string = search('^#', 'bnW')->getline()->matchstr('^#*')
    if empty(hashes)
        return ''
    endif
    execute 'silent ' .. range .. 'substitute/^---/' .. hashes .. ' ?/e'
    return ''
enddef

def markdown#fixFencedCodeBlock() #{{{2
    if execute('syntax list @markdownHighlightvim', 'silent!') !~ 'markdownHighlightvim'
        return
    endif
    # Why here?  Why not in our Vim syntax plugin?{{{
    #
    # Well, we do write  it in our Vim syntax plugin  too; it's indeed necessary
    # for Vim files, but it's not enough for markdown files, because `syntax clear`
    # is ignored when run from an included syntax file.
    #
    # From `:help 44.9`:
    #
    #    > The `:syntax  include` command is  clever enough  to ignore a  `:syntax clear`
    #    > command in the included file.
    #}}}
    syntax clear vimUsrCmd
enddef
# }}}1
# Utilities {{{1
def GetFiletype(arg_filetype: string): string #{{{2
    if filereadable($VIMRUNTIME .. '/syntax/' .. arg_filetype .. '.vim')
        return arg_filetype
    else
        var filetype: string = execute('autocmd filetypedetect')
            ->split('\n')
            ->filter((_, v: string): bool => v =~ '\C\*\.' .. arg_filetype .. '\>')
            ->get(0, '')
            ->matchstr('\Csetf\%[iletype]\s*\zs\S*')
        if filereadable($VIMRUNTIME .. '/syntax/' .. filetype .. '.vim')
            return filetype
        endif
    endif
    return ''
enddef

