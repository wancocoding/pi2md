" pi2md.vim - Paste Image to markdown
" Maintainer:    Vincent Wancocoding  <https://cocoding.cc>
" Version:       0.1
"
"
" Configuration
" ------ base settings ------
" let g:pi2md_save_to = 0							" default: 0 (0: local, 1: cloud)
"
" ------ local storage settings ------
" let g:pi2md_localstorage_strategy = 0
"	default: 0 (0: current dir, 1: absolute path
" let g:pi2md_localstorage_dirname = 'images'
"	(optional) default: images, if you select use absolute path, no need to define it 
" let g:pi2md_localstorage_path = '/Users/vincent/Pictures'
"	(optional) no default, if you use local storage strategy 1, you must define it
"
"
"
"
"
"
"
" where is your image store
if !exists('pi2md_save_to')
	let g:pi2md_save_to = 0
endif

" set the default storage
if !exists('g:pi2md_localstorage_strategy')
	let g:pi2md_localstorage_strategy = 0
	let g:pi2md_localstorage_dirname = 'images'
endif

function! s:InputName()
    call inputsave()
    let name = input('Image name: ')
    call inputrestore()
    return name
endfunction

function! s:RandomString() 
	let l:new_random = strftime("%Y-%m-%d-%H-%M-%S")
	return l:new_random
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


function! s:saveImageOSX()
	let l:save_image_file_name = s:RandomString() . '.png'
	if !exists('g:pi2md_image_base_dir')
		let l:img_file_dir = expand("%:p:h") . '/' . g:pi2md_image_dir_name
	else
		let l:img_file_dir = g:pi2md_image_base_dir . '/' . strftime("%Y") . '/' . strftime("%m")  . '/'  . expand("%:p:t:r") 
	endif
	return l:img_file_dir . '/' . l:save_image_file_name
endfunction

" the main function of save image
function! s:SaveImage()
	echo "testing!"	
	" detect the os
	call s:detectOS()
	if g:pi2md_save_to == 0
		return s:saveImageLocal()
	endif
endfunction


function s:buildLocalPath()
	if g:pi2md_localstorage_strategy == 0
		let local_save_parent_path = expand('%:p:h') . s:separator_char . g:pi2md_localstorage_dirname
	else
		if !exists('g:pi2md_localstorage_path')
			echoerr 'oh it failed'
			return
		endif
		let local_save_parent_path = g:pi2md_localstorage_path
	endif
	if !isdirectory(local_save_parent_path)
        call mkdir(local_save_parent_path)
    endif
	if s:os == "Darwin"
        return local_save_parent_path
    else
        return fnameescape(local_save_parent_path)
    endif
endfunction

function s:buildLocalImageFullPath(parent_dir) abort
	let local_random_image_name = s:RandomString()	
	let local_image_full_name_with_path = a:parent_dir . s:separator_char . local_random_image_name . '.png'
	return local_image_full_name_with_path
endfunction

" Save Images Locally
function s:saveImageLocal()
	echo 'save image in local file system'
	let parent_dir = s:buildLocalPath()
	let image_local_save_to = s:buildLocalImageFullPath(parent_dir)
	echo image_local_save_to
	if s:os == "Darwin"
		return s:saveImageLocalOnMacos(image_local_save_to)
	endif
endfunction

function! s:saveImageLocalOnMacos(save_to)
	let clip_command = 'osascript'
    let clip_command .= ' -e "set png_data to the clipboard as «class PNGf»"'
    let clip_command .= ' -e "set referenceNumber to open for access POSIX path of'
    let clip_command .= ' (POSIX file \"' . a:save_to . '\") with write permission"'
    let clip_command .= ' -e "write png_data to referenceNumber"'
	echo 'call applescript'
	echo a:save_to
	silent call system(clip_command)
	if v:shell_error == 1
        return 1
    else
		return a:save_to
	endif
endfunction

" the main function of upload image 
function s:uploadImage()
		
endfunction

" you need to install nodejs and picgo lib
function s:uploadImageByPicgo()
	
endfunction

function! pi2md#PasteClipboardImageToMarkdown()
	let save_reslut = s:SaveImage()
	if save_reslut == 1
		" error 
		return 
	else
		execute "normal! i![I"
        let ipos = getcurpos()
        execute "normal! amage](" . save_reslut . ")"
        call setpos('.', ipos)
        execute "normal! ve\<C-g>"
	endif
endfunction







