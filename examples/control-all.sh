#!/bin/bash
export PATH="$PATH:/home/pi/.local/bin"

# use: ./aioairctrl.sh option
# only use one option out of:
#           power:  off, on
#           speed:  s, sleep, silent, 1, 2, 3, t, turbo
# automatic modes:  a, auto, A, allergy, B, virus


for ipaddr in 192.168.6.{150..152} #change this to match the ip adresses of your devices
do
  echo $ipaddr
  if [ "$1" != "" ]
  then
    case "$1" in
      a|auto)      timeout 60 aioairctrl -H $ipaddr set mode=P &;;
      A|allergy)      timeout 60 aaioairctrl -H $ipaddr set mode=A &;;
      B|virus)      timeout 60 aaioairctrl -H $ipaddr set mode=B &;;
      # l|lighton)      timeout 60 aaioairctrl -H $ipaddr set aqil=100 uil=1 &;;
      # above does somehow not change the brightness
      # if you want to change brightness, this script uses
      # https://github.com/rgerganov/py-air-control
      # you can install it with: pip3 install py-air-control
      l|lighton)  timeout 60 aairctrl --ipaddr $ipaddr --protocol coap --aqil 100 --uil 1 &;;
      off)    timeout 60 aaioairctrl -H $ipaddr set pwr=0 &;;
      on)     timeout 60 aaioairctrl -H $ipaddr set pwr=1 &;;
      silent|sleep) timeout 60 aaioairctrl -H $ipaddr set mode=M om=s &;;
      turbo)  timeout 60 aaioairctrl -H $ipaddr set mode=M om=t &;;
      *)      timeout 60 aaioairctrl -H $ipaddr set mode=M om=$1 &;;
    esac
  fi
done
