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

" function! s:randomFileNameUUID()

" python << EOF

" import uuid
" import vim

" # output a uuid to the vim variable for insertion below
" vim.command("let generatedUUID = \"%s\"" % str(uuid.uuid4()))

" EOF

" return generatedUUID

" endfunction

function! pi2md#PasteClipboardImageToMarkdown()
	return s:saveImageOSX()
endfunction

