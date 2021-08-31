#!/bin/bash
mkdir /ramdisk
chmod -R 777 /ramdisk
mount -t tmpfs -o size=10M none /ramdisk
mkdir /ramdisk/aioairctrl
chmod -R 777 /ramdisk/aioairctrl
