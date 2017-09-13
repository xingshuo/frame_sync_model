#!/bin/bash

#sh netdelay.sh add #add qdisc
#sh netdelay.sh chg [延迟] [延迟波动] [丢包率]
#sh netdelay.sh del  #del qdisc

DEV='wlan0'

case "$1" in
    add)
        sudo tc qdisc add dev $DEV root netem delay 1ms
        tc qdisc show
        ;;
    del)
        sudo tc qdisc del dev $DEV root netem
        ;;
    chg)
        if [ $# -eq 1 ] ;then
            sudo tc qdisc change dev $DEV root netem delay 100ms        
        elif [ $# -eq 2 ] ;then
            sudo tc qdisc change dev $DEV root netem delay $2ms
        elif [ $# -eq 3 ] ;then
            sudo tc qdisc change dev $DEV root netem delay $2ms $3ms
        elif [ $# -ge 4 ] ;then
            sudo tc qdisc change dev $DEV root netem delay $2ms $3ms loss $4%
        fi
        tc qdisc show
        ;;
    *)
        echo "please see the annotation in file netdelay.sh"
esac