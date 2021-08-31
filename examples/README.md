The *.sh examples were only tested on a raspberry pi running Raspbian 10 (buster).
You need "jq"
sudo apt install jq

In the sudo crontab (sudo crontab -e) add
@reboot sleep 10; /home/pi/mount-ramdisk.sh

In the user crontab (crontab -e) add
@reboot sleep 30; /home/pi/luft-aio.sh >> /ramdisk/aioairctrl/status.txt 2>&1

You could view the output (with coloring from grep) using
tail -f /ramdisk/aioairctrl/status.txt | grep -E 'PM.*|*'
