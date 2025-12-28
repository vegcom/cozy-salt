" run at vim startup function is called here
autocmd VimEnter * call RunOnce()
"warn on trailing white spaces on enter, and call cute text
autocmd BufWinEnter * match ErrorMsg '\s\+$'
"remove trailing white space(s) on write
autocmd BufWritePre * %s/\s\+$//e
" clear old buffer matches
autocmd BufWinLeave * call clearmatches()
" Spell-check Markdown files and Git Commit Messages
autocmd FileType markdown setlocal spell
autocmd FileType gitcommit setlocal spell
" Enable dictionary auto-completion in Markdown files and Git Commit Messages
autocmd FileType markdown setlocal complete+=kspell
autocmd FileType gitcommit setlocal complete+=kspell

" vi: ft=vim
