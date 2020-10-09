Paste Image To Markdown
=======================

A Vim plugin use to autosave  image from clipboard to local system storage or upload image to cloud storage which from your clipboard, and then insert link snippet to your article

## Table of Contents

  - [Features](#features)
  - [Screencasts](#screencasts)
  - [Installing](#installing)
  - [Usage](#usage)
  - [ChangeLog](#changelog)
  - [License](#license)

## Screencasts

**upload image to cloud from clipboard**

![2020-10-09-cloud-storage-upic](https://user-images.githubusercontent.com/55470045/95555526-83c96580-0a44-11eb-847d-863846fd2a4c.gif)


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
* [x] PicGo
* [x] uPic

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

## ChangeLog
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
