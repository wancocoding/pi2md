" vim:set ft=vim et sts=4 sw=4 ts=4 tw=78:
"
" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <http://cocoding.cc>
" Create date:		Sep 28, 2020
" Update date:		Nov 03, 2020
"
" Settings Example 
" more example, please see readme
"
"
" let g:pi2mdSettings = {
" \ 'debug': 1,
" \ 'storage': 0,
" \ 'storage_local_position_type': 0,
" \ 'storage_local_dir_name': 'images',
" \ 'storage_local_absolute_path': '/User/yourname/your_images_path',
" \ 'storage_local_prefer_relative_path': 1,
" \ 'storage_cloud_tool': 'picgo-core',
" \ 'storage_cloud_picgocore_path': 
" \     'd:\develop\Scoop\apps\nodejs-lts\current\bin\picgo.cmd'
" }



if exists('did_load_plugin_pi2md') || &cp
    finish
endif
let did_load_plugin_pi2md = 1

if version < 801
   echohl WarningMsg
   echom  "Pi2md requires Vim >= 8.1"
   echohl None
   finish
endif


" ==========================================================
" Bind Commands
" ==========================================================
command! -nargs=* Pi2md call pi2md#Pi2md(<q-args>)
