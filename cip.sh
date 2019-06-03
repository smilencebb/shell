#!/usr/bin/env bash
#HostName 
LocalIP=$(curl -ks ip.sb)
HostName=$(curl -ks http://freeapi.ipip.net/$LocalIP)
#Telegram API
bot_api_key="697362377:AAGvEx2yYghmYsgrclTzCBpGovraJvtL3bQ"
chat_id="-312563634"

NIC=`ls /sys/class/net |grep -v -E 'docker|lo|veth'`


[[ ! -e "/root/banip.txt" ]] && touch banip.txt
[[ ! -e "nowip.txt" ]] && touch nowip.txt
[[ ! -e "/tmp/times.log" ]] && touch /tmp/times.log
echo "0" > /tmp/times.log
if [ ! -f /root/banip.txt ];then
   echo 8.8.8.8 >> /root/banip.txt
fi

Ver="0.01"
Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Font_color_suffix="\033[0m"
Tip="${Green_font_prefix}[Tip]${Font_color_suffix}"
WARNING="${Red_font_prefix}[WARNING]${Font_color_suffix}"
Error="${Red_font_prefix}[Error]${Font_color_suffix}"
Info="${Green_font_prefix}[Message]${Font_color_suffix}"
Separator="——————————————————————————————————————————"


Change_IP(){
	clear
	echo -e " ${WARNING} IP:${IP} is blocked by TCP."
	[[ ! -n "$( cat banip.txt | grep ${IP} )" ]] && echo -e "${IP}" >> banip.txt
	 dhclient -r -v $NIC
     rm -rf /var/lib/dhcp/*
     ps aux |grep dhclient |grep -v grep |awk -F ' ' '{print $2}' | xargs kill -9 2>/dev/null
     dhclient -v $NIC
	last_times=$(cat /tmp/times.log)
	now_times=$[${last_times}+1]
	echo "${now_times}" > /tmp/times.log
	IP=$(curl -ks ip.sb)
	echo -e " ${Tip} No.${now_times} Now IP: ${IP}"
}

Send_TG_Message(){
	if [[ -n "$( cat nowip.txt | grep "${New_IP}" )" ]] ; then
		echo -e " ${Tip} No changes."
		break
	else
		Message="HostName: ***${HostName}*** Date:\[ $(date +"%Y-%m-%d %X") ] Now IP:  ***${New_IP}***"
		curl -g "https://api.telegram.org/bot${bot_api_key}/sendMessage?text=${Message}&chat_id=${chat_id}&parse_mode=Markdown"
		echo "${New_IP}" > nowip.txt
		clear
	fi
}

while true
	do
		IP=$(curl -ks ip.sb)
		q=2
		[[ -n "$( cat banip.txt | grep ${IP} )" ]] && q=1 
		if [[ "$q" -ne "1" ]] ; then
			[ -z "`grep ^Port /etc/ssh/sshd_config`" ] && ssh_port=22 || ssh_port=`grep ^Port /etc/ssh/sshd_config | awk '{print $2}'`
			Test1=$(curl -ks https://cn-zjct-tcping.torch.bgp.sh:10006/${IP}/${ssh_port} | grep false)
			Test2=$(curl -ks https://cn-qzct-tcping.torch.bgp.sh:10005/${IP}/${ssh_port} | grep false)
			Test3=$(curl -ks https://cn-shenzhen-aliyun-tcping.torch.njs.app/${IP}/${ssh_port} | grep false)
			Result=$( echo -e "${Test1}\n${Test2}\n${Test3}" | grep "false" | wc -l )
			[[ "${Result}" -gt 2 ]] && q=1
			[[ "${Result}" -le 2 ]] && q=2
		fi
		[[ "$q" -eq "1" ]] && Change_IP
		if [[ "$q" -eq "2" ]] ; then
			IP=$(curl -ks ip.sb)
			echo -e " ${Tip} Now IP: ${IP}"
			New_IP=$(curl -ks ip.sb)
			Send_TG_Message
			sleep 30s
		fi	
	done
