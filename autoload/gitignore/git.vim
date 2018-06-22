if exists("g:loaded_gitignore_git")
  finish
endif
let g:loaded_gitignore_git = 1

function! s:cd_system(abspath, command)
  let cwd = getcwd()
  let changedir = strlen(abspath) && abspath !=# cwd
  if changedir
    execute! silent 'lcd ' . abspath
  endif
  let output = system(command)
  if changedir
    execute! silent 'lcd ' . cwd
  endif
  return output
endfunction

function! s:abs_directory_of_current_file()
  let abspath = expand('%:p')
  if strlen(abspath) == 0
    return ''
  endif
  if isdirectory(abspath)
    return abspath
  endif
  return substitute(fnamemodify(abspath, ':h'), '/$', '', '')
endfunction

" current directory name => git root directory name
s:git_roots = {}

function! s:find_root_in_cache(dirname)
  let dirname = a:dirname
  while strlen(dirname) && dirname !=# '/'
    root = get(s:git_roots, dirname, '')
    if strlen(root)
      if dirname !=# a:dirname
        s:git_roots[a:dirname] = root   " augment the cache
      return root
    endif
    let dirname = fnamemodify(dirname, ':h')
  endwhile
  return ''
endfunction

function! gitignore#git#root()
  if exists('b:gitignore_root') && strlen(b:gitignore_root)
    return b:gitignore_root
  endif
  let dirname = s:abs_directory_of_current_file()
  let b:gitignore_root = s:find_root_in_cache(dirname)
  if strlen(b:gitignore_root)
    return b:gitignore_root
  endif
  let output = s:cd_system(dirname, 'git rev-parse --is-inside-working-tree --show-cdup')
  if v:shell_error != 0 || output =~? '^fatal'
    return ''
  endif
  let raw_root = split(output, '\n')[-1]
  let cooked_root = (strlen(raw_root) == 0) ?
                      \ '.' :
                      \ substitute(raw_root, '/$', '', '')
  let b:gitignore_root = fnamemodify(cooked_root, ':p')
  let s:git_roots[dirname] = b:gitignore_root
  return b:gitignore_root
endfunction
