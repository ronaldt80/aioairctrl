# Disclaimer
The __bash__ examples are neither eficcient nor elegant or best practice, __use them at your own risk__. They were only tested on a raspberry pi running __Raspbian 10 (buster)__ in combination with __Philips AC2889/10__ SWVersion`1.0.7` WifiVersion`AWS_Philips_AIR@64.3`.

# Instructions
You need `jq`
```bash
sudo apt install jq
```
and __you have to modify the first few lines__ in `master-slave.sh`. This script will bug a little till it got the first update from all devices. This will not happen unless something changes, like measured PM 2.5 or speed. The easiest way to force this update is to change the speed of the master device, wait 10 seconds and then change the master back to the original setting. This will force all other devices to change their speed too. 

In the sudo crontab `sudo crontab -e` add
```bash
@reboot sleep 10; /home/pi/ramdisk.sh
```
In the user crontab `crontab -e` add
```bash
@reboot sleep 30; /home/pi/master-slave.sh >> /ramdisk/aioairctrl/status.txt 2>&1
```
You could view the output (with coloring from grep) using
```bash
tail -f /ramdisk/aioairctrl/status.txt | grep -E 'PM.*|*'
```
