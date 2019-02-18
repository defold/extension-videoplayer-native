#!/usr/bin/env bash

PACKAGENAME=com.defoldexample.videoplayer

if [ -z "$BOB" ];
then
    BOB=bob.jar
fi

#BUILDSERVER="--build-server=http://localhost:9000"

set -e
java -jar $BOB --debug --archive --platform armv7-android clean build bundle -bo build/armv7-android $BUILDSERVER

echo "Uninstall"
adb uninstall $PACKAGENAME
echo "Install"
adb install -r build/armv7-android/VideoPlayer/VideoPlayer.apk
echo "Starting ..."
adb shell am start -a android.intent.action.MAIN -n $PACKAGENAME/com.dynamo.android.DefoldActivity

sleep 1

PID=`adb shell ps | grep $PACKAGENAME | awk '{ print $2 }'`

echo PID=$PID

adb logcat | grep $PID
