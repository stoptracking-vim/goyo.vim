" Copyright (c) 2013 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:cpo_save = &cpo
set cpo&vim

function! s:get_color(group, attr)
  return synIDattr(synIDtrans(hlID(a:group)), a:attr)
endfunction

function! s:set_color(group, attr, color)
  let gui = has('gui_running')
  execute printf("hi %s %s%s=%s", a:group, gui ? 'gui' : 'cterm', a:attr, a:color)
endfunction

function! s:blank()
  let main = bufwinnr(t:goyo_master)
  if main != -1
    execute main . 'wincmd w'
  else
    call s:goyo_off()
  endif
endfunction

function! s:init_pad(command)
  execute a:command

  setlocal buftype=nofile bufhidden=wipe nomodifiable nobuflisted noswapfile
        \ nonu nocursorline laststatus=0 colorcolumn=
        \ statusline=\  winwidth=1 winheight=1
  let bufnr = winbufnr(0)

  execute winnr('#') . 'wincmd w'
  return bufnr
endfunction

function! s:setup_pad(bufnr, vert, size)
  let win = bufwinnr(a:bufnr)
  execute win . 'wincmd w'
  execute (a:vert ? 'vertical ' : '') . 'resize ' . max([0, a:size])
  autocmd WinEnter <buffer> call s:blank()
  execute winnr('#') . 'wincmd w'
endfunction

function! s:hmargin()
  let nwidth = max([len(string(line('$'))) + 1, &numberwidth])
  let width  = get(g:, 'goyo_width', 80) + (&number ? nwidth : 0)
  return (&columns - width)
endfunction

function! s:resize_pads(pads)
  let hmargin = s:hmargin()
  let tmargin = get(g:, 'goyo_margin_top', 4)
  let bmargin = get(g:, 'goyo_margin_bottom', 4)

  call s:setup_pad(a:pads.l, 1, hmargin / 2 - 1)
  call s:setup_pad(a:pads.r, 1, hmargin / 2 - 1)
  call s:setup_pad(a:pads.t, 0, tmargin - 1)
  call s:setup_pad(a:pads.b, 0, bmargin - 2)
endfunction

function! s:tranquilize()
  let bg = s:get_color('Normal', 'bg')
  for grp in ['NonText', 'FoldColumn', 'ColorColumn', 'VertSplit',
            \ 'StatusLine', 'StatusLineNC']
    call s:set_color(grp, 'fg', bg)
    call s:set_color(grp, 'bg', bg)
  endfor
endfunction

function! s:goyo_on()
  " New tab
  tab split

  let t:goyo_master = winbufnr(0)
  setlocal nonu nornu

  let pads = {}
  let t:goyo_revert =
    \ { 'laststatus': &l:laststatus, 'statusline': &l:statusline,
    \   'showtabline': &showtabline, 'colorcolumn': &l:colorcolumn }

  let pads.l = s:init_pad('vertical new')
  let pads.r = s:init_pad('vertical rightbelow new')
  let pads.t = s:init_pad('topleft new')
  let pads.b = s:init_pad('botright new')
  call s:resize_pads(pads)

  augroup goyo
    autocmd!
    autocmd  TabLeave,BufDelete,BufHidden,BufUnload <buffer> call s:goyo_off()
    autocmd  VimResized  * call s:resize_pads(get(t:, 'goyo_pads', {}))
    autocmd  ColorScheme * call s:tranquilize()
  augroup END

  call s:tranquilize()

  setlocal colorcolumn=
  setlocal laststatus=0
  setlocal statusline=\ 
  setlocal showtabline=0

  let t:goyohan = 1
  let t:goyo_pads = pads
endfunction

function! s:goyo_off()
  augroup goyo
    autocmd!
  augroup END

  if !exists('t:goyohan')
    return
  endif

  for [k, v] in items(t:goyo_revert)
    execute printf("setlocal %s=%s", k, v)
  endfor
  execute 'colo '. g:colors_name

  if tabpagenr() == 1
    tabnew
    normal! gt
    bd
  endif
  tabclose

endfunction

function! s:goyo()
  if get(t:, 'goyohan', 0) == 0
    call s:goyo_on()
  else
    call s:goyo_off()
  end
endfunction

command! Goyo call s:goyo()

let &cpo = s:cpo_save
unlet s:cpo_save

