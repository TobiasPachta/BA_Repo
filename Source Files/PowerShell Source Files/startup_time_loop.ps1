$engine_name = $args[0]
$engine_name = "godot"
$with_input = $args[1]
$with_input = $true
$loop_count = $args[2]
$loop_count = 150

adb root
Start-Sleep(5)
<#
0..($loop_count - 1) | % {
    $return_value = & .\startup_time.ps1 $engine_name $with_input
    Write-Host($return_value)
    Start-Sleep(1)
}
#>
$engine_name = "unity"

0..($loop_count - 1) | % {
    $return_value = & .\startup_time.ps1 $engine_name $loop_count
    Write-Host($return_value)
    Start-Sleep(1)
}

