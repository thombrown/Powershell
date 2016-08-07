#vSphere client Links - https://kb.vmware.com/selfservice/microsites/search.do?language=en_US&cmd=displayKC&externalId=2089791
#VMware Web Client Plugin - http://www.virtuallyghetto.com/2016/04/quick-tip-silent-installation-of-the-vmware-client-integration-plugin-cip.html

$url = "http://vsphereclient.vmware.com/vsphereclient/VMware-ClientIntegrationPlugin-6.0.0.exe"
$output = "$PSScriptRoot\VMware-ClientIntegrationPlugin.exe"
$start_time = Get-Date

(New-Object System.Net.WebClient).DownloadFile($url, $output)

Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"  

$url = "http://vsphereclient.vmware.com/vsphereclient/3/0/1/6/4/4/7/VMware-viclient-all-6.0.0-3016447.exe"
$output = "$PSScriptRoot\VMware-viclient.exe"
$start_time = Get-Date

(New-Object System.Net.WebClient).DownloadFile($url, $output)

Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"  