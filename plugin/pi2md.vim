" vim:set ft=vim et sts=4 sw=4 ts=4 tw=78:
"
" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <http://cocoding.cc>
" Create date:		Sep 28, 2020
" Update date:		Nov 06, 2020
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

if has('nvim')
    let s:has_features = has('timers') && has('nvim-0.2.1') && has('python3')
else
    let s:has_features = v:version >= 801 && has('python3') && has('timers')
        \ && exists('*job_start')
endif



if !s:has_features
   echohl WarningMsg
   echom  "Pi2md equires NeoVim >= 0.2.1 or Vim 8 with +timers +job +channel +python3"
   echohl None
   finish
endif

let did_load_plugin_pi2md = 1

" ==========================================================
" Bind Commands
" ==========================================================
command! -nargs=* Pi2md call pi2md#Pi2md(<q-args>)
