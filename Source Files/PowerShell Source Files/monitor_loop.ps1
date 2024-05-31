$engine_name = $args[0]
$engine_name = "unity"
$with_input = $args[1]
$with_input = $true
$loop_count = $args[2]
$loop_count = 1

adb root
Start-Sleep(4)

#0..($loop_count - 1) | % {
#    $return_value = & .\monitor.ps1 $engine_name $with_input
#    Write-Host($return_value)
#    #wait a second
#    Start-Sleep(5)
#}

$engine_name = "godot"

0..($loop_count - 1) | % {
    $return_value = & .\monitor.ps1 $engine_name $with_input
    Write-Host($return_value)
    #wait a second
    Start-Sleep(5)
}