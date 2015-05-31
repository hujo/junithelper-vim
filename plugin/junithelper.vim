scriptencoding utf-8

if get(g:, 'loaded_junithelper', 0)
  finish
endif

let g:loaded_junithelper = 1

command! -nargs=* -complete=file JunitHelper echo junithelper#execResult('', <q-args>)
command! -nargs=* -complete=file JunitHelperMake echo junithelper#execMake(<q-args>)

nnoremap <silent><Plug>(junithelper-atl9) :<C-u>call junithelper#execMakeAndOpen()<CR>
nnoremap <silent><Plug>(junithelper-atl3) :<C-u>call junithelper#execForce3()<CR>
nnoremap <silent><Plug>(junithelper-atl4) :<C-u>call junithelper#execForce4()<CR>
