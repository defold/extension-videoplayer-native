#!/usr/bin/env bash

PACKAGENAME=com.defoldexample.videoplayer

if [ -z "$BOB" ];
then
    BOB=bob.jar
fi

if [ -z "$IDENTITY" ];
then
    echo "No IDENTITY specified"
    echo "Available identities"
    security find-identity -v -p codesigning
    exit 1
fi
if [ -z "$MOBILEPROVISION" ];
then
    echo "No MOBILEPROVISION specified"
    exit 1
fi

BUILDSERVER="--build-server=http://localhost:9000"

set -e
java -jar $BOB --debug --archive --platform armv7-darwin clean build bundle -bo build/armv7-android $BUILDSERVER

# Need the .app to run the debugger, otherwise it suffices with .ipa
#ios-deploy -d -b $APP
