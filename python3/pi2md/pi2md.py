#!/usr/bin/env python
# encoding: utf-8

import os
import urllib.request
import uuid
import socket
import shutil
import http.client
import json
from sys import platform
from PIL import ImageGrab

IMGFOLDER = os.getcwd() + '/images/'
ip_addr = '127.0.0.1'
port = '36677'

def download_image(image_url):
    """download a remote image url, and save a file"""
    uuid_name = str(uuid.uuid4())
    image_postfix = image_url.split('.')[-1]
    temp_image_name = uuid_name + '.' + image_postfix
    urllib.request.urlretrieve(image_url, temp_image_name)


def detect_picgo_api_server(api_port=port):
    """detect the picgo api server port"""
    detectSocket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    detectSocket.settimeout(3)

    detectTarget = (ip_addr, int(api_port))

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
    return serverPortAvailable


def copy_file(source, dest, del_source='y'):
    if del_source == 'y':
        shutil.move(source, dest)
    else:
        shutil.copyfile(source, dest)


def remove_file(source):
    os.remove(source)


def picgo_upload(image_path=None, api_port=port):
    headers = {'Content-Type': 'application/json'}
    apiserver = 'http://' + ip_addr + ':' + api_port + '/upload'
    if image_path:
        # upload image from local image path
        post_data = {"list": [image_path]}
        params = json.dumps(post_data).encode('utf8')
        req = urllib.request \
                .Request(apiserver, data=params,
                        headers={'content-type': 'application/json'},
                        method='POST')
    else:
        # upload from system clipboard
        req = urllib.request.Request(apiserver, method='POST')
    response = urllib.request.urlopen(req)
    result = response.read().decode('utf-8')
    data = json.loads(result)
    if data['success']:
        image_url = data['result'][0]
        return image_url
    return ''


def save_clipboard(dist):
    """save the image from system clipboard"""
    tmpimg = ImageGrab.grabclipboard()
    if tmpimg:
        tmpimg.save(dist, 'PNG', compress_level=9)
        return dist
    return ''


def detect_os():
    if platform.startswith('linux'):
        return 'linux'
    if platform.startswith('freebsd'):
        return 'freebsd'
    if platform.startswith('aix'):
        return 'aix'
    if platform.startswith('win'):
        return 'windows'
    if platform.startswith('darwin'):
        return 'darwin'
    if platform.startswith('cygwin'):
        return 'cygwin'
    return ''


# if __name__ == '__main__':
    # download_image(
    #     'http://files.static.tiqiua.com/cocoding/blog/images/2020/10/30/08820864f35d2c405e8ae42aa7007ecb-1604026998.jpg')
    # detect_picgo_api_server('36678')
    # copy_file('d:\\develop\\workspace\\dotfiles\\windows\\vimfiles.symlink\\plugged\\pi2md\\python3\\pi2md\\f2b4c197-d1f8-4236-9d13-a12322f1d9d8.jpg',
    #     'd:\\asdasdasdasdsadasd.jpg')
    # remove_file('d:\\asdasdasdasdsadasd.jpg')
    # picgo_upload(api_port='36678')
    # save_clipboard('d:\\test.png')

# vim:set ft=python fenc=utf-8 noet sts=4 sw=4 ts=4 tw=79:
