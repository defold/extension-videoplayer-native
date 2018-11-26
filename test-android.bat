java -jar bob.jar --debug --archive --platform armv7-android build bundle -bo build/armv7-android
adb uninstall com.defoldexample.videoplayer
adb install -r build\armv7-android\VideoPlayer\VideoPlayer.apk
adb shell am start -a android.intent.action.MAIN -n com.defoldexample.videoplayer/com.dynamo.android.DefoldActivity
adb logcat -c "defold-videoplayer"
adb logcat -s "defold-videoplayer"
