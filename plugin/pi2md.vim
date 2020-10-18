" vim:set ft=vim noet sts=4 sw=4 ts=4 tw=78:
"
" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <https://cocoding.cc>
"
" Configuration
"
" let g:pi2mdSettings = {
" \ "debug": 1,
" \ "storage": 0,
" \ "storage_local_position_type": 0,
" \ "storage_local_dir_name": "images",
" \ "storage_local_absolute_path": "/User/yourname/your_images_path",
" \ "storage_local_prefer_relative_path": 1,
" \ "storage_cloud_tool": "picgo-core",
" \ "node_bin_path": "/Users/vincent/.nvm/versions/node/v12.11.0/bin/node"
" }
"
"
" Configuration
" ------ base settings ------
"  let g:pi2md_debug_mode = 1
"   default 1 (0: nodebug msg, 1: debug msg in messages)
" let g:pi2md_save_to = 0
"	default: 0 (0: local, 1: cloud)
"
" ------ local storage settings ------
" let g:pi2md_localstorage_strategy = 0
"	default: 0 (0: current dir, 1: absolute path) if you use cloud , ignore it
" let g:pi2md_localstorage_dirname = 'images'
"	(optional) default: images, if you select use absolute path, no need to 
"	define it 
" let g:pi2md_localstorage_path = '/Users/vincent/Pictures'
"	(optional) no default value, if you use local storage strategy 1, you 
"	must define it
" let g:pi2md_localstorage_prefer_relative = 0
"	(optional) defaut: 0, 1: try to use relative path first
"
"
"
" ------ cloud storage settings ------
"
"  ====== PicGo-Core ======
" you must define g:pi2md_save_to = 1 first
" let g:pi2md_cloud_lib = 'picgo-core'
"	default: picgo-core (picgo-core, upic)
"
" let g:pi2md_cloud_picgocore_path = 
"	no default, if you use picgocore, you must define it
"
" let g:pi2md_cloud_picgocore_node_path = 
"	no default, if you use picgocore, you must define it 
"
"  ====== PicGo ======
"  make sure you have install nodejs and global install axios package 
"  post a http request to picgo server
" let g:pi2md_cloud_lib = 'picgo'
"
" let g:pi2md_cloud_picgo_path = '/Applications/PicGo.app/Contents/MacOS/PicGo'
"   deprecated, use host api instead
"
" let g:pi2md_cloud_picgo_node_path = '/Users/vincent/.nvm/versions/node/v12.11.0/bin/node'
"	no default, must define it if you use picgo app 
"
"  ====== uPic ======
" let g:pi2md_cloud_lib = 'upic'
"
" let g:pi2md_cloud_upic_path = '/Applications/uPic.app/Contents/MacOS/uPic'
"   no default, must define it if you use upic


" the configuration constraint
let s:pi2mdConfigConstraint = {
	\ "debug": {
	\	"legalRange": [0, 1], 
	\	"default": 1, 
	\	"required": 1,
	\	"errorMsg": "the value of debug config must be 0 or 1"}, 
	\ "storage": { 
	\	"legalRange": [0, 1], 
	\	"default": 0, 
	\	"required": 1,
	\	"errorMsg": "the value of storage config must be 0 or 1"},
	\ "storage_local_position_type": {
	\	"legalRange": [0, 1], 
	\	"default": 0, 
	\	"required": 1,
	\	"errorMsg": "the value of local position type config must be 0 or 1"},
	\ "storage_local_prefer_relative_path": {
	\	"legalRange": [0, 1], 
	\	"default": 1, 
	\	"required": 0,
	\	"errorMsg": "the value of use relative path config must be 0 or 1"},
	\ "storage_cloud_tool": {
	\	"legalRange": ["picgo-core", "picgo", "upic"], 
	\	"default": "picgo-core", 
	\	"required": 0,
	\	"errorMsg": "the value of cloud lib config must be one of picgo-core, picgo or upic"}
\ }



" ==========================================================
" Init Variables " 
" ==========================================================

function! s:initPi2md()
	" add more variables
	call s:checkConfiguration()
	call s:detectOS()
	let g:pi2mdSettings['os'] = s:os

	" get the pi2md plugin root absolute path
	let s:pi2md_root_full_path = fnamemodify(resolve(expand('<sfile>:p')), ':h:h')
	let g:pi2mdSettings['pi2md_root'] = s:pi2md_root_full_path
