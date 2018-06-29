" Run tests with one of:
"
"     vim -c 'source test/test.vim'
"     vim -S test/test.vim
"

let s:myroot = expand('<sfile>:p:h:h')
execute 'set rtp+=' . s:myroot
source autoload/gitignore/git.vim 

let s:passed = 0
let s:failed = 0

function! s:do(...)
  let expr = a:1
  let expected = a:0 > 1 ? a:2 : -1
  let str = expr . ' = ['
  execute 'let output = ' . expr
  echomsg str . output . '] type(output) = ' . type(output)
  if expected != -1
    if output ==# expected && type(output) == type(expected)
      let msg = 'PASSED'
      let s:passed += 1
    else
      let tmsg = type(output) == type(expected) ?
                    \ '' :
                    \ ', type = ' . type(expected)
      let msg = 'FAILED (expected "' . expected . '"' . tmsg . ')'
      let s:failed += 1
    endif
    echomsg 'Result: ' . msg
  endif
endfunction

execute 'cd ' . s:myroot
echomsg 'Empty buffer, no file => no root'
call s:do('gitignore#git#root()', '')

echomsg 'Open README'
edit README
call s:do('gitignore#git#root()', s:myroot)

echomsg 'Open plugin/gitignore.vim'
edit plugin/gitignore.vim
call s:do('gitignore#git#root()', s:myroot)

call s:do('gitignore#git#root_from_cwd()', s:myroot)

echomsg 'Set git config gitignore.test and read it back'
silent call system('git config --local --add gitignore.test ' . v:version)
if v:shell_error
  echoerr('Failed to set test git config option, gitignore.test')
endif
call s:do('gitignore#git#getconf("gitignore.test", "--local")', '' . v:version)
silent call system('git config --local --unset-all gitignore.test')
if v:shell_error
  echoerr('Failed to unset test git config option, gitignore.test')
endif

echo '===== Full test log ====='
messages
echo 'Summary: ' . s:passed . ' passed, ' . s:failed . ' failed.'
quitall
