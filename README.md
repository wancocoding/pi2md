Paste Image To Markdown
=======================

A Vim plugin use to autosave  image from clipboard to local system storage or upload image to cloud storage which from your clipboard, and then insert link snippet to your article

## Table of Contents

  - [Screencasts](#screencasts)
  - [Features](#features)
  - [Installing](#installing)
  - [Usage](#usage)
  - [Example](#example)
  - [ChangeLog](#changelog)
  - [License](#license)

## Screencasts

**upload image to cloud from clipboard**

![2020-10-09-cloud-storage-upic](https://user-images.githubusercontent.com/55470045/95555526-83c96580-0a44-11eb-847d-863846fd2a4c.gif)


## Features

Both of `Vim` and `NeoVim` can use this plugin

**You can upload image** from

* [x] Clipboard
* [ ] Local file(path)
* [ ] Remote Url

**Support OS**

* [x] MacOS
* [x] Windows
* [ ] Linux
* [ ] WSL(Windows Subsystem For Linux)

**Support Markup Language**

* [x] [Markdown](https://daringfireball.net/projects/markdown/)
* [ ] [Vimwiki](https://github.com/vimwiki/vimwiki)
* [ ] [reStructuredText](https://www.sphinx-doc.org/en/master/usage/restructuredtext/index.html)

**Support Storage**

* [x] Local Storage
* [x] Cloud Storage (via Picgo-Core, Picgo App or uPic etc...)

**Support Cloud Image Hosting Client or Library**

* [x] PicGo-Core(nodejd moudle, recommend)
* [x] PicGo App
* [x] uPic(only on osx)

**Support Cloud**

 [Picgo](https://github.com/Molunerfinn/PicGo) or [PicGo-Core](https://github.com/PicGo/PicGo-Core)

* aliyun oss
* upyun
* qiniu
* tencent cos
* Imgur
* smms
* github

[uPic](https://github.com/gee1k/uPic)

* [smms](https://sm.ms/)
* [UPYUN USS](https://www.upyun.com/products/file-storage)
* [qiniu KODO](https://www.qiniu.com/products/kodo)
* [Aliyun OSS](https://www.aliyun.com/product/oss/)
* [TencentCloud COS](https://cloud.tencent.com/product/cos)
* [BaiduCloud BOS](https://cloud.baidu.com/product/bos.html)
* [Weibo](https://weibo.com/)
* [Github](https://github.com/settings/tokens)
* [Gitee](https://gitee.com/profile/personal_access_tokens)
* [Amazon S3](https://aws.amazon.com/cn/s3/)
* [Imgur](https://imgur.com/)
* [custom upload api](https://blog.svend.cc/upic/tutorials/custom)

## Installing


### [vim-plug](https://github.com/junegunn/vim-plug)

```vim
call plug#begin('~/.vim/plugged')
Plug 'wancocoding/pi2md'
call plug#end()
```
after restart vim/nvim or `:so[urce]` your `vimrc`, then`:PlugInstall`

### [pathogen.vim](https://github.com/tpope/vim-pathogen)

```
git clone https://github.com/wancocoding/pi2md.git ~/.vim/bundle/pi2md
```

### [Vundle.vim](https://github.com/VundleVim/Vundle.vim)

```vim
call vundle#begin()
Plugin 'preservim/nerdtree'
call vundle#end()
```

### [dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#begin()
call dein#add('preservim/nerdtree')
call dein#end()
```



## Usage


You can paste image from clipboard by the command:
```
:Pi2mdClipboard
```
or call global function
```vim
:call pi2md#PasteClipboardImageToMarkdown()
```
or you can define a specific key to call this command

```vim
nmap <leader>pi :Pi2mdClipboard<CR>
```

All Commands:
| Command                 | Intro                            |
| ----------------------- | -------------------------------- |
| :Pi2mdClipboard         | paste image from clipboard       |
| :Pi2mdPath <image path> | paste image from a absolute path |
| :Pi2mdUrl <image url>   | paste image from a remote url    |



### Local Storage

Local Storage is the default way to save clipboard image

```vim
let g:pi2md_save_to = 0
" default: 0 (0: local, 1: cloud) 
let g:pi2md_localstorage_strategy = 0
" default: 0 (0: current dir, 1: absolute path) if you use cloud , ignore it
let g:pi2md_localstorage_dirname = 'images'
" (optional) default: images, if you select use absolute path, no need to define it 
let g:pi2md_localstorage_path = '/Users/vincent/Pictures'
" (optional) no default value, if you use local storage strategy 1, you must define it
let g:pi2md_localstorage_prefer_relative = 0
" (optional) defaut: 0, 1: try to use relative path first
```

## Example

### 1. Save image in current folder and use relative path

```vim
let g:pi2md_save_to = 0
let g:pi2md_localstorage_strategy = 0
let g:pi2md_localstorage_dirname = 'images'
let g:pi2md_localstorage_prefer_relative = 1
```

call the command and you will get this in your markdown file:
```markdown
![Image](images/2020-10-13-22-33-02.png)
```

### 2. Save image in current folder and use absolute path

```vim
let g:pi2md_save_to = 0
let g:pi2md_localstorage_strategy = 0
let g:pi2md_localstorage_dirname = 'images'
let g:pi2md_localstorage_prefer_relative = 0
```

result:
```markdown
![Image](/Users/vincent/develop/wancocoding/docs/example/images/2020-10-13-22-37-04.png)
```

## ChangeLog

* 2020-10-14 1.0.0.beta5
	- fix windows 10 clipboard paste bug
	- add a powershell script
	- put all script together
* 2020-10-13 1.0.0.beta4
	- add local storage for windows
	- add command
	- update readme 
* 2020-10-09 1.0.0.beta3
	- add picgo support
	- add node script for post request 
* 2020-10-09 1.0.0.beta.2
	- fix relative path bug
* 2020-10-09 1.0.0.beta
	- add support for PicGo-Core
	- add support for uPic on MacOS only
* 2020-10-08
	- you can use relative path when save to local storage


## License

[MIT](https://github.com/wancocoding/pi2md/blob/master/LICENSE)