endfunction

" make sure all configuration is right
function! s:checkConfiguration()
	if !exists('g:pi2mdSettings')
		" setting some default configuration
		let g:pi2mdSettings = {
			\ "debug": 1,
			\ "storage": 0,
			\ "storage_local_position_type": 0,
			\ "storage_local_dir_name": "images",
			\ "storage_local_prefer_relative_path": 1,
			\ "storage_cloud_tool": "picgo-core"}
	else
		" check configuration , make sure all settings are correct
		for ckey in keys(s:pi2mdConfigConstraint)
			call s:checkConfigItem(ckey)
		endfor
	endif
endfunction

function s:checkConfigItem(itemKey)
	let settingConstraint = s:pi2mdConfigConstraint[a:itemKey]
	" check if exists in global configuration
	if !has_key(g:pi2mdSettings, a:itemKey)
		" set default value if not exist
		let g:pi2mdSettings[a:itemKey] = settingConstraint.default
	else
		" varify its legitimacy
		let userConfigItem = g:pi2mdSettings[a:itemKey]
		let legalRang = settingConstraint.legalRange
		if index(legalRang, userConfigItem) == -1
			call s:warningMsg(settingConstraint.errorMsg)
		endif
	endif
endfunction

function! s:getSetting(key)
	if !has_key(g:pi2mdSettings, a:key)
		s:errorMsg(a:key . ' does not exist, please define it in your rc file')
	else
		return g:pi2mdSettings[a:key]
	endif
endfunction

" ==========================================================
" Utility Func
" ==========================================================

function! s:errorMsg(msg)
	echohl ErrorMsg | echom '[pi2md]-[Error] '.a:msg | echohl None
endfunction

function! s:warningMsg(msg)
	echohl WarningMsg | echom '[pi2md]-[Warning] '.a:msg | echohl None
endfunction

function s:debugMsg(msg)
	let msgPrefx = '[pi2md]-[Debug] '
	if s:getSetting('debug') == 1
		echom msgPrefx . a:msg
	endif
endfunction

" Deprecated use command args instead
function! s:inputName()
    call inputsave()
    let name = input('Image name: ')
    call inputrestore()
    return name
endfunction


function! s:uuid4() 

python3 << EOF
import uuid
uuid_string = str(uuid.uuid4())
EOF
	" let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
	" return l:new_random
	let uuid_string = py3eval('uuid_string')
	let ts_string = strftime("%Y-%m-%d-%H-%M-%S")
	let new_random = uuid_string . '-' . ts_string
	return new_random
endfunction

" check windows subsystem for linux
function! s:isWSL()
    let lines = readfile("/proc/version")
    if lines[0] =~ "Microsoft"
        return 1
    endif
    return 0
endfunction

function! s:detectOS()
	if !exists('s:os')
		if has("win64") || has("win32") || has("win16")
			let s:os = "Windows"
			let s:separator_char = '\'
		else
			let s:separator_char = '/'
			let s:os = substitute(system('uname'), '\n', '', '')
		endif
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
	call s:debugMsg('current dir : ' . current_file_header_path)
	call s:debugMsg('image save dir : ' . img_file_header_path)
	for path_i in img_path_list
		if loop_index == (len(file_path_list) - 1) && path_i ==# file_path_list[loop_index]
			let img_left_start_index = loop_index + 1
			let img_left_path_list = img_path_list[img_left_start_index:]
			let img_left_path_string = join(img_left_path_list, s:separator_char)
			let img_relative_path = img_left_path_string . s:separator_char . img_name
			return img_relative_path
		endif
		
		if s:os == "Windows"
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
	let img_relative_path = up_dir_string . img_left_path_string . s:separator_char . img_name
	return img_relative_path
endfunction

" convert the path to the final version, depending on your configuration file
" config: storage_local_prefer_relative_path
function! s:fileHandler.getLocalStoragePath(local_full_path) dict
	if s:getSetting('storage_local_prefer_relative_path') == 0
		call s:debugMsg('local storage use absolute path')
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
		call s:debugMsg('local storage use relative path')
		return self.getRelativePath(a:local_full_path)
	endif
endfunction

