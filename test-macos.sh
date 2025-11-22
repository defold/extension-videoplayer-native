#!/usr/bin/env bash

if [ -z "$BOB" ];
then
    BOB=bob.jar
fi

PLATFORM=${PLATFORM:-arm64-darwin}
BUILD_DIR=build/$PLATFORM

set -e
java -jar $BOB --debug --archive --platform $PLATFORM clean build bundle -bo $BUILD_DIR

APP_PATH=$BUILD_DIR/VideoPlayer/VideoPlayer.app
if [ -d "$APP_PATH" ]; then
    echo "Built macOS bundle at $APP_PATH"
    echo "Launching..."
    open "$APP_PATH"
else
    echo "macOS bundle not found at $APP_PATH"
fi
