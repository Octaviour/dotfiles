" soft wrapping with nofile to force 80 columns {{{1
function! pvs#softwrapclose()
    if exists('w:pvs_softwrap')
        let l:main_window = winnr()
        " close previous buffer
        wincmd l
        if &filetype == 'MARGIN'
            wincmd c
        endif
        execute l:main_window.'wincmd w'
        unlet w:pvs_softwrap
    endif
endfunction
function! pvs#softwrap(width)
    call pvs#softwrapclose()
    " open new buffer
    vnew
    setfiletype MARGIN
    set buftype=nofile
    wincmd p
    execute 'vertical res '.(80+&numberwidth)
    let w:pvs_softwrap = 1
endfunction
function! pvs#updatewrap()
    if &wrap
        call pvs#softwrap(80)
    else
        call pvs#softwrapclose()
    endif
endfunction

" case change for symbols {{{1
function! pvs#changecase()
    let l:cchar = matchstr(getline('.'), '\%'.col('.').'c.')
    let l:cword = expand('<cword>')

    if l:cword == 'draft'
        normal ciwfinal
    elseif l:cword == 'final'
        normal ciwdraft
    elseif l:cchar == '+'
        normal r-
    elseif l:cchar == '-'
        normal r+
    elseif l:cchar == '*'
        normal r/
    elseif l:cchar == '/'
        normal r*
    elseif l:cchar == '('
        normal r)
    elseif l:cchar == ')'
        normal r(
    elseif l:cchar == '{'
        normal r}
    elseif l:cchar == '}'
        normal r{
    elseif l:cchar == '['
        normal r]
    elseif l:cchar == ']'
        normal r[
    elseif l:cchar == '<'
        normal r>
    elseif l:cchar == '>'
        normal r<
    elseif l:cchar == "'"
        normal r"
    elseif l:cchar == '"'
        normal r'
    elseif l:cchar == ' '
        normal r_
    elseif l:cchar == '_'
        normal r<space>
    else
        normal g~l
    endif
endfunction
" map in) etc to next brace {{{1
function! pvs#selectclosestbracket(brackets, command)
    " find character under cursor
    let l:current_character = matchstr(getline('.'), '\%' . col('.') . 'c.')

    if a:brackets =~# l:current_character
        let l:next_brace = col('.')
    else
        let l:search_string = join(split(a:brackets, '\zs'), '\|')
        let l:next_brace = match(getline('.'), l:search_string, col('.')) + 1

        " if no matches are found
        if l:next_brace == 0
            call feedkeys("\<esc>")
            return
        end
    endif

    execute 'normal! ' . l:next_brace . '|'
    execute 'normal! v' . a:command
endfunction

" open temporary buffer {{{1
function! pvs#opentemporarybuffer()
    split tmp
    set buftype=nofile
endfunction

" remove trailing space {{{1
" TODO rehighlight previous search
function! pvs#removetrailingspace()
    let l:save_view = winsaveview()
    %s/\v\s+$//e
    call winrestview(l:save_view)
    call histdel('search', -1)
endfunction

" increment subsequent lines {{{1
function! pvs#incrementsubsequentlines()
    " TODO: make work for count~=1
    " TODO: do not use normal if not required
    " jump to next number and save initial location
    execute "normal mp"
    execute "normal \<c-a>\<c-x>"
    let l:col = col('.')

    let l:increment=1
    let l:number=1
    while l:number
        " get the word on next line
        execute 'normal j'.l:col.'|'
        let l:firstWord=expand('<cword>')

        " test if it contains a number
        if l:firstWord=~#"[0-9]"
            " increment the number in the text
            for i in range(1,increment)
                execute "normal \<c-a>"
            endfor

            " increment next line more
            let l:increment=l:increment+1

            " stop on last line
            if line('.') == line('$')
                let l:number=0
            endif
        else
            let l:number=0
        endif
    endwhile

    " restore cursor position
    execute "normal 'p"
endfunction

" change directory {{{1
" automatically go to directory file is in
" function pvs#projectroot {{{2
function! pvs#projectroot()
    " changes current directory to folder with .git closest to root
    " start with directory of current file
    let l:pwd = ''
    cd %:p:h

    " move up and remember highest .git directory found
    while 1
        " remember previous directory
        let l:prevdir = getcwd()

        " check if .git directory present
        if isdirectory('.git')
            let l:pwd = getcwd()
        endif

        " move up one directory and check if at root, if cannot move give up
        " TODO do not catch everything
        try | cd .. | catch /.*/ | break | endtry
        if getcwd() ==# l:prevdir
            break
        endif
    endwhile

    " output results
    return l:pwd
endfunction

" function pvs#chdir {{{2
function! pvs#chdir()
    " check if a file is currently loaded
    if len(expand('%')) > 0
        let l:dir = pvs#projectroot()
        if l:dir !=# ''
            " if a project root was found
            execute 'cd '.l:dir
        else
            " return file path
            cd %:p:h
        endif
    else
        " default to HOME directory
        cd $HOME
    endif
endfunction

" Filetype specific {{{1
" TODO: currently there needs to be a main.tex in the pwd
function! pvs#texmainfname()
    " if exists main.tex is the main file
    " otherwise find a file that contains the \documentclass
    let l:main = globpath(getcwd(), '**/main.tex', 0, 1)
    if len(l:main) == 1
        return l:main[0]
    endif
    echom 'ERROR: no main latex file found'
    return ''
endfunction

function! pvs#texviewer()
    " opens the desired pdf viewer
    let l:root = fnamemodify(pvs#texmainfname(), ':p:r')
    if executable('sumatrapdf')
        execute 'Dispatch sumatrapdf '.shellescape(l:root.'.pdf')
    endif
    return l:root
endfunction

function! pvs#texcompile()
    " compiles LaTeX code once
    if !executable('pdflatex')
        echom 'ERROR: pdflatex not found'
        return
    endif
    let l:texfile = pvs#texmainfname()
    let l:outdir = 'output'
    let l:cmd = 'Dispatch pdflatex -halt-on-error -interaction=nonstopmode -synctex=1 -aux-directory='
    execute l:cmd.shellescape(l:outdir).' '.shellescape(l:texfile)
endfunction

" minimize window {{{1
function! pvs#windowminimize()
    let l:windowsize = &lines
    let l:filesize = line('$')
    if l:windowsize > l:filesize
        execute l:filesize.'wincmd _'
        setlocal winfixheight
    endif
endfunction

" open file browser {{{1
function! pvs#openfilebrowser()
    if has('win32')
        ! cmd
    endif
endfunction
