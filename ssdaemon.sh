#!/usr/bin/env bash
while :
do
	for i in `netstat -tlnp |grep -E "873|1099|152|153|156|21111|21112|21113" |awk '$2 >30 {print $7}' |cut -d"/" -f1 |awk '!a[$0]++'`
	do
		for j in `docker inspect -f "{{.Id}} {{.State.Pid}}"  $(docker ps -q)|grep $i |awk '{print $1}'`
		do 
			docker restart $j
		done
	done
	sleep 5
done