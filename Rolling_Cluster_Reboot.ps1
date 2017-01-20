#Original script was written by JD Green - http://jdgreen.io/rolling-reboot-vsphere-cluster-powercli/
#Script was modified to support VMware Horizon Instant Clones and VSAN by Thomas Brown


 
# Check to make sure both arguments exist
if ($args.count -ne 2) {
Write-Host "Usage: reboot-vmcluster.ps1 <vCenter> <cluster>"
exit
}
# Set vCenter and Cluster name from Arg

$vCenterServer = $args[0] 
$ClusterName = $args[1]

# Connect to vCenter
Connect-VIServer -Server $vCenterServer | Out-Null

# Get VMware Server Object based on name passed as arg
$ESXiServers = Get-VMHost -Location $ClusterName


# Reboot ESXi Server Function
Function RebootESXiServer ($CurrentServer) {
  # Get VI-Server name
  $ServerName = $CurrentServer.Name

  #Check to see if Instant Clone maintenance mode is disabled (or exists)
  if ((Get-Annotation -Entity (Get-VMHost -Name $ServerName) -CustomAttribute "InstantClone.Maintenance").Value -eq ""){
    Write-Host "Entering Instant Clone Maintenance Mode"
    #Enter Instant Clone maintenance mode
    Set-Annotation -Entity (Get-VMHost -Name $ServerName) -CustomAttribute "InstantClone.Maintenance" -Value "1"
  }

  # Put server in maintenance mode
  Write-Host "** Rebooting $ServerName **"
  Write-Host "Entering Maintenance Mode"
  
  #Check to see if VSAN is enabled on the cluster
  if((Get-Cluster -Name $clustername).VsanEnabled){
    #Check for PowerCLI 6.5 or higher for VSAN Data Migration Mode Command
    if((Get-PowerCLIVersion).Major -ge '6' -and (Get-PowerCLIVersion).minor -ge '5'){

      #Ensure VSAN data accessbility when going into maintenance mode
      Set-VMHost $CurrentServer -State Maintenance -Evacuate:$true -VsanDataMigrationMode EnsureAccessibility -Confirm:$false
    }
    else {
      Write-Host "PowerCLI 6.5 or later required for VSAN Data Migration compatibility. Rerun script with PowerCLI 6.5 or later"
    }
  }
  else{
    #Do a normal maintenance mode if no VSAN
    Set-VMhost $CurrentServer -State maintenance -Evacuate:$true | Out-Null
  }

  #If Instant Clone Maintenance Mode hasn't equaled 2 yet, Instant clones are still present
  do {
    sleep 15
    Write-Host "Waiting for Instant Clones to Evacuate"
  }
  while ((Get-Annotation -Entity (Get-VMHost -Name $ServerName) -CustomAttribute "InstantClone.Maintenance").Value -ne "2")
  
  
  # Reboot host
  Write-Host "Rebooting"
  Restart-VMHost $CurrentServer -confirm:$false | Out-Null

  # Wait for Server to show as down
  do {
    sleep 15
    $ServerState = (get-vmhost $ServerName).ConnectionState
  }
  while ($ServerState -ne "NotResponding")
  Write-Host "$ServerName is Down"

  # Wait for server to reboot
  do {
    sleep 60
    $ServerState = (get-vmhost $ServerName).ConnectionState
    Write-Host "Waiting for Reboot …"
  }
  while ($ServerState -ne "Maintenance")
  Write-Host "$ServerName is back up"

  # Exit maintenance mode
  Write-Host "Exiting Maintenance mode"
  #Exit Instant Clone Maintenance Mode
  Set-Annotation -Entity (Get-VMHost -Name $CurrentServer) -CustomAttribute "InstantClone.Maintenance" -Value ""
  Set-VMhost $CurrentServer -State Connected | Out-Null
  Write-Host "** Reboot Complete **"
  Write-Host ""
}

## MAIN
foreach ($ESXiServer in $ESXiServers) {
RebootESXiServer ($ESXiServer)
}

# Disconnect from vCenter
Disconnect-VIServer -Server $vCenterServer -Confirm:$False
