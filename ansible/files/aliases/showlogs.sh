#!/bin/bash

showpclog() {
lines=600
if [ $1 ]; then
        lines=$1
fi
tail -f -n $lines /usr/WSApps/UKGGPC2/Guidewire/logs/pclog.log
}
alias showpclog=showpclog

showcmlog() {
lines=600
if [ $1 ]; then
        lines=$1
fi
tail -f -n $lines /usr/WSApps/UKGGCM/Guidewire/logs/ablog.log
}
alias showcmlog=showcmlog

showcclog() {
lines=600
if [ $1 ]; then
        lines=$1
fi
tail -f -n $lines /usr/WSApps/UKGGCC/Guidewire/logs/cclog.log
}
alias showcclog=showcclog

showgpalog() {
lines=600
if [ $1 ]; then
        lines=$1
fi
tail -f -n $lines /usr/WSApps/UKGGPC/Guidewire/logs/pclog.log
}
alias showcclog=showcclog
