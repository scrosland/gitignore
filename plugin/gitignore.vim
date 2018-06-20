" Vim plugin that add the entries in .gitignore to 'wildignore'
"
" Last Change:	2012 Aug 6
" Maintainer:	Adam Bellaire
" Contributors:	Giuseppe Rota
" Contributors:	Simon Crosland
" License:	This file is placed in the public domain.
"
"                     Fugitive Integration
" The plugin provides no default mappings but integrates nicely with fugitive
" https://github.com/tpope/vim-fugitive. I.e. if you have fugitive installed,
" this plugin will use fugitive's builtin detection of a git repository and
" add that repo's gitignore entries to 'wildignore'
"
" If you don't want that to happen automatically, create the file
" `.vim/after/plugin/disable-gitignore-fugitive.vim` with the single command:
" autocmd! wildignorefromgitignore_fugitive
"
"                     Manual Triggering
" If you need to invoke the functionality manually, put this in your .vimrc:
" map <silent> <unique> <Leader>foo <Plug>WildignoreFromGitignore
" which will look for a .gitignore file in the same directory as the current
" file.
"
" You can also map against the :WildignoreFromGitignore command that accepts
" a directory name as in:
" map <Leader>baz :WildignoreFromGitignore /path/to/some/repo<CR>

if exists("g:loaded_gitignore_wildignore")
  finish
endif
let g:loaded_gitignore_wildignore = 1

let s:save_cpo = &cpo
set cpo&vim

let s:gitignore_files = []

function s:ShouldParseFile(gitignore)
  " testing if the file has been seen before is cheaper that testing
  " readability, so do them in that order
  if index(s:gitignore_files, a:gitignore) == -1
    return 0
  endif
  if !filereadable(a:gitignore)
    return 0
  endif
  " save the gitignore name after testing if it is readable to allow for files
  " being created after the first call to this function
  call add(s:gitignore_files, a:gitignore)
  return 1
endfunction

function s:WildignoreFromGitignore(gitignore)
  if !s:ShouldParseFile(a:gitignore)
    return
  endif
  let igstring = ''
  for oline in readfile(a:gitignore)
    let line = substitute(oline, '\s|\n|\r', '', "g")
    if line =~ '^#' | con | endif
    if line == ''   | con | endif
    if line =~ '^!' | con | endif
    if line =~ '/$' | let igstring .= "," . line . "*" | con | endif
    let igstring .= "," . line
  endfor
  let execstring = "set wildignore+=".substitute(igstring, '^,', '', "g")
  execute execstring
endfunction

function s:WildignoreFromGitDirectory(...)
  let gitignore = (a:0 && !empty(a:1)) ? fnamemodify(a:1, ':p') : fnamemodify(expand('%'), ':p:h') . '/'
  let gitignore .= '.gitignore'
  call s:WildignoreFromGitignore(gitignore)
endfunction

function s:WildignoreFromGlobalGitignore()
endfunction

noremap <unique> <script> <Plug>WildignoreFromGitDirectory <SID>WildignoreFromGitDirectory
noremap <SID>WildignoreFromGitDirectory :call <SID>WildignoreFromGitDirectory()<CR>

command -nargs=? WildignoreFromGitDirectory :call <SID>WildignoreFromGitDirectory(<q-args>)

augroup wildignorefromgitignore_fugitive
    autocmd!
    autocmd User Fugitive if exists('b:git_dir') | call <SID>WildignoreFromGitDirectory(fnamemodify(b:git_dir, ':h')) | endif
augroup END

let &cpo = s:save_cpo
unlet s:save_cpo

" vim:set ft=vim sw=2 sts=2 et:
