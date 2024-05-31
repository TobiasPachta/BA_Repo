$engine_name = $args[0]
$with_input = $args[1]
$test_duration_in_ms = 15 * 60 * 1000
$working_dir = "C:\Users\Tobias\Documents\FH Burgenland\BA"
$regex_pattern_datetime = "\d{2}[-]\d{2} \d{2}[:]\d{2}[:]\d{2}\.\d{3}"
$regex_pattern_time = "\d{2}[:]\d{2}[:]\d{2}\.\d{3}"
$android_input_timestamp_list = New-Object System.Collections.ArrayList
$engine_input_timestamp_list = New-Object System.Collections.ArrayList

#$engine_name = "unity"
#$with_input = $false

#change directory to BA dir
cd $working_dir
#get file count
#$file_name = (Get-ChildItem -Path ("test_results\" + $engine_name) -File -Filter '*_raw.csv').Count
$file_name_report = "test_results\" + $engine_name + "\mean_values.csv"
$file_name_report_raw = "test_results\" + $engine_name + "\values_raw.csv"
#check if files already exist


#clear logcat
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
Start-Sleep(10)
#get app pid
$app_pid = adb shell pidof $app_name
Write-Host("PID: " + $app_pid)
Write-Host($with_input)
if ($with_input) {
    $list_with_timestamps = @()
    for ($i = 0; $i -lt 4000; $i++) {
        $list_with_timestamps += Get-Random -Minimum 100 -Maximum ($test_duration_in_ms/4000)
    }
    $timeframe_sum = 0
    $res_measurements = 1
    ForEach ($timeframe in $list_with_timestamps) {
        if ($timeframe_sum -ge ($res_measurements * ($test_duration_in_ms/150))) {
            Add-Content -Path ("test_results\" + $engine_name + "\cpumem_stats.txt") -Value (adb shell top -b -n 1 -p $app_pid -o %CPU,RES)
            $res_measurements += 1
            #Write-Host($res_measurements * ($test_duration_in_ms/10))
        }
        [System.Threading.Thread]::Sleep($timeframe)
        adb shell input tap (Get-Random -Minimum 50 -Maximum 1200) 1200
        $timeframe_sum += $timeframe
    }
    Start-Sleep(5)
} else {
#wait test duration in seconds
    Start-Sleep($test_duration_in_ms/1000)
}

#quit app
$output = adb shell am force-stop $app_name
Write-Host("Closing App: " + $output)

#wait a second
Start-Sleep(2)

#get log file
adb pull $out_file_location ("C:\Temp\" + $engine_name + "_out.txt")

$logcat_output = adb logcat -d -v time | Select-String -Pattern "action=ACTION_DOWN"
ForEach ($line in $($logcat_output -split "`r`n"))
{
    $temp_timestamp = [regex]::Match($line,$regex_pattern_datetime).Value
    $temp = $android_input_timestamp_list.Add($temp_timestamp)
}
$output = adb logcat -d -v time | Select-String -Pattern "Input registered"
ForEach ($line in $($output -split "`r`n"))
{
    $temp_timestamp = [regex]::Matches($line,$regex_pattern_time)[1].Value
    $temp = $engine_input_timestamp_list.Add($temp_timestamp)
}
Write-Host("Collected " + $android_input_timestamp_list.Count + " Android Timestamps")
Write-Host("Collected " + $engine_input_timestamp_list.Count + " Engine Timestamps")
if ($android_input_timestamp_list.Count -ne $engine_input_timestamp_list.Count) {
    Write-Error("Different sample size")
}
#log nachricht mit startup timestamp zuweisen
$startup_timestamp_string = adb logcat -d -v time | Select-String -Pattern "Loading finished"
#zeitstempel des android systems holen
$startup_timestamp_android = [regex]::Match($startup_timestamp_string,$regex_pattern_datetime).Value
#zeitstempel der engine holen
$startup_timestamp_engine_ms = [regex]::Matches($startup_timestamp_string,"Loading finished (\d+)")[0].Value
$startup_timestamp_engine_ms = [regex]::Matches($startup_timestamp_engine_ms,"(\d+)")[0].Value
$startup_timestamp_android_ms = ([DateTime]::ParseExact($startup_timestamp_android.Split(" ")[1], "HH:mm:ss.fff",$null) - [DateTime]::ParseExact($startup_timestamp_start_android, "HH:mm:ss.fff",$null)).TotalMilliseconds



$mean_input_registration_duration = 0
$min_input_reg = 1000
$max_input_reg = 0
$sample_count = $engine_input_timestamp_list.Count
$input_delay_list = New-Object System.Collections.ArrayList
0..($sample_count - 1) | % {
    $android_datetime = [DateTime]::ParseExact($android_input_timestamp_list[$_].Split(" ")[1], "HH:mm:ss.fff",$null)
    $engine_datetime = [DateTime]::ParseExact($engine_input_timestamp_list[$_], "HH:mm:ss.fff",$null)
    $input_delay = ($engine_datetime - $android_datetime).TotalMilliseconds
    $mean_input_registration_duration += $input_delay
    if ($input_delay -lt $min_input_reg) {$min_input_reg = $input_delay}
    if ($input_delay -gt $max_input_reg) {$max_input_reg = $input_delay}
    $temp = $input_delay_list.Add($input_delay)
}
$output_data = Import-Csv -Path ("C:\Temp\" + $engine_name + "_out.txt") -Delimiter ";"
#alle zeilen entfernen, wo die CPU Zeit == 0.0 ist für Unity, gibt zahlen als float aus
$output_data = $output_data | Where-Object { $_.CPU_ms -ne '0.0' }
#alle zeilen entfernen, wo die CPU Zeit == 0 ist, fü godot, gibt zahlen als int aus
$output_data = $output_data | Where-Object { $_.CPU_ms -ne '0' }
#letzte zeile entfernen, da die meist nicht vollständig ist
if ($output_data.Count -gt 0) {
    $output_data = $output_data[0..($output_data.Count - 2)]
}
Write-Host("$($output_data.Count) Zeilen im Logfile")
$means = @{}

$android_system_res_stats = Get-Content -Path ("test_results\" + $engine_name + "\cpumem_stats.txt")
$android_system_res_stats_cpu = New-Object System.Collections.ArrayList
$android_system_res_stats_ram = New-Object System.Collections.ArrayList
$values_in_next_line = $false
ForEach ($line in $($android_system_res_stats -split "`n")) {
    if ($values_in_next_line) {
        if ($line.Split(" ").Count -eq 2) {
            $temp = $android_system_res_stats_cpu.Add($line.Split(" ")[0])
            $temp = $android_system_res_stats_ram.Add($line.Split(" ")[1].Replace("M",""))
        } else {
            $temp = $android_system_res_stats_cpu.Add($line.Split(" ")[1])
            $temp = $android_system_res_stats_ram.Add($line.Split(" ")[2].Replace("M",""))
        }
        $values_in_next_line = $false
    }
    if ($line.Equals("%CPU [RES")) {
        $values_in_next_line = $true
    }
}


for ($i = 0; $i -lt $android_system_res_stats_ram.Count; $i++) {
    $output_data[$i] | Add-Member -MemberType NoteProperty -Name 'System_RAM' -Value $android_system_res_stats_ram[$i]
}

for ($i = 0; $i -lt $android_system_res_stats_cpu.Count; $i++) {
    $output_data[$i] | Add-Member -MemberType NoteProperty -Name 'System_CPU' -Value $android_system_res_stats_cpu[$i]
}

for ($i = 0; $i -lt $input_delay_list.Count; $i++) {
    $output_data[$i] | Add-Member -MemberType NoteProperty -Name 'Input_Delay' -Value $input_delay_list[$i]
}


foreach ($column in $output_data | Get-Member -MemberType Properties) {
    $columnName = $column.Name
    $columnValues = $output_data.$columnName | Where-Object { $_ -ne $null } | ForEach-Object { [double]$_ }
    $mean = ($columnValues | Measure-Object -Average).Average
    $min_val = ($columnValues | Measure-Object -Minimum).Minimum
    $max_val = ($columnValues | Measure-Object -Maximum).Maximum
    $means[$columnName] = $mean
    $means[$columnName + "_min"] = $min_val
    $means[$columnName + "_max"] = $max_val
    if ($columnValues.Count%2) {
        $means[$columnName + "_median"] = ($columnValues | Sort-Object)[$columnValues.Count/2]
    } else {
        $columnValues = $columnValues | Sort-Object
        $means[$columnName + "_median"] = ($columnValues[$columnValues.Count/2],$columnValues[$columnValues.count/2-1] | Measure-Object -Average).average
    }
    
}
#$means["Input_Delay"] = $mean_input_registration_duration/$sample_count
#$means["Min Input Delay"] = $min_input_reg
#$means["Max Input Delay"] = $max_input_reg
#if ($input_delay_list.Count%2) {
#    $means["Mean Input Delay"] = ($input_delay_list | Sort-Object)[$input_delay_list.Count/2]
#} else {
#    $input_delay_list = $input_delay_list | Sort-Object
#    $means["Mean Input Delay"] = ($input_delay_list[$input_delay_list.Count/2],$input_delay_list[$input_delay_list.count/2-1] | Measure-Object -Average).average
#}

$means["Startup_Engine_ms"] = $startup_timestamp_engine_ms
$means["Startup_Android"] = $startup_timestamp_android_ms


#fürjeden eintrag in means eine spalate erstellen, wie unten und anschließend die werte einfügen
$csv_out = New-Object PSObject -Property $means
$csv_out | Export-Csv -Path ($file_name_report) -Append -Delimiter ";" -NoTypeInformation
$output_data | Export-Csv -Path ($file_name_report_raw) -Append -Delimiter ";" -NoTypeInformation

#$means_csv = $means.GetEnumerator() | ForEach-Object {
#    [PSCustomObject]@{
#        ValueName = $_.Key
#        Value = $_.Value
#    }
#}

#$means_csv | Export-Csv -Path ($file_name_report) -Append -Delimiter ";" -NoTypeInformation

#uninstall app
$output = adb uninstall $app_name
Write-Host("Uninstall: " + $output)

Exit 0