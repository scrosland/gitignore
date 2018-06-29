if exists("g:loaded_gitignore_git")
  finish
endif
let g:loaded_gitignore_git = 1

function! s:chdir(dir)
  if strlen(a:dir) && a:dir !=# getcwd()
    let chdir = (exists("*haslocaldir") && haslocaldir()) ? 'lcd' : 'cd'
    execute chdir . ' ' . a:dir
  endif
endfunction

function! s:system(abspath, command)
  let cwd = getcwd()
  try
    call s:chdir(a:abspath)
    silent let output = system(a:command)
  finally
    call s:chdir(a:abspath)
  endtry
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

" directory => git root directory
let s:git_roots = {}

function! s:find_root_in_cache(dirname)
  let dirname = copy(a:dirname)
  while strlen(dirname) && dirname !=# '/'
    let root = get(s:git_roots, dirname, '')
    if strlen(root)
      if dirname !=# a:dirname
        let s:git_roots[a:dirname] = root   " augment the cache
      endif
      return root
    endif
    let dirname = fnamemodify(dirname, ':h')
  endwhile
  return ''
endfunction

" Return the git root (toplevel) directory related to the dirname argument.
" Note that if dirname is in a git submodule this returns the parent toplevel,
" not the toplevel of the submodule.  Using 'git rev-parse --show-toplevel'
" would do the opposite and return the toplevel of the submodule.
function! s:get_root(dirname)
  if strlen(a:dirname) == 0
    return ''
  endif
  let root = s:find_root_in_cache(a:dirname)
  if strlen(root)
    return root
  endif
  silent let output = s:system(a:dirname, 'git rev-parse --is-inside-working-tree --show-cdup')
  if v:shell_error != 0 || output =~? '^fatal'
    return ''
  endif
  let raw_root = split(output, '\n')[-1]
  if strlen(raw_root) == 0
    let raw_root = '.'
  endif
  let root = substitute(fnamemodify(raw_root, ':p'), '/$', '', '')
  let s:git_roots[a:dirname] = root
  return root
endfunction

" Return the git root (toplevel) directory related to the current file (%).
" Also updates the buffer local cache of the current git root.
function! gitignore#git#root()
  if exists('b:gitignore_root')
    return b:gitignore_root
  endif
  let b:gitignore_root = s:get_root(s:abs_directory_of_current_file())
  return b:gitignore_root
endfunction

" Return the git root (toplevel) directory related to the cwd.
function! gitignore#git#root_from_cwd()
  return s:get_root(getcwd())
endfunction

" Get a git configuration item.
"   key     : the git config key to read.
"   domain  : the git config file to read. Optional, defaults to '--global'.
" Note this only returns a single value, so multi-value items won't work.
let s:domains = [ '', '--global', '--local', '--system' ]
function! gitignore#git#getconf(key, ...)
  let l:domain = get(a:, 1, '--global')
  if index(s:domains, l:domain) == -1
    throw 'error: getconf() called with unknown git config file, ' . l:domain
  endif
  silent let output = system('git config --null ' . l:domain . ' --get ' . a:key)
  if !v:shell_error && strlen(output)
    " system() replaces NUL characters in the output with SOH (0x01)
    return split(output, "\x01")[0]
  endif
  return ''
endfunction
