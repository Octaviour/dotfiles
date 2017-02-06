setlocal foldmethod=marker

augroup vimclose
    autocmd!
    autocmd BufWritePost <buffer> source $MYVIMRC
augroup END
