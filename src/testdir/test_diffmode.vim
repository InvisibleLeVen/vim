" Tests for diff mode
source shared.vim
source screendump.vim

func Test_diff_fold_sync()
  enew!
  let l = range(50)
  call setline(1, l)
  diffthis
  let winone = win_getid()
  new
  let l[25] = 'diff'
  call setline(1, l)
  diffthis
  let wintwo = win_getid()
  " line 15 is inside the closed fold
  call assert_equal(19, foldclosedend(10))
  call win_gotoid(winone)
  call assert_equal(19, foldclosedend(10))
  " open the fold
  normal zv
  call assert_equal(-1, foldclosedend(10))
  " fold in other window must have opened too
  call win_gotoid(wintwo)
  call assert_equal(-1, foldclosedend(10))

  " cursor position is in sync
  normal 23G
  call win_gotoid(winone)
  call assert_equal(23, getcurpos()[1])

  windo diffoff
  close!
  set nomodified
endfunc

func Test_vert_split()
  set diffopt=filler
  call Common_vert_split()
  set diffopt&
endfunc

func Test_vert_split_internal()
  set diffopt=internal,filler
  call Common_vert_split()
  set diffopt&
endfunc

func Common_vert_split()
  " Disable the title to avoid xterm keeping the wrong one.
  set notitle noicon
  new
  let l = ['1 aa', '2 bb', '3 cc', '4 dd', '5 ee']
  call setline(1, l)
  w! Xtest
  normal dd
  $
  put
  normal kkrXoxxx
  w! Xtest2
  file Nop
  normal ggoyyyjjjozzzz
  set foldmethod=marker foldcolumn=4
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  vert diffsplit Xtest
  vert diffsplit Xtest2
  call assert_equal(1, &diff)
  call assert_equal('diff', &foldmethod)
  call assert_equal(2, &foldcolumn)
  call assert_equal(1, &scrollbind)
  call assert_equal(1, &cursorbind)
  call assert_equal(0, &wrap)

  let diff_fdm = &fdm
  let diff_fdc = &fdc
  " repeat entering diff mode here to see if this saves the wrong settings
  diffthis
  " jump to second window for a moment to have filler line appear at start of
  " first window
  wincmd w
  normal gg
  wincmd p
  normal gg
  call assert_equal(2, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(6, winline())
  normal j
  call assert_equal(8, winline())
  normal j
  call assert_equal(9, winline())

  wincmd w
  normal gg
  call assert_equal(1, winline())
  normal j
  call assert_equal(2, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(8, winline())

  wincmd w
  normal gg
  call assert_equal(2, winline())
  normal j
  call assert_equal(3, winline())
  normal j
  call assert_equal(4, winline())
  normal j
  call assert_equal(5, winline())
  normal j
  call assert_equal(6, winline())
  normal j
  call assert_equal(7, winline())
  normal j
  call assert_equal(8, winline())

  " Test diffoff
  diffoff!
  1wincmd 2
  let &diff = 1
  let &fdm = diff_fdm
  let &fdc = diff_fdc
  4wincmd w
  diffoff!
  1wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  wincmd w
  call assert_equal(0, &diff)
  call assert_equal('marker', &foldmethod)
  call assert_equal(4, &foldcolumn)
  call assert_equal(0, &scrollbind)
  call assert_equal(0, &cursorbind)
  call assert_equal(1, &wrap)

  call delete('Xtest')
  call delete('Xtest2')
  windo bw!
endfunc

func Test_filler_lines()
  " Test that diffing shows correct filler lines
  enew!
  put =range(4,10)
  1d _
  vnew
  put =range(1,10)
  1d _
  windo diffthis
  wincmd h
  call assert_equal(1, line('w0'))
  unlet! diff_fdm diff_fdc
  windo diffoff
  bwipe!
  enew!
endfunc

func Test_diffget_diffput()
  enew!
  let l = range(50)
  call setline(1, l)
  call assert_fails('diffget', 'E99:')
  diffthis
  call assert_fails('diffget', 'E100:')
  new
  let l[10] = 'one'
  let l[20] = 'two'
  let l[30] = 'three'
  let l[40] = 'four'
  call setline(1, l)
  diffthis
  call assert_equal('one', getline(11))
  11diffget
  call assert_equal('10', getline(11))
  21diffput
  wincmd w
  call assert_equal('two', getline(21))
  normal 31Gdo
  call assert_equal('three', getline(31))
  call assert_equal('40', getline(41))
  normal 41Gdp
  wincmd w
  call assert_equal('40', getline(41))
  new
  diffthis
  call assert_fails('diffget', 'E101:')

  windo diffoff
  %bwipe!
endfunc

func Test_dp_do_buffer()
  e! one
  let bn1=bufnr('%')
  let l = range(60)
  call setline(1, l)
  diffthis

  new two
  let l[10] = 'one'
  let l[20] = 'two'
  let l[30] = 'three'
  let l[40] = 'four'
  let l[50] = 'five'
  call setline(1, l)
  diffthis

  " dp and do with invalid buffer number.
  11
  call assert_fails('norm 99999dp', 'E102:')
  call assert_fails('norm 99999do', 'E102:')
  call assert_fails('diffput non_existing_buffer', 'E94:')
  call assert_fails('diffget non_existing_buffer', 'E94:')

  " dp and do with valid buffer number.
  call assert_equal('one', getline('.'))
  exe 'norm ' . bn1 . 'do'
  call assert_equal('10', getline('.'))
  21
  call assert_equal('two', getline('.'))
  diffget one
  call assert_equal('20', getline('.'))

  31
  exe 'norm ' . bn1 . 'dp'
  41
  diffput one
  wincmd w
  31
  call assert_equal('three', getline('.'))
  41
  call assert_equal('four', getline('.'))

  " dp and do with buffer number which is not in diff mode.
  new not_in_diff_mode
  let bn3=bufnr('%')
  wincmd w
  51
  call assert_fails('exe "norm" . bn3 . "dp"', 'E103:')
  call assert_fails('exe "norm" . bn3 . "do"', 'E103:')
  call assert_fails('diffput not_in_diff_mode', 'E94:')
  call assert_fails('diffget not_in_diff_mode', 'E94:')

  windo diffoff
  %bwipe!
endfunc

func Test_diffoff()
  enew!
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new
  call setline(1, ['One', '', 'Two', 'Three'])
  diffthis
  redraw
  call assert_notequal(normattr, screenattr(1, 1))
  diffoff!
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  bwipe!
  bwipe!
endfunc

func Common_icase_test()
  edit one
  call setline(1, ['One', 'Two', 'Three', 'Four', 'Fi#ve'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new two
  call setline(1, ['one', 'TWO', 'Three ', 'Four', 'fI=VE'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_notequal(normattr, screenattr(3, 1))
  call assert_equal(normattr, screenattr(4, 1))

  let dtextattr = screenattr(5, 3)
  call assert_notequal(dtextattr, screenattr(5, 1))
  call assert_notequal(dtextattr, screenattr(5, 5))

  diffoff!
  %bwipe!
endfunc

func Test_diffopt_icase()
  set diffopt=icase,foldcolumn:0
  call Common_icase_test()
  set diffopt&
endfunc

func Test_diffopt_icase_internal()
  set diffopt=icase,foldcolumn:0,internal
  call Common_icase_test()
  set diffopt&
endfunc

func Common_iwhite_test()
  edit one
  " Difference in trailing spaces and amount of spaces should be ignored,
  " but not other space differences.
  call setline(1, ["One \t", 'Two', 'Three', 'one two', 'one two', 'Four'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new two
  call setline(1, ["One\t ", "Two\t ", 'Three', 'one   two', 'onetwo', ' Four'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_equal(normattr, screenattr(3, 1))
  call assert_equal(normattr, screenattr(4, 1))
  call assert_notequal(normattr, screenattr(5, 1))
  call assert_notequal(normattr, screenattr(6, 1))

  diffoff!
  %bwipe!
endfunc

func Test_diffopt_iwhite()
  set diffopt=iwhite,foldcolumn:0
  call Common_iwhite_test()
  set diffopt&
endfunc

func Test_diffopt_iwhite_internal()
  set diffopt=internal,iwhite,foldcolumn:0
  call Common_iwhite_test()
  set diffopt&
endfunc

func Test_diffopt_context()
  enew!
  call setline(1, ['1', '2', '3', '4', '5', '6', '7'])
  diffthis
  new
  call setline(1, ['1', '2', '3', '4', '5x', '6', '7'])
  diffthis

  set diffopt=context:2
  call assert_equal('+--  2 lines: 1', foldtextresult(1))
  set diffopt=internal,context:2
  call assert_equal('+--  2 lines: 1', foldtextresult(1))

  set diffopt=context:1
  call assert_equal('+--  3 lines: 1', foldtextresult(1))
  set diffopt=internal,context:1
  call assert_equal('+--  3 lines: 1', foldtextresult(1))

  diffoff!
  %bwipe!
  set diffopt&
endfunc

func Test_diffopt_horizontal()
  set diffopt=internal,horizontal
  diffsplit

  call assert_equal(&columns, winwidth(1))
  call assert_equal(&columns, winwidth(2))
  call assert_equal(&lines, winheight(1) + winheight(2) + 3)
  call assert_inrange(0, 1, winheight(1) - winheight(2))

  set diffopt&
  diffoff!
  %bwipe
endfunc

func Test_diffopt_vertical()
  set diffopt=internal,vertical
  diffsplit

  call assert_equal(&lines - 2, winheight(1))
  call assert_equal(&lines - 2, winheight(2))
  call assert_equal(&columns, winwidth(1) + winwidth(2) + 1)
  call assert_inrange(0, 1, winwidth(1) - winwidth(2))

  set diffopt&
  diffoff!
  %bwipe
endfunc

func Test_diffopt_hiddenoff()
  set diffopt=internal,filler,foldcolumn:0,hiddenoff
  e! one
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new two
  call setline(1, ['One', 'Four'])
  diffthis
  redraw
  call assert_notequal(normattr, screenattr(1, 1))
  set hidden
  close
  redraw
  " should not diffing with hidden buffer two while 'hiddenoff' is enabled
  call assert_equal(normattr, screenattr(1, 1))

  bwipe!
  bwipe!
  set hidden& diffopt&
endfunc

func Test_diffoff_hidden()
  set diffopt=internal,filler,foldcolumn:0
  e! one
  call setline(1, ['Two', 'Three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis
  botright vert new two
  call setline(1, ['One', 'Four'])
  diffthis
  redraw
  call assert_notequal(normattr, screenattr(1, 1))
  set hidden
  close
  redraw
  " diffing with hidden buffer two
  call assert_notequal(normattr, screenattr(1, 1))
  diffoff
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  diffthis
  redraw
  " still diffing with hidden buffer two
  call assert_notequal(normattr, screenattr(1, 1))
  diffoff!
  redraw
  call assert_equal(normattr, screenattr(1, 1))
  diffthis
  redraw
  " no longer diffing with hidden buffer two
  call assert_equal(normattr, screenattr(1, 1))

  bwipe!
  bwipe!
  set hidden& diffopt&
endfunc

func Test_setting_cursor()
  new Xtest1
  put =range(1,90)
  wq
  new Xtest2
  put =range(1,100)
  wq

  tabe Xtest2
  $
  diffsp Xtest1
  tabclose

  call delete('Xtest1')
  call delete('Xtest2')
endfunc

func Test_diff_move_to()
  new
  call setline(1, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  diffthis
  vnew
  call setline(1, [1, '2x', 3, 4, 4, 5, '6x', 7, '8x', 9, '10x'])
  diffthis
  norm ]c
  call assert_equal(2, line('.'))
  norm 3]c
  call assert_equal(9, line('.'))
  norm 10]c
  call assert_equal(11, line('.'))
  norm [c
  call assert_equal(9, line('.'))
  norm 2[c
  call assert_equal(5, line('.'))
  norm 10[c
  call assert_equal(2, line('.'))
  %bwipe!
endfunc

func Test_diffexpr()
  if !executable('diff')
    return
  endif

  func DiffExpr()
    " Prepent some text to check diff type detection
    call writefile(['warning', '  message'], v:fname_out)
    silent exe '!diff ' . v:fname_in . ' ' . v:fname_new . '>>' . v:fname_out
  endfunc
  set diffexpr=DiffExpr()
  set diffopt=foldcolumn:0

  enew!
  call setline(1, ['one', 'two', 'three'])
  redraw
  let normattr = screenattr(1, 1)
  diffthis

  botright vert new
  call setline(1, ['one', 'two', 'three.'])
  diffthis

  redraw
  call assert_equal(normattr, screenattr(1, 1))
  call assert_equal(normattr, screenattr(2, 1))
  call assert_notequal(normattr, screenattr(3, 1))

  diffoff!
  %bwipe!
  set diffexpr& diffopt&
endfunc

func Test_diffpatch()
  " The patch program on MS-Windows may fail or hang.
  if !executable('patch') || !has('unix')
    return
  endif
  new
  insert
***************
*** 1,3 ****
  1
! 2
  3
--- 1,4 ----
  1
! 2x
  3
+ 4
.
  saveas! Xpatch
  bwipe!
  new
  call assert_fails('diffpatch Xpatch', 'E816:')

  for name in ['Xpatch', 'Xpatch$HOME', 'Xpa''tch']
    call setline(1, ['1', '2', '3'])
    if name != 'Xpatch'
      call rename('Xpatch', name)
    endif
    exe 'diffpatch ' . escape(name, '$')
    call assert_equal(['1', '2x', '3', '4'], getline(1, '$'))
    if name != 'Xpatch'
      call rename(name, 'Xpatch')
    endif
    bwipe!
  endfor

  call delete('Xpatch')
  bwipe!
endfunc

func Test_diff_too_many_buffers()
  for i in range(1, 8)
    exe "new Xtest" . i
    diffthis
  endfor
  new Xtest9
  call assert_fails('diffthis', 'E96:')
  %bwipe!
endfunc

func Test_diff_nomodifiable()
  new
  call setline(1, [1, 2, 3, 4])
  setl nomodifiable
  diffthis
  vnew
  call setline(1, ['1x', 2, 3, 3, 4])
  diffthis
  call assert_fails('norm dp', 'E793:')
  setl nomodifiable
  call assert_fails('norm do', 'E21:')
  %bwipe!
endfunc

func Test_diff_hlID()
  new
  call setline(1, [1, 2, 3])
  diffthis
  vnew
  call setline(1, ['1x', 2, 'x', 3])
  diffthis
  redraw

  call assert_equal(synIDattr(diff_hlID(-1, 1), "name"), "")

  call assert_equal(synIDattr(diff_hlID(1, 1), "name"), "DiffChange")
  call assert_equal(synIDattr(diff_hlID(1, 2), "name"), "DiffText")
  call assert_equal(synIDattr(diff_hlID(2, 1), "name"), "")
  call assert_equal(synIDattr(diff_hlID(3, 1), "name"), "DiffAdd")
  call assert_equal(synIDattr(diff_hlID(4, 1), "name"), "")

  wincmd w
  call assert_equal(synIDattr(diff_hlID(1, 1), "name"), "DiffChange")
  call assert_equal(synIDattr(diff_hlID(2, 1), "name"), "")
  call assert_equal(synIDattr(diff_hlID(3, 1), "name"), "")

  %bwipe!
endfunc

func Test_diff_filler()
  new
  call setline(1, [1, 2, 3, 'x', 4])
  diffthis
  vnew
  call setline(1, [1, 2, 'y', 'y', 3, 4])
  diffthis
  redraw

  call assert_equal([0, 0, 0, 0, 0, 0, 0, 1, 0], map(range(-1, 7), 'diff_filler(v:val)'))
  wincmd w
  call assert_equal([0, 0, 0, 0, 2, 0, 0, 0], map(range(-1, 6), 'diff_filler(v:val)'))

  %bwipe!
endfunc

func Test_diff_lastline()
  enew!
  only!
  call setline(1, ['This is a ', 'line with five ', 'rows'])
  diffthis
  botright vert new
  call setline(1, ['This is', 'a line with ', 'four rows'])
  diffthis
  1
  call feedkeys("Je a\<CR>", 'tx')
  call feedkeys("Je a\<CR>", 'tx')
  let w1lines = winline()
  wincmd w
  $
  let w2lines = winline()
  call assert_equal(w2lines, w1lines)
  bwipe!
  bwipe!
endfunc

func WriteDiffFiles(list1, list2)
  call writefile(a:list1, 'Xfile1')
  call writefile(a:list2, 'Xfile2')
endfunc

" Verify a screendump with both the external and external diff.
func VerifyBoth(buf, dumpfile, extra)
  call term_sendkeys(a:buf, ":diffupdate!\<cr>")
  " trailing : for leaving the cursor on the command line
  for cmd in [":set diffopt=filler" . a:extra . "\<cr>:", ":set diffopt+=internal\<cr>:"]
    call term_sendkeys(a:buf, cmd)
    if VerifyScreenDump(a:buf, a:dumpfile, {}, cmd =~ 'internal' ? 'internal' : 'external')
      break " don't let the next iteration overwrite the "failed" file.
    endif
  endfor
endfunc

func Test_diff_screen()
  if !CanRunVimInTerminal() || !has('menu')
    return
  endif
  " clean up already existing swap files, just in case
  call delete('.Xfile1.swp')
  call delete('.Xfile2.swp')

  " Test 1: Add a line in beginning of file 2
  call WriteDiffFiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  let buf = RunVimInTerminal('-d Xfile1 Xfile2', {})
  " Set autoread mode, ,so that Vim won't complain once we re-write the test
  " files
  call term_sendkeys(buf, ":set autoread\<cr>\<c-w>w:set autoread\<cr>\<c-w>w")

  call VerifyBoth(buf, 'Test_diff_01', '')

  " Test 2: Add a line in beginning of file 1
  call WriteDiffFiles([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_02', '')

  " Test 3: Add a line at the end of file 2
  call WriteDiffFiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
  call VerifyBoth(buf, 'Test_diff_03', '')

  " Test 4: Add a line at the end of file 1
  call WriteDiffFiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_04', '')

  " Test 5: Add a line in the middle of file 2, remove on at the end of file 1
  call WriteDiffFiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11], [1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_05', '')

  " Test 6: Add a line in the middle of file 1, remove on at the end of file 2
  call WriteDiffFiles([1, 2, 3, 4, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11])
  call VerifyBoth(buf, 'Test_diff_06', '')

  " Test 7 - 9: Test normal/patience/histogram diff algorithm
  call WriteDiffFiles(['#include <stdio.h>', '', '// Frobs foo heartily', 'int frobnitz(int foo)', '{',
      \ '    int i;', '    for(i = 0; i < 10; i++)', '    {', '        printf("Your answer is: ");',
      \ '        printf("%d\n", foo);', '    }', '}', '', 'int fact(int n)', '{', '    if(n > 1)', '    {',
      \ '        return fact(n-1) * n;', '    }', '    return 1;', '}', '', 'int main(int argc, char **argv)',
      \ '{', '    frobnitz(fact(10));', '}'],
      \ ['#include <stdio.h>', '', 'int fib(int n)', '{', '    if(n > 2)', '    {',
      \ '        return fib(n-1) + fib(n-2);', '    }', '    return 1;', '}', '', '// Frobs foo heartily',
      \ 'int frobnitz(int foo)', '{', '    int i;', '    for(i = 0; i < 10; i++)', '    {',
      \ '        printf("%d\n", foo);', '    }', '}', '',
      \ 'int main(int argc, char **argv)', '{', '    frobnitz(fib(10));', '}'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_07', {})

  call term_sendkeys(buf, ":set diffopt+=algorithm:patience\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_08', {})

  call term_sendkeys(buf, ":set diffopt+=algorithm:histogram\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_09', {})

  " Test 10-11: normal/indent-heuristic
  call term_sendkeys(buf, ":set diffopt&vim\<cr>")
  call WriteDiffFiles(['', '  def finalize(values)', '', '    values.each do |v|', '      v.finalize', '    end'],
      \ ['', '  def finalize(values)', '', '    values.each do |v|', '      v.prepare', '    end', '',
      \ '    values.each do |v|', '      v.finalize', '    end'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_10', {})

  call term_sendkeys(buf, ":set diffopt+=indent-heuristic\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_11', {})

  " Test 12: diff the same file
  call WriteDiffFiles([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 2, 3, 4, 5, 6, 7, 8, 9, 10])
  call VerifyBoth(buf, 'Test_diff_12', '')

  " Test 13: diff an empty file
  call WriteDiffFiles([], [])
  call VerifyBoth(buf, 'Test_diff_13', '')

  " Test 14: test diffopt+=icase
  call WriteDiffFiles(['a', 'b', 'cd'], ['A', 'b', 'cDe'])
  call VerifyBoth(buf, 'Test_diff_14', " diffopt+=filler diffopt+=icase")

  " Test 15-16: test diffopt+=iwhite
  call WriteDiffFiles(['int main()', '{', '   printf("Hello, World!");', '   return 0;', '}'],
      \ ['int main()', '{', '   if (0)', '   {', '      printf("Hello, World!");', '      return 0;', '   }', '}'])
  call term_sendkeys(buf, ":diffupdate!\<cr>")
  call term_sendkeys(buf, ":set diffopt&vim diffopt+=filler diffopt+=iwhite\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_15', {})
  call term_sendkeys(buf, ":set diffopt+=internal\<cr>")
  call VerifyScreenDump(buf, 'Test_diff_16', {})

  " clean up
  call StopVimInTerminal(buf)
  call delete('Xfile1')
  call delete('Xfile2')
endfunc

