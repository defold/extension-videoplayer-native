java -jar bob.jar --archive --platform armv7-android build bundle -bo build/armv7-android
adb uninstall com.example.todo
adb install -r build\armv7-android\VideoPlayerTest\VideoPlayerTest.apk
adb shell am start -a android.intent.action.MAIN -n com.example.todo/com.dynamo.android.DefoldActivity
adb logcat -c "defold-videoplayer"
adb logcat -s "defold-videoplayer"
