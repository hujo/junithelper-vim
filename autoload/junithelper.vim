scriptencoding utf-8

if !exists('g:junithelper_home')
  finish
endif

let s:BASE_OPTIONS =
\ [['-Djunithelper.configProperties=%s', '/junithelper-config.properties']
\ ,['-Djunithelper.extensionConfigXML=%s', '/junithelper-extension.xml']
\ ,['-jar %s', '/junithelper-core-*.jar']]

"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
"" オプション
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" g:junithelper_home
"   junitheperがインストールされているディデクトリへのパスを設定します。
"   example:
"     let g:junithelper_home = 'C:\Users\user\Download\junithelper'
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" g:junithelper_open
"   1 または 0 を設定します。
"   テストファイルが作成された時にそのファイルを開くかどうかを設定します。
"   1 ならば開き、0 ならば開きません。
"   デフォルトの値は 1 です。
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" g:junithelper_open_command
"   g:junithelper_open に 1 が設定されていた場合のファイルの開き方を設定します。
"   デフォルトの値は 'split' です。
"   example:
"     let g:junithelper_open_command = 'vsplit'
"     let g:junithelper_open_command = 'tabedit'
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" g:junithelper_opts
"   junithelper を実行する java コマンドに渡す追加オプションを指定します。
"   配列で指定してください。
"
"   デフォルトでは以下のコマンドとなります。
"   %s の部分は {g:junithelper_home}/core/tools に置き換えられます。
"
"   java -Djunithelper.skipConfirming=true ^
"        -Djunithelper.configProperties=%s/junithelper-config.properties ^
"        -Djunithelper.extensionConfigXML=%s/junithelper-extension.xml ^
"        -jar %s/junithelper-core-*.jar
"
"""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

function! s:isOpen() abort
  return get(g:, 'junithelper_open', 1)
endfunction

function! s:openCmd() abort
  return get(g:, 'junithelper_open_command', 'split')
endfunction

" g:junithelper_home に設定されているパス文字列を取得。
" 設定されているパスが存在しない場合は空文字列を返す。
function! s:getJunitHelperHome() abort
  let home = get(g:, 'junithelper_home', '')
  return home ==# '' ? '' : glob(home . '/core/tools')
endfunction

" 与えられたファイル名のバッファが
" カレントウインドウに開かれているかを調べる。
function! s:isOpend(fname) abort
  let bnr = bufnr(a:fname)
  return bufwinnr(bnr) != -1
endfunction

function! s:getLinkedPathOpts(path) abort
  let cmdopts = ['-Djunithelper.skipConfirming=true']
  let addopts = get(g:, 'junithelper_opts', [])
  if type(addopts) is type([]) && !empty(addopts)
    let cmdopts = cmdopts + addopts
  endif
  let baseopts = map(copy(s:BASE_OPTIONS), 'printf(v:val[0], glob(a:path . v:val[1]))')
  return join(cmdopts + baseopts, ' ')
endfunction

" junithelper を実行するコマンドオプション文字列を作成する。
" g:junithelper_home の値が不正である場合または引数が空文字列の場合
" は空文字列を返す。
function! s:buildCmd(arg) abort
  let path = s:getJunitHelperHome()
  if path ==# '' || a:arg ==# ''
    return ''
  endif
  return printf('java %s %s', s:getLinkedPathOpts(path), a:arg)
endfunction

function! s:system(arg) abort
  return a:arg ==# '' ? '' : system(a:arg)
endfunction

function! s:isTestFile(fname) abort
  return fnamemodify(a:fname, ':t:r') =~# '\vTest$'
endfunction

" cmd と fname をスペースで結合した文字列を返す。
" cmd は make, force3, force4 など。
" fname が空文字列の場合カレントバッファのファイル名を使用する。
" ファイルがテストファイルである場合またはファイルが存在しない場合
" は空文字列を返す。
" テストファイルかどうかの判定は s:isTestFile() による。
function! s:escapedFnameWithCmd(cmd, fname) abort
  let target = glob(a:fname !=# '' ? a:fname : '%:p')
  return target ==# '' || s:isTestFile(target) ?
  \   '' : a:cmd . ' ' . shellescape(target)
endfunction

" junithelper コマンドの結果から作成されたテストファイル名を抽出した
" 文字列の配列を返す。
function! s:parseResult(result) abort
  let regx = '\v\c^\s*%(created|forced junit \d\.\a):\s*\zs\f+\ze\s*$'
  let ret = map(split(a:result, '\v\r\n|\r|\n'), 'matchstr(v:val, regx)')
  return filter(ret, 'v:val !=# ''''')
endfunction

" 1. ファイルが存在する
" 2. g:junithelper_open が 1 である
" 3. カレントウインドウにすでに対象のファイルが開かれていない
" であるならば、ファイルを開く。
" 開き方は g:junithelper_open_command による。
function! s:openFile(fname) abort
  if glob(a:fname) !=# '' && s:isOpen() && !s:isOpend(a:fname)
    execute printf('%s %s', s:openCmd(), a:fname)
  endif
endfunction

" junithelper cmd target を実行し結果の文字列を返す。
function! junithelper#execResult(cmd, target) abort
  return s:system(s:buildCmd(s:escapedFnameWithCmd(a:cmd, a:target)))
endfunction

" junithelper cmd target を実行しファイルを開こうとする。
function! junithelper#execAndOpen(cmd, target) abort
  call map(s:parseResult(junithelper#execResult(a:cmd, a:target)), 's:openFile(v:val)')
endfunction

" junithelper make target を実行し結果の文字列を返す。
function! junithelper#execMake(target) abort
  return junithelper#execResult('make', a:target)
endfunction

" junithelper make target を実行しファイルを開こうとする。
function! junithelper#execMakeAndOpen() abort
  call junithelper#execAndOpen('make', '')
endfunction

" junithelper force3 target を実行しファイルを開こうとする。
function! junithelper#execForce3() abort
  call junithelper#execAndOpen('force3', '')
endfunction

" junithelper force4 target を実行しファイルを開こうとする。
function! junithelper#execForce4() abort
  call junithelper#execAndOpen('force4', '')
endfunction
