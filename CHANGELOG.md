ChangeLog
======


* 2020-10-29
	- update node script
	- add function to detect picgo api service
	- set default value for not required config which has depneds and it has been setup already
	- picgo app support local image upload
	- set shell for vim script before run `system` or `systemlist` 
	- use cmd as the default shell on win32 platform
* 2020-10-28
	- add local image path support
	- Compatible with neovim function argument
* 2020-10-23
	- fix invalid argument for Neovim
	- finish upload image by picgo app with api
* 2020-10-21
	- fix win32 power shell output with special char
	- update execute command quotes
* 2020-10-20
	- refactor continue
	- text with double quotes to single quotes
* 2020-10-19
	- add check python envrionment function and error catch for python or python module
	- update check settings function
	- update settings data structure
	- refactored the functions of cloud storage
	- update readme examples
	- use try catch to handle exceptions
	- modify logging format
* 2020-10-18
	- add functions for check configuration
	- add functions for print different messages
	- refactor all functions to dict function
* 2020-10-16
	- change pi2md configuration to dictionary
	- refactor all functions
	- support reStructuredText language
	- support vimwiki markup language
	- update examples
	- update config introduction
* 2020-10-16 1.0.0.b7
	- refactor clipbord function
	- update readme with more example
* 2020-10-16 1.0.0.b6
	- add debug mode
	- use absolute path on windows when the drive are different
	- update random func, use uuid
	- use py3 script to handle clipboard on all platforms
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