" copy file from one path to another, del_source will decide whether to delete the 
" source file
function! s:fileHandler.copyFile(source, dest, del_source=1) dict

python3 << EOF
import shutil

delete_source = vim.eval('a:del_source')
if delete_source == 1:
	shutil.move(vim.eval('a:source'), vim.eval('a:dest'))
else:
	shutil.copyfile(vim.eval('a:source'), vim.eval('a:dest'))
EOF

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
endfunction

" insert lint for different markup language
function! s:markupLang.insertImageLink(img_url) dict
	let file_type = self.detectMarkupLanguage()
	if file_type ==? 'markdown'
		execute "normal! i![I"
		let ipos = getcurpos()
		execute "normal! amage](" . a:img_url . ")"
		call setpos('.', ipos)
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'rst'
		execute "normal! i!.. |I"
		let ipos = getcurpos()
		execute "normal! amage| image:: " . a:img_url
		call setpos('.', ipos)
		execute "normal! ve\<C-g>"
	elseif file_type ==? 'vimwiki'
		let vimwiki_flag = ''
		if g:pi2mdSettings['storage'] == 0
			let vimwiki_flag = 'file:'
		endif
		execute "normal! i!{{" . vimwiki_flag . a:img_url . "}}"
	endif
	return
endf


" ==========================================================
" Clipboard Tools
" ==========================================================

function! s:getClipBoardImageAndSave(save_path)
	let save_to = fnameescape(a:save_path)

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

	let py_fun_error = py3eval('no_image_in_clip')
	if py_fun_error == 1
		call s:warningMsg('saveClipBoardImage error')
		return 1
	endif
	return a:save_path
endfunction


function! s:getAndSaveClipBoardImageTemporary()
	" get current dir and temp file_name
	let temp_file_name = s:uuid4() . '.png'
	let temp_path = expand('%:p:h')
	let temp_img_full_path = temp_path . s:separator_char . temp_file_name
	return s:getClipBoardImageAndSave(temp_img_full_path)
endfunction

" ==========================================================
" Storage
" ==========================================================


" ====== Local storage

let s:localStorage = {}

function! s:localStorage.saveToLocalStorage(source) dict
	" get file name from source
	let file_name = fnamemodify(a:source, ':p:t')
	let file_dest_path = self.buildLocalStorageParentPath() . s:separator_char . file_name
	call s:fileHandler.copyFile(a:source, file_dest_path)
	call s:debugMsg('The final image local path is ' . file_dest_path)
	let markup_link_url = s:fileHandler.getLocalStoragePath(file_dest_path)
	return markup_link_url
endfunction

" build the local storage real path , not the same with temporary path
function! s:localStorage.buildLocalStorageParentPath() dict
	if s:getSetting('storage_local_position_type') == 0
		" use current dirctory
		let local_save_parent_path = expand('%:p:h') . s:separator_char . s:getSetting('storage_local_dir_name')
	else
		" use absolute path for local storage
		let local_save_parent_path = getSetting('g:pi2md_localstorage_path')
	endif
	" make dir if not exists
	if !isdirectory(local_save_parent_path)
        call mkdir(local_save_parent_path)
    endif
	if s:os == "Darwin"
        return local_save_parent_path
    else
        return fnameescape(local_save_parent_path)
    endif

endfunction

" ====== Cloud storage

let s:cloudStorage = {}

function s:cloudStorage.saveToCloudStorage(source)

	
endfunction


" ==========================================================
" Paste from clipboard 
" ==========================================================

function! s:pasteImageFromClipboard()
	" save image to temp file
	let temp_img_file = s:getAndSaveClipBoardImageTemporary()
	" upload to cloud or save to local
	let final_img_url = 'your link'
	if s:getSetting('storage') == 0
		let final_img_url = s:localStorage.saveToLocalStorage(temp_img_file)
	elseif s:getSetting('storage') == 1
		" cloud storage
	endif
	" write link for markup language
	call s:markupLang.insertImageLink(final_img_url)	
	return
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
	" 
endfunction


" ==========================================================
" Main function and commands
" ==========================================================

function! pi2md#PasteClipboardImage()
	call s:pasteImageFromClipboard()
endfunction

" ==========================================================
" Bind Commands
" ==========================================================



call s:initPi2md()

command! -nargs=0 Pi2mdClipboard call pi2md#PasteClipboardImage()


