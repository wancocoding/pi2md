Paste Image To Markdown
=======================

A Vim/NeoVim plugin use to autosave  image from clipboard to local system storage or upload image to cloud storage which from your clipboard, and then insert link snippet to your article

## Table of Contents

  - [Screencasts](#screencasts)
  - [Features](#features)
  - [Installation](#installation)
  - [Usage](#usage)
  - [Configuration](#configuration)
  - [Examples](#examples)
  - [ChangeLog](#changelog)
  - [License](#license)

## Screencasts

**paste image from clipboard**

![paste-image-from-clipboard](https://user-images.githubusercontent.com/55470045/98808447-164f9100-2457-11eb-9550-47f176f358b3.gif)


**paste image from local path**

![paste-image-from-local-path](https://user-images.githubusercontent.com/55470045/98812660-d63fdc80-245d-11eb-9bb8-b6d48abb7353.gif)

**paste image from web url**

![paste-image-from-web-url](https://user-images.githubusercontent.com/55470045/98817049-8284c180-2464-11eb-8e2e-e7e778dcf182.gif)

**upload image from clipboard to cloud storage**

![upload-image-from-clipboard-to-cloud](https://user-images.githubusercontent.com/55470045/98820382-0d67bb00-2469-11eb-8cce-95947c3fdc39.gif)


## Features

Both of `Vim` and `NeoVim` can use this plugin

**You can upload image** from

* [x] Clipboard
* [x] Local file(path)
* [x] Remote Url

**Support OS**

* [x] MacOS
* [x] Windows
* [x] Linux
* [ ] WSL(Windows Subsystem For Linux)

**Support Markup Language**

* [x] [Markdown](https://daringfireball.net/projects/markdown/)
* [x] [Vimwiki](https://github.com/vimwiki/vimwiki)
* [x] [reStructuredText](https://www.sphinx-doc.org/en/master/usage/restructuredtext/index.html)

**Support Storage**

* [x] Local Storage
* [x] Cloud Storage (via Picgo-Core, Picgo App or uPic etc...)

**Support Cloud Storage**

> Pi2md supperts upload images to your cloud storage by 3rd-party libraries 
> like *picgo-core*, *uPic*...

* [x] PicGo-Core(nodejd moudle, recommend)
* [x] PicGo App
* [x] uPic(only on osx)


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

## Installation

**Requirements**

* vim 8.1+ and compiled with python3 support
* install `Pillow` for python3(Optional)
* cloud library(Optional)


**Install Pillow(Optional)**

You must install python3 and enable python3 for your vim/neovim
support for your vim, and then install [Pillow](https://github.com/python-pillow/Pillow) 

For `Win32/64` or `Win10` User, before `pip install`
```
python -m ensurepip
python -m pip install -U pip
python -m pip install pillow
```
Unix like platforms:
```
pip install -U pip
pip install pillow
```


**Install Picgo-Core(Optional)**

`Picgo-core` is an *nodejs* package, If you upload to cloud with picgo-core,
you can install it simply by:
```
npm install picgo -g
```


**Install Pi2md**

You can install `Pi2md` by the 3rd-party plugin managers

[vim-plug](https://github.com/junegunn/vim-plug)

```vim
call plug#begin('~/.vim/plugged')
Plug 'wancocoding/pi2md'
call plug#end()
```
after restart vim/nvim or `:so[urce]` your `vimrc`, then`:PlugInstall`

[pathogen.vim](https://github.com/tpope/vim-pathogen)

```
git clone https://github.com/wancocoding/pi2md.git ~/.vim/bundle/pi2md
```

[Vundle.vim](https://github.com/VundleVim/Vundle.vim)

```vim
call vundle#begin()
Plugin 'preservim/nerdtree'
call vundle#end()
```

[dein.vim](https://github.com/Shougo/dein.vim)

```vim
call dein#begin()
call dein#add('preservim/nerdtree')
call dein#end()
```



## Usage


You can paste image from clipboard by the command:
```
:Pi2md
```
Commands:

| Command                 | Intro                            |
| ----------------------- | -------------------------------- |
| :Pi2md                  | paste image from clipboard       |
| :Pi2md p                | paste image from a absolute path |
| :Pi2md r                | paste image from a remote url    |



### Local Storage Settings

Local Storage is the default way to save clipboard image

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 0,
    \ 'storage_local_position_type': 0
  \ }
```

### Cloud Storage Settings

#### 1 use picgo-core(recommended)

put this in your `vimrc` file

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 1,
    \ 'storage_cloud_tool': 'picgo-core',
    \ 'storage_cloud_picgocore_path': 
    \     '/home/vincent/.nvm/versions/node/v12.19.0/lib/node_modules/picgo/bin/picgo'
  \ }
```

config your picgo-core,see: [Picgo-core](https://github.com/PicGo/PicGo-Core)

picgo-core settings example(for aliyun oss):

edit your `~/.picgo/config.json`

```json
{
  "picBed": {
    "uploader": "aliyun",
    "current": "smms",
    "aliyun": {
      "accessKeyId": "your ak id",
      "accessKeySecret": "your ak key",
      "bucket": "your bucket name",
      "area": "your oss region",
      "path": "cocoding/blog/images/",
      "customUrl": "http://your.oss.domain.com",
      "options": ""
    }
  },
  "picgoPlugins": {
    "picgo-plugin-rename-file": true
  },
  "picgo-plugin-rename-file": {
    "format": "{y}/{m}/{d}/{hash}-{timestamp}"
  }
}
```



#### 2 use picgo app

If you use `Picgo app` as a cloud library

see: [Picgo Guide - Configuration](https://picgo.github.io/PicGo-Doc/en/guide/config.html)

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 1,
    \ 'storage_cloud_tool': 'picgo',
    \ 'storage_cloud_picgoapp_api_server_port': '36677'
  \ }
```

Where is the picgo config file

* windows: `%APPDATA%\picgo\data.json`
* Linux: `$XDG_CONFIG_HOME/picgo/data.json` or `~/.config/picgo/data.json`
* macOS: `~/Library/Application\ Support/picgo/data.json`

An exaple on windows picgo app, `data.json`
```

{
  "uploaded": [],
  "picBed": {
    "current": "aliyun",
    "uploader": "aliyun",
    "smms": {
      "token": ""
    },
    "aliyun": {
      "accessKeyId": "your akid",
      "accessKeySecret": "your aks",
      "area": "your oss region",
      "bucket": "your bucket name",
      "customUrl": "http://yourdomain",
      "options": "",
      "path": "your/custom/path"
    }
  },
  "settings": {
    "shortKey": {
      "picgo:upload": {
        "enable": true,
        "key": "CommandOrControl+Shift+P",
        "name": "upload",
        "label": "upload-key"
      }
    },
    "server": {
      "port": 36677,
      "host": "127.0.0.1",
      "enable": true
    },
    "showUpdateTip": true,
    "customLink": "$url"
  },
  "picgoPlugins": {
    "picgo-plugin-rename-file": true
  },
  "debug": true,
  "PICGO_ENV": "GUI",
  "needReload": false,
  "picgo-plugin-rename-file": {
    "format": "{y}/{m}/{d}/{hash}-{timestamp}"
  }
}
```

then start the picgo app, make sure picgo server started with port `36677` or what your defined in your vimrc files

## Configuration

Configuring `Pi2md` is very simple, you only need to add the following content
to your `vimrc`

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 1,
    \ 'storage_local_position_type': 0,
    \ 'storage_local_dir_name': 'images',
    \ 'storage_local_absolute_path': '/home/vincent/temp/imgs',
    \ 'storage_local_prefer_relative_path': 1,
    \ 'storage_cloud_tool': 'picgo-core',
    \ 'storage_cloud_picgocore_path': 
    \     '/home/vincent/.nvm/versions/node/v12.19.0/lib/node_modules/picgo/bin/picgo',
    \ 'storage_cloud_picgoapp_api_server_port': '36677'
  \ }
```

**debug**

- type: integer
- default: 1

Output debugging mesage if it turns on

**storage**

- type: integer
- default: 0
	+ 0: save the image locally
	+ 1: save the image in the cloud storage

**storage_local_position_type**

- type: integer
- default: 0
	+ 0: save images in `images` folder which in current directory
	+ 1: save images in a absolute path you defined

**storage_local_dir_name**

- type: string
- default: images

define the directory name for save images, when the **storage_local_position_type** value is **0**

**storage_local_absolute_path**

- type: string
- no default

> you must define a path if the **storage_local_position_type** is **1**

**storage_local_prefer_relative_path**


- type: integer
- default: 1

> Try to use relative path to display images as much as possible

**storage_cloud_tool**

- type: string
- default: picgo-core
	- picgo: a app on all platform
	- picgo-core: nodejs library
	- upic: a app on macOS

select a cloud library to save your images

**storage_cloud_picgocore_path**

- type: string
- no default

define the path of `picgo-core`, if you use `picgo-core` to save image in your cloud storage.


**storage_cloud_picgoapp_api_server_port**

- type: string
- default: 36677

picgo app start a api server, we can use it to upload image, it only works when
you use picgo app as a tool for uploading images to your cloud storage.

## Examples

### 1. Save image in current folder and use relative path

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 0,
    \ 'storage_local_position_type': 0,
    \ 'storage_local_dir_name': 'images',
    \ 'storage_local_prefer_relative_path': 1,
  \ }
```

results:
```markdown
![Image](images/2020-10-13-22-33-02.png)
```

### 2. Save image in current folder and use absolute path

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 0,
    \ 'storage_local_position_type': 1,
    \ 'storage_local_absolute_path': '/home/vincent/temp/imgs',
    \ 'storage_local_prefer_relative_path': 0,

  \ }
```

result:
```markdown
![Image](/Users/vincent/imgs/2020-10-13-22-37-04.png)
```

### 3. Save image in a specific directory and use relative path


```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 0,
    \ 'storage_local_position_type': 1,
    \ 'storage_local_absolute_path': 'f:\Dropbox\Dropbox\docs\md\notes\files\images\202010',
    \ 'storage_local_prefer_relative_path': 1,
  \ }
```

result:
```
![Image](..\..\..\files\images\202010\1c353706-c5a1-4865-b767-9f37e5c71c4e-2020-10-16-10-19-28.png)
```

### 4. Save image to cloud by picgo-core


```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 1,
    \ 'storage_cloud_tool': 'picgo-core',
    \ 'storage_cloud_picgocore_path': 
    \     '/home/vincent/.nvm/versions/node/v12.19.0/lib/node_modules/picgo/bin/picgo'
  \ }
```

results:
```
![Image](http://cdn.images.myclouddomain.com/cocoding/blog/images/2020/11/13/10068c58c929bcbf80598fed427dab61-1605260574.png)
```

### 5. Save image to cloud by picgo app

```vim
let g:pi2mdSettings = {
    \ 'debug': 1,
    \ 'storage': 1,
    \ 'storage_cloud_tool': 'picgo',
    \ 'storage_cloud_picgoapp_api_server_port': '36677'
  \ }
```

results:
```
![Image](http://cdn.images.myclouddomain.com/cocoding/blog/images/2020/11/13/10068c58c929bcbf80598fed427dab61-1605260574.png)
```


## ChangeLog

see: [CHANGELOG](https://github.com/wancocoding/pi2md/blob/master/CHANGELOG.md)

## License

[MIT](https://github.com/wancocoding/pi2md/blob/master/LICENSE)

Copyright © 2020 Vincent Wancocoding

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
