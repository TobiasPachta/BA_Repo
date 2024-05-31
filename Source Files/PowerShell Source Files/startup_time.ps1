$engine_name = $args[0]
$loop_count = $args[1]
$working_dir = "C:\Users\Tobias\Documents\FH Burgenland\BA"
$regex_pattern_datetime = "\d{2}[-]\d{2} \d{2}[:]\d{2}[:]\d{2}\.\d{3}"
$regex_pattern_time = "\d{2}[:]\d{2}[:]\d{2}\.\d{3}"


$file_name_report = "test_results\" + $engine_name + "\startup_time.csv"


cd $working_dir

adb logcat -c

if ($engine_name -eq "godot") {
    $apk_name = "Android_Performance_Test_Godot.apk"
    $app_name = "com.example.performance_test_godot"
    $app_activity = "com.godot.game.GodotApp"
    $out_file_location = "/data/data/com.example.performance_test_godot/files/out.txt"
} else {
    $apk_name = "Android_Performance_Test_Unity.apk"
    $app_name = "com.example.performance_test_unity"
    $app_activity = "com.unity3d.player.UnityPlayerActivity"
    $out_file_location = "/storage/emulated/0/Android/data/com.example.performance_test_unity/files/out.txt"
}
#uninstall app
$output = adb uninstall $app_name
Write-Host("Uninstall: " + $output)
#install app und unterdrücke fehlernachricht die immer kommt obwohl eh alles geht...
$output = adb install $apk_name 2>$null
Write-Host("Install: " + $output)

#start app
$output = adb shell am start -n ($app_name + "/"  +$app_activity)
Write-Host("Starting App: " + $output)
$startup_timestamp_start_android = adb shell 'echo $(date +%T)${EPOCHREALTIME:10:4}'
#wait for app start
Start-Sleep(7)

#quit app
$output = adb shell am force-stop $app_name

#wait a second
Start-Sleep(1)

#log nachricht mit startup timestamp zuweisen
$startup_timestamp_string = adb logcat -d -v time | Select-String -Pattern "Loading finished"
#zeitstempel des android systems holen
$startup_timestamp_android = [regex]::Match($startup_timestamp_string,$regex_pattern_datetime).Value
#zeitstempel der engine holen
$startup_timestamp_engine_ms = [regex]::Matches($startup_timestamp_string,"Loading finished (\d+)")[0].Value
$startup_timestamp_engine_ms = [regex]::Matches($startup_timestamp_engine_ms,"(\d+)")[0].Value
$startup_timestamp_android_ms = ([DateTime]::ParseExact($startup_timestamp_android.Split(" ")[1], "HH:mm:ss.fff",$null) - [DateTime]::ParseExact($startup_timestamp_start_android, "HH:mm:ss.fff",$null)).TotalMilliseconds

if (-not (Test-Path $file_name_report)) {
    Add-Content -Path $file_name_report -Value "Engine_Startup,Android_Startup" -Encoding UTF8
}

Add-Content -Path $file_name_report -Value ($startup_timestamp_engine_ms + "," + $startup_timestamp_android_ms) -Encoding UTF8

#$csv_out | Export-Csv -Path ($file_name_report) -Append -Delimiter ";" -NoTypeInformation
