#!/bin/bash
export PATH="$PATH:/home/pi/.local/bin" # you likely have to modify this path, maybe you don't need it at all

### edit these lines from here ###
pathToRamdisk="/ramdisk/aioairctrl/"  # if you already use this path, this script will cause havoc!
                                      # this script will happily delete or modify anything in this path
iReadTheWarning=false    # change this to true after reading the warning
ipAddrBase="192.168.6."
master=150  #last ipv4 block of master device
sleepTime=10
print=true
ipAddrRange="$(echo {150..152})"  #last ipv4 block of all devices including master
autoTurbo=true
autoTurboOnAbove=80  #input is PM 2.5 value
autoTurboOffBelow=40  #input is PM 2.5 value
ccn=5    # charCountName, how many chars does your device names have? (table spacing) do not go below 3
### to here ###

trap stopeverything SIGINT
stopeverything(){
  iReadTheWarning=false
  killall aioairctrl
  if $print ; then echo "";  echo "bye bye"; fi
}
killall aioairctrl
noHuman=0
for i in $ipAddrRange
do
  aioairctrl -H $ipAddrBase$i status-observe -J >> $pathToRamdisk$i.txt &
  lineCount[${i}]=$(cat $pathToRamdisk$i.txt | wc -l)
  repeat[${i}]=0
  if [ ${lineCount[$i]} == "0" ] # force a change on the device so it has a reason to send a new message
  then
    aioairctrl -H $ipAddrBase$i set om=t
    sleep 1
    aioairctrl -H $ipAddrBase$i set mode=P
  fi
done

while $iReadTheWarning
do
  sleep $sleepTime
  for i in $ipAddrRange ################ start of watchdog
  do
    lineCountOld[${i}]=${lineCount[$i]}
    lineCount[${i}]=$(cat $pathToRamdisk$i.txt | wc -l)
    #count loops without update
    if [ ${lineCount[$i]} == ${lineCountOld[$i]} ]
    then
      repeat[${i}]=$((${repeat[$i]} + 1))
    else
      repeat[${i}]=0
    fi
    #observer not working? restart if 30 loops without update
    if [ ${repeat[$i]} -gt 30 ]
    then
      kill $(ps -aux | grep -i aioairctrl | grep -i $ipAddrBase$i | awk '//{print $2}')
      aioairctrl -H $ipAddrBase$i status-observe -J >> $pathToRamdisk$i.txt &
      if $print ; then echo "restarting "$i; fi
      repeat[${i}]=0
    fi
    ########### end of watchdog
    device[${i}]=$(tail -n 1 $pathToRamdisk$i.txt)
    deviceOm[${i}]=$(echo ${device[$i]} | jq -r '.om')
    devicePm[${i}]=$(echo ${device[$i]} | jq -r '.pm25')
    devicePwr[${i}]=$(echo ${device[$i]} | jq -r '.pwr')
    deviceMode[${i}]=$(echo ${device[$i]} | jq -r '.mode')
    deviceName[${i}]=$(echo ${device[$i]} | jq -r '.name')
  done
  #prevent ramdisk from overflow
  for j in $pathToRamdisk*
  do
    if [ $(cat $j | wc -l) -gt 1000 ]
    then
      if $print ; then echo "$j"; fi
      tail -n 10 $j > $j.backup
      cat $j.backup > $j
      rm $j.backup
    fi
  done

  if $print
  then
    echo ""
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" $(date +%F_%H-%M-%S) ${deviceName[*]}
    line="--------------------------------------------------------"
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" $line $line $line $line
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "no updates since" ${repeat[*]}
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "lineCount" ${lineCount[*]}
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "Speed" ${deviceOm[*]}
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "PM2.5" ${devicePm[*]}
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "Power" ${devicePwr[*]}
    printf "%20.20s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s | %"$ccn"."$ccn"s |\n" "Mode" ${deviceMode[*]}
  fi
  #autoTurbo function
  if $autoTurbo
  then
    #if in auto mode and pm25 is really high -> use turbo
    if [ "${devicePm[$master]}" -gt $autoTurboOnAbove ] && [ "${deviceMode[$master]}" == "P" ]
    then
      if $print ; then echo "turbo"; fi
      aioairctrl -H $ipAddrBase$master set om=t
      noHuman=1
      deviceOm[${master}]="t"
    fi
    # in case of auto turbo (see above) go back to normal if pm25 low enough but only if turbo was not invoked by human
    if [ "${devicePm[$master]}" -lt $autoTurboOffBelow ] && [ "${deviceMode[$master]}" == "M" ] && [ "$noHuman" == "1" ]
    then
      if $print ; then echo "auto"; fi
      aioairctrl -H $ipAddrBase$master set mode=P
      noHuman=0
      deviceOm[${master}]="2"
    fi
  fi
  # master-slave-function
  for i in $ipAddrRange
  do
    if [ "${devicePwr[$i]}" != "${devicePwr[$master]}" ]; then aioairctrl -H $ipAddrBase$i set pwr="${devicePwr[$master]}"; if $print ; then echo $i" pwr"; fi; fi
    if [ "${deviceOm[$i]}" != "${deviceOm[$master]}" ]; then aioairctrl -H $ipAddrBase$i set om="${deviceOm[$master]}"; if $print ; then echo $i" om"; fi; fi
  done
done
