" vim:set ft=vim et sts=4 sw=4 ts=4 tw=78:
"
" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <http://cocoding.cc>
" Create date:		Sep 28, 2020
" Update date:		Oct 20, 2020
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




" Configuration

" the configuration constraint
let s:pi2mdConfigConstraint = {
	\ 'debug': {
	\	'legalRange': [0, 1], 
	\	'default': 1, 
	\	'required': 1,
	\	'errorMsg': 'the value of debug config must be 0 or 1'}, 
	\ 'storage': { 
	\	'legalRange': [0, 1], 
	\	'default': 0, 
	\	'required': 1,
	\	'errorMsg': 'the value of storage config must be 0 or 1'},
	\ 'storage_local_position_type': {
	\	'legalRange': [0, 1], 
	\	'default': 0, 
	\	'required': 1,
	\	'errorMsg': 'the value of local position type config must be 0 or 1'},
	\ 'storage_local_prefer_relative_path': {
	\	'legalRange': [0, 1], 
	\	'default': 1, 
	\	'required': 0,
	\	'errorMsg': 'the value of use relative path config must be 0 or 1'},
	\ 'storage_cloud_tool': {
	\	'legalRange': ['picgo-core', 'picgo', 'upic'], 
	\	'default': 'picgo-core', 
	\	'required': 0,
	\	'depends': {'itemKey': 'storage', 'itemVal': 1},
	\	'errorMsg': 'the value of cloud lib config must be one of picgo-core,
			\ picgo or upic'},
	\ 'storage_cloud_picgocore_path': {
	\	'default': 'picgo', 
	\	'required': 0,
	\	'isPath': 1,
	\	'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo-core'},
	\	'errorMsg': 'you must define your picgo-core bin path,
			\ if you use cloud by picgo-core'},
    \ 'storage_cloud_picgoapp_node_path': {
        \ 'default': 'node',
        \ 'required': 0,
        \ 'isPath': 1,
        \ 'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo'},
        \ 'errorMsg': 'you must define the right nodejs bin path,
            \ if you want to use picgo app'},
    \ 'storage_cloud_picgoapp_api_server_port': {
        \ 'default': '36677',
        \ 'required': 0,
        \ 'depends': {'itemKey': 'storage_cloud_tool', 'itemVal': 'picgo'},
        \ 'errorMsg': 'the picgo api server default port is [36677],
            \ if not, please set port in your settings!'}
\ }


let s:Errors = {
	\ 'E-PIM-10': 'Configuration error',
	\ 'E-PIM-11': 'Configuration item error',
	\ 'E-PIM-12': 'There are no images in your system clipbord!',
	\ 'E-PIM-13': 'The python module PIL could not found,
	\   Please install it with pip',
	\ 'E-PIM-14': 'Your system does not have python3 installed or
	\   python3 and python3x.dll are not in the PATH',
	\ 'E-PIM-15': 'Sorry, The filetype of current buffer
	\   does not support right now',
    \ 'E-PIM-16': 'An error occurred while proccessing files',
    \ 'E-PIM-17': 'Upload to the cloud by picgo-core failed, 
    \   please see the log messages.',
    \ 'E-PIM-18': 'Picgo App upload failed, please check your picgo config,
    \   or report issue',
    \ 'E-PIM-19': 'Picgo App upload failed',
    \ 'E-PIM-20': 'Invalid argument for Pi2md!',
    \ 'E-PIM-21': 'The image file does not exist!',
    \ 'E-PIM-22': 'The picgo server is not available,
    \   please check your settings',
    \ 'E-PIM-23': 'Error occurred when execute system cmd!',
    \ 'E-PIM-24': 'Error occurred when execute systemlist cmd!'
	\ }

" ==========================================================
" Init Variables " 
" ==========================================================
let s:scriptRoot = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')

let s:settings = {}

function! s:settings.initPi2md() dict
	try
		" add more variables
		call self.checkConfiguration()
		call self.checkPy3()
		call s:utilityTools.detectOS()
		let g:pi2mdSettings['os'] = s:os

		" get the pi2md plugin root absolute path
		" let s:pi2md_root_full_path = fnamemodify(resolve(
		" 			\ expand('<sfile>:p')), ':h:h')
		let g:pi2mdSettings['pi2md_root'] = s:scriptRoot
	catch /.*/
		call s:logger.errorMsg('Caught "' . v:exception . '" in [iniPi2md]')
		throw 'E-PIM-10'
	endtry
endfunction

function s:settings.checkPy3() dict
	if !has('python3')
		throw 'E-PIM-14'
	endif
	" check module
	try
python3 << EOF
import PIL
EOF
	catch 'Vim(python3):ModuleNotFoundError: No module named \'PIL\''
		throw 'E-PIM-13'
	endtry
endfunction

" make sure all configuration is right
function! s:settings.checkConfiguration() dict
	if !exists('g:pi2mdSettings')
		" setting some default configuration
		let g:pi2mdSettings = {
			\ 'debug': 1,
			\ 'storage': 0,
			\ 'storage_local_position_type': 0,
			\ 'storage_local_dir_name': 'images',
			\ 'storage_local_prefer_relative_path': 1}
	else
		" check configuration , make sure all settings are correct
		for ckey in keys(s:pi2mdConfigConstraint)
			try
				call self.checkConfigItem(ckey)
			catch /.*/ 
				call s:logger.errorMsg('Caught "' . v:exception .
					\ '" in [checkConfiguration], error item is' . ckey)
				throw 'E-PIM-11'
			endtry
		endfor
	endif
endfunction

function s:settings.checkConfigItem(itemKey) dict
	let settingConstraint = s:pi2mdConfigConstraint[a:itemKey]
	" check if exists in global configuration
	" chech required and depends
	let hasError = 0
	" =================== check the config not defined
	if !has_key(g:pi2mdSettings, a:itemKey) && settingConstraint.required == 1
		" set default value if not exist
		if has_key(settingConstraint, 'default')
			let g:pi2mdSettings[a:itemKey] = settingConstraint.default
		else
			let hasError = 1
		endif
	elseif !has_key(g:pi2mdSettings, a:itemKey)
		\ && settingConstraint.required == 0
		" check depends
		if has_key(settingConstraint, 'depends')
			" get depends
			let depends = settingConstraint.depends
			" get depend key 
			let dependKey = depends['itemKey']
			let dependVal = depends['itemVal']
			" if depends defined , item must not be empty
			if has_key(g:pi2mdSettings, dependKey) 
				if g:pi2mdSettings[dependKey] == dependVal
                    if has_key(settingConstraint, 'default')
                        let g:pi2mdSettings[a:itemKey] = settingConstraint.default
                    else
                        let hasError = 1
                    endif
				endif
			endif
		endif
	" ================== check the config defined
	elseif has_key(g:pi2mdSettings, a:itemKey)
		" varify its legitimacy
		let userConfigItem = g:pi2mdSettings[a:itemKey]
		" check value range
		if has_key(settingConstraint, 'legalRange')
			let legalRang = settingConstraint.legalRange
			if index(legalRang, userConfigItem) == -1
				let hasError = 1
			endif
		endif
		" check path exist
		if has_key(settingConstraint, 'isPath')
			if empty(glob(fnameescape(userConfigItem)))
				let hasError = 1
			endif
		endif
	endif
	if hasError == 1
		call s:logger.errorMsg(settingConstraint.errorMsg)
	endif
endfunction

function! s:settings.getSetting(key) dict
	if !has_key(g:pi2mdSettings, a:key)
		s:logger.errorMsg(a:key . ' does not exist, 
			\ please define it in your rc file')
	else
		return g:pi2mdSettings[a:key]
	endif
endfunction
" ==========================================================
" Call System Command func
" ==========================================================

let s:syscall = {}

function! s:syscall.system(cmd) dict
    if s:settings.getSetting('os') ==? 'Windows'
        let envShell = &shell
        let envShellcmdflag = &shellcmdflag
        let &shell = 'cmd.exe'
        let &shellcmdflag = '/c'
        try
            return systemlist(a:cmd)
        " catch 
        "     throw 'E-PIM-23' 
        finally
            let &shell = envShell
            let &shellcmdflag = envShellcmdflag
        endtry
    else
        return systemlist(a:cmd)
    endif
endfunction

function! s:syscall.systemList(cmd) dict
    if s:settings.getSetting('os') ==? 'Windows'
        let envShell = &shell
        let envShellcmdflag = &shellcmdflag
        let &shell = 'cmd.exe'
        let &shellcmdflag = '/c'
        try
            return systemlist(a:cmd)
        " catch 
        "     throw 'E-PIM-24' 
        finally
            let &shell = envShell
            let &shellcmdflag = envShellcmdflag
        endtry
    else
        return systemlist(a:cmd)
    endif
endfunction


" ==========================================================
" Utility Func
" ==========================================================

let s:logger = {}

function! s:logger.getPrefix(flag) dict
	return '[Pi2md]-[' . a:flag . ']-[' . strftime('%d/%m/%y %H:%M:%S') . '] '
endfunction

function! s:logger.errorMsg(msg) dict
	echohl ErrorMsg | echom self.getPrefix('ERROR') . a:msg | echohl None
endfunction

function! s:logger.warningMsg(msg) dict
	echohl WarningMsg | echom self.getPrefix('WARNING') . a:msg | echohl None
endfunction

function s:logger.debugMsg(msg) dict
	if g:pi2mdSettings['debug'] == 1
		echohl None | echom self.getPrefix('DEBUG') . a:msg
	endif
endfunction


let s:utilityTools = {}

function s:utilityTools.caught() dict
	let catchErr = v:exception
	if has_key(s:Errors, catchErr)
		call s:logger.errorMsg(s:Errors[catchErr])
	else
		call s:logger.errorMsg('Caught "' . v:exception . '"')
	endif
endfunction

function s:utilityTools.trimPsOutput(originLine) dict
    let realLine = substitute(a:originLine, '\%x00', '', 'g')
    let realLine = substitute(realLine, '\%x0d', '', 'g')
    return realLine
endfunction

function! s:utilityTools.uuid4() dict

python3 << EOF
import uuid
uuid_string = str(uuid.uuid4())
EOF
	" let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
	" return l:new_random
	let uuid_string = py3eval('uuid_string')
	let ts_string = strftime('%Y-%m-%d-%H-%M-%S')
	let new_random = uuid_string . '-' . ts_string
	return new_random
endfunction

" check windows subsystem for linux
function! s:utilityTools.isWSL() dict
    let lines = readfile('/proc/version')
    if lines[0] =~ 'Microsoft'
        return 1
    endif
    return 0
endfunction

function! s:utilityTools.detectOS() dict
	if !exists('s:os')
		if has('win64') || has('win32') || has('win16')
			let s:os = 'Windows'
			let s:separator_char = '\'
		else
			let s:separator_char = '/'
			let s:os = substitute(s:syscall.system('uname'), '\n', '', '')
		endif
	endif
endfunction

function! s:utilityTools.inputName() dict
    redraw | call inputsave()
    let image_path = input('Enter your image path: ')
    call inputrestore()
    let image_path = fnameescape(image_path)
    if empty(glob(image_path))
        throw 'E-PIM-21'
    endif
    return image_path
endfunction

function! s:utilityTools.detectPicgoApiServerPort() dict
    let picgoApiServerPort = s:settings.getSetting(
        \ 'storage_cloud_picgoapp_api_server_port')
    call s:logger.debugMsg('checking the picgo api server, port is :' 
        \ . picgoApiServerPort)
python3 << EOF

import socket
import vim

ip_addr = '127.0.0.1'
port = vim.eval('picgoApiServerPort')

detectSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
detectSocket.settimeout(3)

detectTarget = (ip_addr, int(port))

serverPortAvailable = 'NO'
try:
    result = detectSocket.connect_ex(detectTarget)
    if result == 0:
        # connect to server success
        serverPortAvailable = 'YES'
    else:
        serverPortAvailable = 'NO'
finally:
    detectSocket.close()
EOF

    let picgoApiServerAviailable = py3eval('serverPortAvailable')
    if picgoApiServerAviailable ==? 'NO'
        throw 'E-PIM-22'
    endif
endfunction


" ==========================================================
" File system utils
" ==========================================================

let s:fileHandler = {}

" translate absolute path to relative path
function s:fileHandler.getRelativePath(img_path) dict
	let current_file_header_path = expand('%:p:h')
	let file_path_list = split(current_file_header_path, s:separator_char)
	let img_name = fnamemodify(a:img_path, ':p:t')
	let img_file_header_path = fnamemodify(a:img_path, ':p:h')
	let img_path_list = split(img_file_header_path, s:separator_char)
	let loop_index = 0
	let not_equal_path_index = 0
	call s:logger.debugMsg('current dir : ' . current_file_header_path)
	call s:logger.debugMsg('image save dir : ' . img_file_header_path)
	for path_i in img_path_list
		if loop_index == (len(file_path_list) - 1) 
			\ && path_i ==# file_path_list[loop_index]
			let img_left_start_index = loop_index + 1
			let img_left_path_list = img_path_list[img_left_start_index:]
			let img_left_path_string = join(img_left_path_list,
				\ s:separator_char)
			let img_relative_path = img_left_path_string . 
				\ s:separator_char . img_name
			return img_relative_path
		endif
		
		if s:os == 'Windows'
			if path_i !=? file_path_list[loop_index]
				let not_equal_path_index = loop_index
				break
			endif
		else
			if path_i !=# file_path_list[loop_index]
				let not_equal_path_index = loop_index
				break
			endif
		endif	
		let loop_index += 1
	endfor
	let img_nomatch_path_counts = len(img_path_list) - not_equal_path_index
	" return absolute path if not match path count greater then 4
	" if nomatch_path_counts == 
	" 	return a:img_path
	" endif
	let file_nomatch_path_count = len(file_path_list) - not_equal_path_index
	let up_dir_loop_index = 0
	let up_dir_string = ''
	while up_dir_loop_index < file_nomatch_path_count
		let up_dir_string .= '..' . s:separator_char
		let up_dir_loop_index += 1
	endwhile
	let img_left_path_list = img_path_list[not_equal_path_index:]
	let img_left_path_string = join(img_left_path_list, s:separator_char)
	let img_relative_path = up_dir_string . img_left_path_string 
		\ . s:separator_char . img_name
	return img_relative_path
endfunction

" convert the path to the final version, depending on your configuration file
" config: storage_local_prefer_relative_path
function! s:fileHandler.getLocalStoragePath(local_full_path) dict
	if s:settings.getSetting('storage_local_prefer_relative_path') == 0
		call s:logger.debugMsg('local storage use absolute path')
		return a:local_full_path
	else
		" try to use relative path
		" let article_full_parent_path = expand('%:p:h')
		" get current working dir
		" let current_working_dir = getcwd()
		" let article_parent_dir = expand('%:h')
		" execute 'lcd ' . article_parent_dir
		" let image_full_parent_path = fnamemodify(a:local_full_path, ':.')	
		" execute 'lcd ' . current_working_dir
		call s:logger.debugMsg('local storage use relative path')
		return self.getRelativePath(a:local_full_path)
	endif
endfunction

" copy file from one path to another,
" del_source will decide whether to delete the 
" source file
function! s:fileHandler.copyFile(source, dest, ...) dict

let deleteSource = get(a:, 1, 1)
python3 << EOF
import shutil

delete_source = int(vim.eval('deleteSource'))
if delete_source == 1:
	shutil.move(vim.eval('a:source'), vim.eval('a:dest'))
else:
	shutil.copyfile(vim.eval('a:source'), vim.eval('a:dest'))
EOF

endfunction

function s:fileHandler.delete(filePath) dict
    call s:logger.debugMsg('delete the temp file now!')
    try
python3 << EOF
import os
file_to_delete = vim.eval('a:filePath')
if os.path.exists(file_to_delete):
    os.remove(file_to_delete)
EOF
	catch /^Vim(python3):/
        throw 'E-PIM-16'
    endtry
endfunction


" ==========================================================
" markup language tools
" ==========================================================

let s:markupLang = {}

" get current file markup language type
" so far from now, this plugin support markdown, reStructuredText and Vimwiki
function! s:markupLang.detectMarkupLanguage() dict
	let file_type = &filetype
	if file_type ==? 'markdown' || file_type ==? 'rst'
		return file_type
	endif
	let file_postfix = expand('%:e')
	if file_postfix ==? 'wiki'
		return 'vimwiki'
	endif
	throw 'E-PIM-15'
endfunction

" insert lint for different markup language
function! s:markupLang.insertImageLink(img_url) dict
    call s:logger.debugMsg('paste image finish!')
	let file_type = self.detectMarkupLanguage()
	if file_type ==? 'markdown'
		execute "normal! i![I"
		let ipos = getcurpos()
		execute "normal! amage](" . a:img_url . ")"
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'rst'
		execute "normal! i!.. |I"
		let ipos = getcurpos()
		execute "normal! amage| image:: " . a:img_url
		call setpos('.', ipos)
		redraw | echo 'please enter the title of this image...'
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'vimwiki'
		let vimwiki_flag = ''
		if g:pi2mdSettings['storage'] == 0
			let vimwiki_flag = 'file:'
		endif
		execute "normal! i!{{" . vimwiki_flag . a:img_url . "}}"
	endif
endf


" ==========================================================
" Clipboard Tools
" ==========================================================

let s:clipboardTools = {}

function! s:clipboardTools.getClipBoardImageAndSave(save_path) dict
	let save_to = fnameescape(a:save_path)
	try
python3 << EOF
import vim
from PIL import ImageGrab
tmpimg = ImageGrab.grabclipboard()
if tmpimg is None:
	no_image_in_clip = 1
else:
	no_image_in_clip = 0
	tmpimg.save(vim.eval('save_to'), 'PNG', compress_level=9)
EOF
	catch 'Vim(python3):ModuleNotFoundError: No module named \'PIL\''
		throw 'E-PIM-13'
	catch /^Vim\%((\a\+)\)\=:E370:/
		throw 'E-PIM-14'
	endtry

	let py_fun_error = py3eval('no_image_in_clip')
	if py_fun_error == 1
		call s:logger.warningMsg('No image in your system clipboard!')
		throw 'E-PIM-12'
	endif
	return a:save_path
endfunction


function! s:clipboardTools.getAndSaveClipBoardImageTemporary() dict
	" get current dir and temp file_name
    call s:logger.debugMsg('save image from clipboard temporary!')
	let temp_file_name = s:utilityTools.uuid4() . '.png'
	let temp_path = expand('%:p:h')
	let temp_img_full_path = temp_path . s:separator_char . temp_file_name
    call s:logger.debugMsg('the temp image file path is:' . temp_img_full_path)
	return s:clipboardTools.getClipBoardImageAndSave(temp_img_full_path)
endfunction



" ==========================================================
" 3rd part cloud lib functions
" ==========================================================


" ------ upic functions



" ====== Local storage

let s:localStorage = {}

function! s:localStorage.saveToLocalStorage(source, ...) dict
    let deleteSource = get(a:, 1, 1)
	" get file name from source
	let file_name = fnamemodify(a:source, ':p:t')
	let file_dest_path = self.buildLocalStorageParentPath() 
		\ . s:separator_char . file_name
	call s:fileHandler.copyFile(a:source, file_dest_path, deleteSource)
	call s:logger.debugMsg('The final image local path is ' . file_dest_path)
	let markup_link_url = s:fileHandler.getLocalStoragePath(file_dest_path)
	return markup_link_url
endfunction

" build the local storage real path , not the same with temporary path
function! s:localStorage.buildLocalStorageParentPath() dict
	if s:settings.getSetting('storage_local_position_type') == 0
		" use current dirctory
		let local_save_parent_path = expand('%:p:h') . s:separator_char . 
			\ s:settings.getSetting('storage_local_dir_name')
	else
		" use absolute path for local storage
		let local_save_parent_path = 
			\ settings.getSetting('g:pi2md_localstorage_path')
	endif
	" make dir if not exists
	if !isdirectory(local_save_parent_path)
        call mkdir(local_save_parent_path)
    endif
	if s:os == 'Darwin'
        return local_save_parent_path
    else
        return fnameescape(local_save_parent_path)
    endif

endfunction

" ====== Cloud storage

let s:cloudStorage = {}

function s:cloudStorage.saveToCloudStorage(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    let remote_img_url = ''
    if g:pi2mdSettings['storage_cloud_tool'] ==? 'picgo-core'
        let remote_img_url = self.uploadByPicgoCore(a:source, deleteSource)
    elseif g:pi2mdSettings['storage_cloud_tool'] ==? 'picgo'
        " use picgo app api
        let remote_img_url = self.uploadByPicgoApp(a:source, deleteSource)
    endif
    return remote_img_url
endfunction

function s:cloudStorage.uploadByPicgoCore(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    call s:logger.debugMsg('upload image by picgo-core')
    " build a upload command
    try
        let picgocore_upload_cmd = 
            \ g:pi2mdSettings['storage_cloud_picgocore_path'] .
            \ ' upload ' .
            \ a:source
        let picgoApiCmdResult= s:syscall.systemList(picgocore_upload_cmd)
        let image_url_result = self.getPicgoResult(picgoApiCmdResult)
        call s:logger.debugMsg('upload image by Picgo app success!')
        return image_url_result
    catch 'E-PIM-18' 
        throw 'E-PIM-18'
    finally
        " finally delete the temp image file
        if deleteSource == 1
            call s:fileHandler.delete(a:source)
        endif
    endtry

    " if g:pi2mdSettings.os ==? 'Windows' || has('win32')
    "     " call s:logger.debugMsg('the system list output length is: ' . len(picgocore_output_list))
    "     let currentIndex = 0
    "     for oriMsg in picgocore_output_list
    "         let windowsPicgoCoreOutput = s:utilityTools.trimPsOutput(oriMsg)
    "         call s:logger.debugMsg(windowsPicgoCoreOutput)
    "         let isSuccessIndex = match(windowsPicgoCoreOutput, 'Picgo\ SUCCESS')
    "         if isSuccessIndex > 0
    "             " get url index of list
    "             let successReturnUrlIndex = currentIndex + 1
    "             let returnUrlString = s:utilityTools.trimPsOutput(picgocore_output_list[successReturnUrlIndex])
    "             call s:logger.debugMsg(returnUrlString)
    "             return returnUrlString
    "         elseif currentIndex == len(picgocore_output_list) - 1
    "             " upload to picgo failed
    "             throw 'E-PIM-17'
    "         endif
    "         let currentIndex += 1
    "     endfor
    " else
    "     let output_file_remote_url = picgocore_output_list[-1]
    "     return output_file_remote_url
    " endif
endfunction


function! s:cloudStorage.buildPicgoAppCmd(source) dict
    let picgo_node_script_path = g:pi2mdSettings['pi2md_root']
        \ . s:separator_char . 'scripts' . s:separator_char . 'picgo.js'
    let picgo_upload_cmd = 
        \ g:pi2mdSettings['storage_cloud_picgoapp_node_path']
        \ . ' ' . picgo_node_script_path
        \ . ' -p '
        \ . s:settings.getSetting('storage_cloud_picgoapp_api_server_port')
    if a:source !=# ''
        let picgo_upload_cmd .= ' -f '
            \ . a:source
	endif
    call s:logger.debugMsg('the picgo app upload cmd is ' . picgo_upload_cmd)
    return picgo_upload_cmd
endfunction

function! s:cloudStorage.uploadByPicgoApp(source, ...) dict
    let deleteSource = get(a:, 1, 1)
    call s:logger.debugMsg('upload image by picgo app')
    call s:utilityTools.detectPicgoApiServerPort()
    try
        let picgoapp_upload_cmd = self.buildPicgoAppCmd(a:source)
        " let picgoappCmdResultList = system(picgoapp_upload_cmd)
        " let @r = system(picgoapp_upload_cmd)
        let picgoApiCmdResult = s:syscall.systemList(picgoapp_upload_cmd)
        let image_url_result = self.getPicgoResult(picgoApiCmdResult)
        call s:logger.debugMsg('upload image by Picgo app success!')
        return image_url_result
    catch 'E-PIM-18' 
        throw 'E-PIM-18'
    finally
        if deleteSource == 1
            call s:fileHandler.delete(a:source)
        endif
    endtry
endfunction

function! s:cloudStorage.getPicgoResult(resultList)
    if len(a:resultList) == 1
        let firstLine = a:resultList[0] 
        call s:logger.debugMsg('the picgo api result is: ' . firstLine)
        if match(firstLine, '^http[s]\?:\/\/.\?') >= 0
            return firstLine
        endif
    elseif len(a:resultList) > 1
        let resultIndex = 0
        let currentIndex = 0
        for lineText in a:resultList
            if match(lineText, 'Picgo\ SUCCESS') > 0
                let resultIndex = currentIndex + 1
                return a:resultList[resultIndex]
            elseif match(lineText, 'Picgo\ ERROR') > 0
                throw 'E-PIM-18'
            endif
            let currentIndex += 1
        endfor
        throw 'E-PIM-18'
    endif
    call s:logger.errorMsg('error occurred when call picgo api')
    throw 'E-PIM-19'
endfunction


function! s:pasteImage(source, ...)
    let deleteSource = get(a:, 1, 1)
	" upload to cloud or save to local
	let final_img_url = 'your link'
	if s:settings.getSetting('storage') == 0
		" local storage
		call s:logger.debugMsg('use local storage')
		let final_img_url = s:localStorage.saveToLocalStorage(
            \ a:source, deleteSource)
	elseif s:settings.getSetting('storage') == 1
		call s:logger.debugMsg('use cloud storage')
		" cloud storage
		let final_img_url = s:cloudStorage.saveToCloudStorage(
            \ a:source, deleteSource)
	endif
    return final_img_url
endfunction

" ==========================================================
" Paste from clipboard 
" ==========================================================

function! s:pasteImageFromClipboard()
	" save image to temp file
	let temp_img_file = s:clipboardTools.getAndSaveClipBoardImageTemporary()
	let final_img_url = s:pasteImage(temp_img_file, 1)
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url)	
endfunction



" ==========================================================
" Paste from Remote Url 
" ==========================================================

function! s:pasteImageFromRemoteUrl()
	" save image to a temp file
endfunction

" ==========================================================
" Paste from local
" ==========================================================


function! s:pasteImageFromLocalPath()
	" wait for user input
    let image_file = s:utilityTools.inputName()
    let final_img_url = s:pasteImage(image_file, 0)
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url)	
    return
endfunction


" ==========================================================
" Main function and commands
" ==========================================================

function! pi2md#Pi2md(...) 
	try
        if a:0 > 0 && a:0 <=2
            let methodFlag = a:000[0] == '' ? 'c' : a:000[0]
            call s:logger.debugMsg('the command argument is:[' . methodFlag . ']')
        else
            throw 'E-PIM-20'
        endif
		call s:settings.initPi2md()
		if methodFlag ==? 'c'
			call s:logger.debugMsg('paste image from your clipboard start!')
			call s:pasteImageFromClipboard()
		elseif methodFlag ==? 'p'
			call s:logger.debugMsg(
				\ 'paste image from your local file system start!')
            call s:pasteImageFromLocalPath()
		elseif methodFlag ==? 'r'
			call s:logger.debugMsg('paste image from a remote url start!')
		endif
	catch
		call s:utilityTools.caught()
	endtry
endfunction

" ==========================================================
" Bind Commands
" ==========================================================

command! -nargs=* Pi2md call pi2md#Pi2md(<q-args>)

