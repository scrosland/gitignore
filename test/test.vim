let s:myroot = expand('<sfile>:p:h:h')
execute 'set rtp+=' . s:myroot

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
      let tmsg = type(output) == type(expected) ? '' : ' different types'
      let msg = 'FAILED (expected "' . expected . '")' . tmsg
      let s:failed += 1
    endif
    echomsg 'Result: ' . msg
  endif
endfunction

echomsg 'Open plugin/gitignore.vim'
edit plugin/gitignore.vim
call s:do('gitignore#git#root()', s:myroot)
call s:do('gitignore#git#root_from_cwd()', s:myroot)

echo '===== Full test log ====='
messages
echo 'Summary: ' . s:passed . ' passed, ' . s:failed . ' failed.'
quit
