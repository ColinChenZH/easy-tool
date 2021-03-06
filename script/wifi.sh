#! /bin/bash

readonly wifi_menu_array=(#"Open WiFi"    "wifi_open"\
			  #"Close WiFi"   "wifi_close"\
			  "Connect WiFi" "wifi_connect"\
			  #"Disconnect WiFi" "wifi_disconnect"\
			  "Change Country"  "wifi_change_country"\
			  "Scan WiFi List" "wifi_scan"\
			  "Refresh Connection" "wifi_refresh"\
			  "Back" "break")

function wifi_open () {
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_enable{}'"
}

function wifi_close () {
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_disable{}'"
}

function wifi_connect () {
	read -p "Enter ssid:" wifissid
	read -p "Enter Password:" wifipassw
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_onboard{}'"
	wifiMsgStr="adk-message-send 'connectivity_wifi_connect {ssid:\"$wifissid\"password:\"$wifipassw\" homeap:true}'"
	gnome-terminal -x adb shell "$wifiMsgStr"
	echo "Waiting For 3s"
	sleep 3s
	pid=`ps -ef | grep -w "is_wifi_stable.sh" | grep -v "grep" | awk '{print $2}'`
	if [[ -z ${pid} ]]
	then
		./script/sys/is_wifi_stable.sh &
	fi
}

function wifi_disconnect () {
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_onboard{}'"
}

function wifi_change_country () {
	nationName=`adb shell adkcfg -f /data/adk.connectivity.wifi.db read connectivity.wifi.onboard_ap_country_code`
	echo "Current Nation Name: $nationName"
	echo ""
	read -p "Enter Nation Name:" nationName
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_onboard{}'"
	adb shell adkcfg -f /data/adk.connectivity.wifi.db write connectivity.wifi.onboard_ap_country_code $nationName --ignore
	adb reboot
}

function wifi_scan () {
	gnome-terminal -x adb shell "adk-message-monitor -a"
	gnome-terminal -x adb shell "adk-message-send 'connectivity_wifi_scan{}'"	
}

function wifi_refresh () {
	adb pull /etc/misc/wifi/wpa_supplicant.conf .
	wifiName=`grep 'ssid=\"' ./wpa_supplicant.conf`
	wifiNameStr=${wifiName#*\"}
	wifiNameStr=${wifiNameStr%\"*}
	rm ./wpa_supplicant.conf
}

function wifi_menu () {
	wifi_refresh
	while :
	do
		clear
		echo "      WiFi Connection"
		echo ""
		echo "   Connecting : $wifiNameStr"
		echo ""
		for ((i=0; i<$[${#wifi_menu_array[*]}/2]; i++))
		do
			echo "      $[$i+1]. ${wifi_menu_array[$[${i}*2]]}"
		done
		echo ""
		read -p "Enter Number:" wifiNum
		if [ $[${wifiNum}-1] -lt $[${#wifi_menu_array[*]}/2] ]
                then
			clear
			${wifi_menu_array[$[$[$wifiNum-1]*2+1]]}
                else
                        echo "Enter Error"
                fi
	done
}

wifi_menu
