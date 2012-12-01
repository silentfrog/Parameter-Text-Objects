" A Vim plugin that defines a parameter text object.
" Maintainer: David Larson <david@thesilverstream.com>
" Last Change: Mar 15, 2010
"
" This script defines a parameter text object. A parameter is the text between
" parentheses or commas, typically found in a function's argument list.
"
" See:
" :help text-objects
"   for a description of what can be done with text objects.
" Also See:
" :help a(
"   If you want to operate on the parentheses also.
"
" Like all the other text-objects, a parameter text object can be selected
" following these commands: 'd', 'c', 'y', 'v', etc. The script defines these
" operator mappings:
"
"    aa    "an argument", select an argument, including one comma (if there is
"          one).
"
"    ia    "inner argument", selectn a argument, not including commas.
"
" If you would like to remap the commands then you can prevent the default
" mappings from getting set if you set g:no_parameter_object_maps = 1 in your
" .vimrc file. Then remap the commands as desired, like this:
"
"    let g:no_parameter_object_maps = 1
"    vmap     <silent> ia <Plug>ParameterObjectI
"    omap     <silent> ia <Plug>ParameterObjectI
"    vmap     <silent> aa <Plug>ParameterObjectA
"    omap     <silent> aa <Plug>ParameterObjectA

if exists("loaded_parameter_objects") || &cp || v:version < 701
  finish
endif
let loaded_parameter_objects = 1

vnoremap <silent> <script> <Plug>ParameterObjectI :<C-U>call <SID>parameter_object("i")<cr>
onoremap <silent> <script> <Plug>ParameterObjectI :call <SID>parameter_object("i")<cr>
vnoremap <silent> <script> <Plug>ParameterObjectA :<C-U>call <SID>parameter_object("a")<cr>
onoremap <silent> <script> <Plug>ParameterObjectA :call <SID>parameter_object("a")<cr>

vnoremap <script> <Plug>Focus :<C-U>call <SID>focus_on_param()<cr>
onoremap <script> <Plug>Focus :call <SID>focus_on_param()<cr>
noremap <script> <Plug>Focus :call <SID>focus_on_param()<cr>

vnoremap <script> <Plug>NextParam :<C-U>call <SID>next_param()<cr>
onoremap <script> <Plug>NextParam :call <SID>next_param()<cr>
noremap <script> <Plug>NextParam :call <SID>next_param()<cr>

vnoremap <script> <Plug>PrevParam :<C-U>call <SID>prev_param()<cr>
onoremap <script> <Plug>PrevParam :call <SID>prev_param()<cr>
noremap <script> <Plug>PrevParam :call <SID>prev_param()<cr>

if !exists("g:no_parameter_object_maps") || !g:no_parameter_object_maps
  vmap     <silent> ia <Plug>ParameterObjectI
  omap     <silent> ia <Plug>ParameterObjectI
  vmap     <silent> aa <Plug>ParameterObjectA
  omap     <silent> aa <Plug>ParameterObjectA
  vmap     <leader>p <Plug>Focus
  omap     <leader>p <Plug>Focus
  map      <leader>p <Plug>Focus
  vmap     <leader>. <Plug>NextParam
  omap     <leader>. <Plug>NextParam
  map      <leader>. <Plug>NextParam
  vmap     <leader>' <Plug>PrevParam
  omap     <leader>' <Plug>PrevParam
  map      <leader>' <Plug>PrevParam
endif

function! s:MoveToNextNonSpace()
  let oldp = getpos('.')
  while strlen(getline('.')) < getpos('.')[2] || getline('.')[getpos('.')[2]-1]==' '
    normal! l
    if oldp == getpos('.')
      break
    endif
    let oldp = getpos('.')
  endwhile
endfunction

function! s:next_param()
  let whichwrap_save = &whichwrap
  set whichwrap+=h,l
  let ve_save = &ve
  set virtualedit=onemore
  let k_save = @k
  let l_save = @l
  let m_save = @m
  try
    let [ok, gotone] = <SID>find_param("i")
    if ok == 1
    normal `ml
    call <SID>MoveToNextNonSpace()
    endif
  finally
    let &ve = ve_save
    let @k = k_save
    let @l = l_save
    let @m = m_save
    let &whichwrap=whichwrap_save
  endtry
endfunction

function! s:prev_param()
  let whichwrap_save = &whichwrap
  set whichwrap+=h,l
  let ve_save = &ve
  set virtualedit=onemore
  let k_save = @k
  let l_save = @l
  let m_save = @m
  try
    let [ok, gotone] = <SID>find_param("i")
    if ok == 1
      normal! `kh
      call <SID>focus_on_param()
    endif
  finally
    let &ve = ve_save
    let @k = k_save
    let @l = l_save
    let @m = m_save
    let &whichwrap=whichwrap_save
  endtry
endfunction

function! s:focus_on_param()
  let whichwrap_save = &whichwrap
  set whichwrap+=h,l
  let ve_save = &ve
  set virtualedit=onemore
  let k_save = @k
  let l_save = @l
  let m_save = @m
  try
    let [ok, gotone] = <SID>find_param("i")
    if ok != 1
      return
    endif
    normal! `l
  finally
    let &ve = ve_save
    let @k = k_save
    let @l = l_save
    let @m = m_save
    let &whichwrap=whichwrap_save
  endtry
endfunction

function! s:parameter_object(mode)
  let whichwrap_save = &whichwrap
  set whichwrap+=h,l
  let ve_save = &ve
  set virtualedit=onemore
  let k_save = @k
  let l_save = @l
  let m_save = @m
  try
    let [ok, gotone] = <SID>find_param(a:mode)
    if ok != 1
      return
    endif
    if a:mode == "a" && @l == ',' && !gotone
      normal! l
      call <SID>MoveToNextNonSpace()
      normal! h
    else
      normal! h
    endif
    normal! v`l
  finally
    let &ve = ve_save
    let @k = k_save
    let @l = l_save
    let @m = m_save
    let &whichwrap=whichwrap_save
  endtry
endfunction

function! s:find_param(mode)
  " Search for the start of the parameter text object
  if searchpair('(', ',', ')', 'bWs', "s:skip()") <= 0
    return [0, 0]
  endif

  normal! "lylmk
  if a:mode == "a" && @l == ','
    echo "!".@l
    let gotone = 1
    normal! ml
  else
    normal! lmlh
    if a:mode =="i"
      normal! lmm
      call <SID>MoveToNextNonSpace()
      normal! ml
      normal! `m
    endif
  endif

  let c = v:count1
  while c
    " Search for the end of the parameter text object
    if searchpair('(',',',')', 'W', "s:skip()") <= 0
      normal! `'
      return [0, 0]
    endif
    normal! "lyl
    if @l == ')' && c > 1
      " found the last parameter when more is asked for, so abort
      normal! `'
      return [0, 0]
    endif
    let c -= 1
  endwhile
  normal! mm
  return [1, exists("gotone")]
endfunction

function! s:skip()
  let name = synIDattr(synID(line("."), col("."), 0), "name")
  if name =~? "comment"
    return 1
  elseif name =~? "string"
    return 1
  endif
  return 0
endfunction

" vim:fdm=marker fmr=function\ ,endfunction
