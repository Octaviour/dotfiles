" allow completion of figure etc labels
setlocal iskeyword+=:

" spell checking
set spell

" mappings
nnoremap <buffer> <localleader>v :call pvs#texviewer()<cr>
nnoremap <buffer> <localleader>cc :write<cr>:execute '!start cmd /c latexmk '.shellescape(b:vimtex.tex)<cr>
"nnoremap <buffer> <localleader>c :write<cr>:call pvs#texcompile()<cr>

setlocal makeprg=latexmk\ -pdf\ -latexoption=-file-line-error\ main.tex
