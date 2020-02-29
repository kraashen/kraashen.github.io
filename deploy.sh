#!/bin/zsh

if ! hugo -D ; then
	echo "Error in creating site with Hugo"
	exit 1
fi

rsync -autvz ./public/ erani@lakka.kapsi.fi:~/sites/erani.kapsi.fi/www/.
