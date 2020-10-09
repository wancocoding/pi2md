Paste Image To Markdown
=======================

A Vim plugin use to autosave  image from clipboard to local system storage or upload image to cloud storage which from your clipboard, and then insert link snippet to your article

## Features

**You can upload image** from

* [x] Clipboard
* [ ] Local file(path)
* [ ] Remote Url

**Support Markup Language**

* [x] [Markdown](https://daringfireball.net/projects/markdown/)
* [ ] [Vimwiki](https://github.com/vimwiki/vimwiki)
* [ ] [reStructuredText](https://www.sphinx-doc.org/en/master/usage/restructuredtext/index.html)

**Support Storage**

* [x] Local Storage
* [x] Cloud Storage (via Picgo-Core or uPic etc...)

**Support Cloud Image Hosting Client or Library**

* [x] PicGo-Core
* [ ] PicGo
* [x] uPic

**Support Cloud**

Support by Picgo

* aliyun oss
* upyun
* qiniu
* tencent cos
* Imgur
* sm.ms
* github


### ChangeLog

* 2020-10-09 1.0.0.beta
	- add support for PicGo-Core
	- add support for uPic on MacOS only
* 2020-10-08
	- you can use relative path when save to local storage
