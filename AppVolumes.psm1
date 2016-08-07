<#
    -----------------------------------------------------------------------------
    GENERAL FUNCTIONS
    -----------------------------------------------------------------------------
#>
function Connect-AppVolumes
{
  <#

  #>
    [CmdletBinding()]

    param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$username,

    [parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty()]
    [String]$password

    )

    if ((!$username) -or (!$password)){
      $cred = Get-Credential
      $username = $cred.UserName
      $password = $cred.GetNetworkCredential().Password
    }

    $body = @{
      username = $username
      password = $password
    }
    try{
      Invoke-RestMethod -SessionVariable Login -Method Post -Uri "http://$server/cv_api/sessions" -Body $body
    }
    Catch{

    if ($_.Exception.Message -match '401')
        {   
            
            
        }

    }
      Set-Variable -Name Login -value $login -Scope global
      Set-Variable -Name Server -value $server -Scope global
      
}

function Set-AppVolumeAssignment
{
  <#

  #>
  
  param(
    [parameter(Mandatory=$true)]
    [ValidateSet('assign','unassign',ignorecase=$true)]
    [string]$AssignmentType

    )
  
    try{
      $results = (Invoke-RestMethod -WebSession $Login -Method Post -Uri "http://$server/cv_api/assignments?action_type=$AssignmentType&id=1&assignments%5B0%5D%5Bentity_type%5D=User&assignments%5B0%5D%5Bpath%5D=CN%3Dvi-admin%2CCN%3DUsers%2CDC%3Dlab%2CDC%3Dlocal&rtime=true&mount_prefix=").Content | ConvertFrom-Json
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
    return $results
}


#Should probably restructure data
function Get-AppVolumeAssignments
{
  <#

  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/$AppID/assignments").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    $obj = New-Object System.Object
    $i=0
    while ($i -ne $r.name.Length){
    
    $obj | Add-Member –Type NoteProperty –Name Assignment[$i] –Value $r.name[$i].Substring($r.name[$i].IndexOf('">')+2,($r.name[$i].IndexOf('</')-$r.name[$i].IndexOf('">')-2))

    $i++
    }
    return $obj

}

#Needs work
function Get-AppVolumeCurrentAttachements
{
  <#
  Needs work
  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/$AppID/attachments").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    $obj = New-Object System.Object
    $i=0
    while ($i -ne $r.name.Length){
    
    $obj | Add-Member –Type NoteProperty –Name User[$i] –Value $r.name[$i].Substring($r.name[$i].IndexOf('">')+2,($r.name[$i].IndexOf('</')-$r.name[$i].IndexOf('">')-2))
    $obj | Add-Member –Type NoteProperty –Name User[$i] –Value $r.entity

    $i++
    }
    return $r

}

#Haven't Started
function Set-AppVolumesWritableVolumeEnabled
{
  <#

  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/writables/$AppID").Content | ConvertFrom-Json).writable
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}

#Haven't Started
function Set-AppVolumesWritableVolumeDisabled
{
  <#

  #>
}


<#
    -----------------------------------------------------------------------------
    Complete
    -----------------------------------------------------------------------------
#>
function Get-AppVolumes
{
  <#

  #>
    try{
      $results = (Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks").Content | ConvertFrom-Json
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
           
        }
    }
    return $results
}

function Get-AppVolumesLicense
{
  <#

  #>
    try{
      $license = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/license").Content | ConvertFrom-Json).license
      $license_usage = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/license_usage").Content | ConvertFrom-Json).licenses
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
    
 
        
    $myLicense = New-Object System.Object
    $myLicense | Add-Member –Type NoteProperty –Name LicenseKey –Value $license.keynow
    $myLicense | Add-Member –Type NoteProperty –Name DateAdded –Value $license.keycreate
    $myLicense | Add-Member -Type NoteProperty -Name ActiveDirectory -Value $license.ft.active_directory
    $myLicense | Add-Member -Type NoteProperty -Name Administrators -Value $license.ft.administrators
    $myLicense | Add-Member -Type NoteProperty -Name Hypervisor -Value $license.ft.hypervisor
    $myLicense | Add-Member -Type NoteProperty -Name Datastores -Value $license.ft.datastores
    $myLicense | Add-Member -Type NoteProperty -Name AppStacks -Value $license.ft.appstacks
    $myLicense | Add-Member -Type NoteProperty -Name WritableVolumes -Value $license.ft.writable_volumes
    $myLicense | Add-Member -Type NoteProperty -Name ConcurrentUserLicense -Value ($license_usage | Where-Object -property bar -Contains 'user_concurrent' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name ConcurrentUserActive -Value ($license_usage | Where-Object -property bar -Contains 'user_concurrent' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name NamedUserLicense -Value ($license_usage | Where-Object -property bar -Contains 'user' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name NamedUserActive -Value ($license_usage | Where-Object -property bar -Contains 'user' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name TerminalUserConcurrentLicense -Value ($license_usage | Where-Object -property bar -Contains 'terminal_user_concurrent' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name TerminalUserConcurrentActive -Value ($license_usage | Where-Object -property bar -Contains 'terminal_user_concurrent' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name TerminalUserNamedLicense -Value ($license_usage | Where-Object -property bar -Contains 'terminal_user' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name TerminalUserNamedActive -Value ($license_usage | Where-Object -property bar -Contains 'terminal_user' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name DesktopConcurrentLicense -Value ($license_usage | Where-Object -property bar -Contains 'desktop_concurrent' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name DesktopConcurrentActive -Value ($license_usage | Where-Object -property bar -Contains 'desktop_concurrent' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name DesktopNamedLicense -Value ($license_usage | Where-Object -property bar -Contains 'desktop' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name DesktopNamedActive -Value ($license_usage | Where-Object -property bar -Contains 'desktop' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name ServerConcurrentLicense -Value ($license_usage | Where-Object -property bar -Contains 'server_concurrent' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name ServerConcurrentActive -Value ($license_usage | Where-Object -property bar -Contains 'server_concurrent' | Select-Object num).num
    $myLicense | Add-Member -Type NoteProperty -Name ServerNamedLicense -Value ($license_usage | Where-Object -property bar -Contains 'server' | Select-Object cap).cap
    $myLicense | Add-Member -Type NoteProperty -Name ServerNamedActive -Value ($license_usage | Where-Object -property bar -Contains 'server' | Select-Object num).num
       
    return $mylicense    
}
function Get-AppVolumesADSettings
{
  <#

  #>

   try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/ad_settings").Content | ConvertFrom-Json).config_ad
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
    
   
    return $r
      
}
function Get-AppVolumesCurrentAdminGroup
{
  <#

  #>
  
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/administrator").Content | ConvertFrom-Json).current_admin
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
    
    return $r
  
}
function Get-AppVolumesvCenterUser
{
  <#

  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/machine_managers").Content | ConvertFrom-Json).machine_managers
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
    
    return $r
}
function Get-AppVolumesDatastores
{
  <#

  #>

  try{
      $r = (Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/datastores").Content | ConvertFrom-Json
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r        
}
function Get-AppVolumeDetails
{
  <#

  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/$AppID").Content | ConvertFrom-Json).appstack
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumeApps
{
  <#

  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/$AppID/applications").Content | ConvertFrom-Json).applications
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumeFileLocation
{
  <#

  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/$AppID/files").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesWritableVolumes
{
  <#

  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/writables").Content | ConvertFrom-Json).datastores.writable_volumes
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}
function Get-AppVolumesWritableVolumeDetails
{
  <#

  #>

   param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$VolumeID

    )

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/writables/$VolumeID").Content | ConvertFrom-Json).writable
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesAttachments
{
  <#

  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/attachments").Content | ConvertFrom-Json).attachments
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesCurrentAssignments
{
  <#
  Needs HTML formatting work
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/assignments").Content | ConvertFrom-Json).assignments
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}
function Get-AppVolumesApps
{
  <#
  Needs formatting work
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/applications").Content | ConvertFrom-Json).applications
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesAppDetails
{
  <#
  Seems to be unnecessary with Get-AppVolumesApps
  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/applications/$AppID").Content | ConvertFrom-Json).application
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesOnlineEntities
{
  <#
  Needs formatting work
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/online_entities").Content | ConvertFrom-Json).online.records
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesUsers
{
  <#
  
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/users").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesAgents
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/computers").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesGroups
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/groups").Content | ConvertFrom-Json).groups
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesOUs
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/org_units").Content | ConvertFrom-Json).org_units
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesMachines
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/machines").Content | ConvertFrom-Json).machines
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesStorage
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storages").Content | ConvertFrom-Json).storages
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r
}
function Get-AppVolumesStorageGroups
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storage_groups").Content | ConvertFrom-Json).storage_groups
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }

    return $r

}
function Get-AppVolumesStorageGroupDetails
{
  <#

  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageGroup

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storage_groups/$StorageGroup").Content | ConvertFrom-Json).storage_group
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}
function Get-AppVolumesLog
{
  <#

  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/activity_logs").Content | ConvertFrom-Json).actlogs.logs
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}
function Get-AppVolumesSystemMessages
{
  <#

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/system_messages").Content | ConvertFrom-Json).allmessages.system_messages
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }
    }
 
    $i = 0
    

    #Create Table object
    $table = New-Object system.Data.DataTable 'System Messages'

    #Define Columns
    $col1 = New-Object system.Data.DataColumn Event,([string])
    $col2 = New-Object system.Data.DataColumn Date,([string])

    #Add the Columns
    $table.columns.add($col1)
    $table.columns.add($col2)

    foreach ($message in $r.message){
      

        #Create a row
        $row = $table.NewRow()

        #Enter data in the row
        $row.Event = $r.message[$i]
        $row.Date = $r.event_time_human[$i] 

        #Add the row to the table
        $table.Rows.Add($row)


        $i++


        }

    return $table | Select-Object date,Event

}

<#
    -----------------------------------------------------------------------------
    Not tested
    -----------------------------------------------------------------------------
#>
function Start-AppVolumesStorageReplication
{
  <#

  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageGroup

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/storage_groups/$StorageGroup/replicate").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}
function Add-AppVolumesStoragetoGroup
{
  <#

  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks/storage_groups/$StorageID/import").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r

}
function Get-AppVolumesPendingActions
{
  <#

  #>

   try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/pending_activities").Content | ConvertFrom-Json).allactivities.pending_activities
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            Connect-AppVolumes
            
        }

    }
    return $r
}

