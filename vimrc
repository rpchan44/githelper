" ==========================
" 📄 Minimal vimrc for YAML
" ==========================

" Always use spaces, never tabs
set expandtab

" YAML indentation: 2 spaces
autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

" Auto-indent
filetype plugin indent on

" Enable syntax highlighting
syntax on

" Show line numbers
set number

" Show invisible chars (helpful for spaces in YAML)
set list
set listchars=tab:▸\ ,trail:·

" Highlight trailing whitespace
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
autocmd BufWinEnter * match ExtraWhitespace /\s\+$/
autocmd InsertEnter * match ExtraWhitespace /\s\+\%#\@<!$/
autocmd InsertLeave * match ExtraWhitespace /\s\+$/
autocmd BufWinLeave * call clearmatches()

" YAML folding support
let g:yaml_folding = 1

" Run yamllint on save (if installed)
autocmd BufWritePost *.yaml,*.yml silent! !yamllint % || echo "YAML lint passed"

