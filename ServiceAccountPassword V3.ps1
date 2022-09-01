#Requires -RunAsAdministrator 
Start-Transcript -OutputDirectory c:\temp\logfiles
 $usercredential= Get-Credential

 if(!$usercredential){exit}

# Service Password updates

Get-WmiObject win32_service | Where-Object{$_.StartName -eq $usercredential.UserName }| Stop-Service -force

$Services = Get-WmiObject win32_service | Where-Object{$_.StartName -eq $usercredential.UserName }

foreach ($service in $Services)
{
$Service.Change($Null,$Null,$Null,$Null,$Null,$Null,$Null,$usercredential.Password,$Null,$Null,$Null)

$Service.startService().ReturnValue

sleep -Seconds 5 

}

#IIS app pool password change
Import-Module WebAdministration
$applicationPools = Get-ChildItem IIS:\AppPools | where { $_.processModel.userName -eq $usercredential.UserName }
foreach($pool in $applicationPools)
{
    Stop-WebAppPool -Name $pool.name
    $pool.processModel.userName = $usercredential.UserName
    $pool.processModel.password = $usercredential.Password
    
    $pool | Set-Item
    Start-WebAppPool -Name $pool.name
}
# Setting credential for ACMManagerWebSVC 
Set-WebConfigurationProperty -pspath 'IIS:\Sites\ACM\ACMManagerWebSvc'  -filter "system.webServer/security/authentication/anonymousAuthentication" -name "userName" -value $usercredential.UserName
Set-WebConfigurationProperty -pspath 'IIS:\Sites\ACM\ACMManagerWebSvc'  -filter "system.webServer/security/authentication/anonymousAuthentication" -name "password" -value $usercredential.Password

#Task scheduler password change

$tasks = Get-ScheduledTask | Where-Object { $_.Principal.UserId -eq $usercredential.UserName }
foreach ($task in $tasks) {
    $myTask = $task.TaskPath+$task.TaskName
    echo changing $myTask
    schtasks /change  /tn $myTask  /ru $usercredential.UserName /rp $usercredential.Password
}


Stop-Transcript
