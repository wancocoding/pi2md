" pi2md.vim - Paste Image to markdown
" Maintainer:    Cocoding  <https://cocoding.cc>
" Version:       0.1


" image base dir
if !exists('g:pi2md_image_base_dir')
	let g:pi2md_image_dir_type = 'CURRENT'
	let g:pi2md_image_dir_name = 'images'
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
endfunction


function s:SaveImageLocal()
	
endfunction

function! s:SaveImageLocalOnMacos() abort
	
endfunction

" the main function of upload image 
function s:uploadImage()
		
endfunction

" you need to install nodejs and picgo lib
function s:uploadImageByPicgo()
	
endfunction


function! pi2md#PasteClipboardImageToMarkdown()
	return s:SaveImage()
endfunction

