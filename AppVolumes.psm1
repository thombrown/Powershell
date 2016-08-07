<#

.SYNOPSIS
This is a Powershell Module for VMware AppVolumes

.DESCRIPTION
This module leverages the RESTful API built in to VMware AppVolumes.

.NOTES
Author: Thomas Brown

It was written against AppVolumes version 2.11 and has not been tested against any other version as of 8/7/16.

.LINK
http://github.com/thombrown
http://www.thomas-brown.com
VMware AppVolumes API Reference Guide: https://chrisdhalstead.net/2015/12/30/vmware-app-volumes-api-reference/
#>


function Set-AppVolumeAssignment
{
  <#
  .DESCRIPTION
   This function is used to assign and unassign appstacks.  Please note that the entity must be in Directory Services format, Ex: CN=vi-admin,CN=users,DC=lab,DC=local.  This is a limitation of the AppVolumes API

  .PARAMETER AssignmentType
    Tells the API if you wish to assign or unassign the appstack
  .PARAMETER AppID
    This is the ID of the appstack you wish to modify.  If you don't know the ID use the Get-AppVolumes function
  .PARAMETER entityType
    This tells AppVolumes what type of entity you would like to assign the appstack to.  Options are computer, user, group, or orgunit
  .PARAMETER entity
    This is the actual user, computer, orgunit or group that you want to assign. Please note that the entity must be in Directory Services format, Ex: CN=vi-admin,CN=users,DC=lab,DC=local.  This is a limitation of the AppVolumes API
  .PARAMETER instant
    If true, this will instantly attach or detach the appstack.  If false, this will attach or detach on next login/logout.

  #>
  
  param(
    [parameter(Mandatory=$true)]
    [ValidateSet('assign','unassign',ignorecase=$true)]
    [string]$AssignmentType,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID,
    
    [parameter(Mandatory=$true)]
    [ValidateSet('computer','user', 'group', 'orgunit', ignorecase=$true)]
    [string]$entitytype,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$entity,
    
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [boolean]$instant
        
    #CN%3Dvi-admin%2CCN%3DUsers%2CDC%3Dlab%2CDC%3Dlocal
    

    )
  
    try{
      $r = (Invoke-RestMethod -WebSession $Login -Method Post -Uri "http://$server/cv_api/assignments?action_type=$AssignmentType&id=$AppID&assignments%5B0%5D%5Bentity_type%5D=$entitytype&assignments%5B0%5D%5Bpath%5D=$entity&rtime=($instant.toString())&mount_prefix=")
      if ($r.warning){$r = 'The entity needs to be in Directory Services format, Ex: CN=vi-admin,CN=users,DC=lab,DC=local'}
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            
            write-host 'An error occurred'
        }
    }
    return $r
}

function Connect-AppVolumes
{
  <#
  .DESCRIPTION
   This function is used to Connect to the AppVolumes server.

  .PARAMETER Server
    Specifies the server you wish to connect.  Can be FQDN or IP address.
  .PARAMETER username
    The user you wish to connect as.  If left blank you will be prompted for credentials.
  .PARAMETER password
    The password for the user you wish to connect as. If left blank you will be propmted for credentials.
  #>
    [CmdletBinding()]

    param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [String]$server,

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
            write-host 'An error occurred'
            
        }

    }
      Set-Variable -Name Login -value $login -Scope global
      Set-Variable -Name Server -value $server -Scope global
      
}
function Set-AppVolumesWritableVolumeEnabled
{
  <#
  .DESCRIPTION
   This function is used to enable a writable volume.

  .PARAMETER AppID
  This tells the API which writable volume you wish to modify. If you do not know the ID use Get-AppVolumesWritableVolumes
  
  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

  try{
      $r = (Invoke-WebRequest -WebSession $Login -Method Post -Uri "http://$server/cv_api/writables/disable?volumes%5B%5D=$AppID").content
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Set-AppVolumesWritableVolumeDisabled
{
  <#
  .DESCRIPTION
   This function is used to disable a writable volume.

  .PARAMETER AppID
   This tells the API which writable volume you wish to modify. If you do not know the ID use Get-AppVolumesWritableVolumes
  
  #>
  
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$AppID

    )

  try{
      $r = (Invoke-WebRequest -WebSession $Login -Method Post -Uri "http://$server/cv_api/writables/enable?volumes%5B%5D=$AppID").content
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error has occurred'
            
        }

    }
    return $r
  
}
function Get-AppVolumeCurrentAttachments
{
  <#
    .DESCRIPTION
   This function lists the curently attached appstacks and the entity they are attached to.

  .PARAMETER AppID
  This tells the API which writable volume you wish to modify. If you do not know the ID use Get-AppVolumes
  
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
            write-host 'An error occurred'
            
        }

    }

    #Create Table object
    $table = New-Object system.Data.DataTable 'System Messages'

    #Define Columns
    $col1 = New-Object system.Data.DataColumn Name,([string])
    $col2 = New-Object system.Data.DataColumn EntityType,([string])

    #Add the Columns
    $table.columns.add($col1)
    $table.columns.add($col2)

    foreach ($message in $r){
      

        #Create a row
        $row = $table.NewRow()

        #Enter data in the row
        $row.Name = $r.name.Substring($r.name.IndexOf('">')+2,($r.name.IndexOf('</')-$r.name.IndexOf('">')-2))
        $row.EntityType = $r.entity_type
        
        #Add the row to the table
        $table.Rows.Add($row)


        $i++


        }

    return $table

}
function Get-AppVolumeAssignments
{
  <#
  .DESCRIPTION
   This function lists the assignments of a specific appstack

  .PARAMETER AppID
  This tells the API which writable volume you wish to modify. If you do not know the ID use Get-AppVolumes
  
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
            write-host 'An error occurred'
            
        }

    }
    
    
    #Create Table object
    $table = New-Object system.Data.DataTable 'System Messages'

    #Define Columns
    $col1 = New-Object system.Data.DataColumn Name,([string])
    $col2 = New-Object system.Data.DataColumn EntityType,([string])

    #Add the Columns
    $table.columns.add($col1)
    $table.columns.add($col2)

    $i=0

    foreach ($message in $r){
      

        #Create a row
        $row = $table.NewRow()

        #Enter data in the row
        $row.Name = $r.name[$i].Substring($r.name[$i].IndexOf('">')+2,($r.name[$i].IndexOf('</')-$r.name[$i].IndexOf('">')-2))
        $row.EntityType = $r.entity_type[$i] 

        #Add the row to the table
        $table.Rows.Add($row)


        $i++


        }

    return $table
    
}
function Get-AppVolumes
{
  <#
  .DESCRIPTION
   This function is used list all appvolumes known by the AppVolumes manager.
   
  #>
    try{
      $results = (Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/appstacks").Content | ConvertFrom-Json
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
           
        }
    }
    return $results
}
function Get-AppVolumesLicense
{
  <#
  .DESCRIPTION
   This function lists all licensing information about the AppVolumes Manager


  #>
    try{
      $license = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/license").Content | ConvertFrom-Json).license
      $license_usage = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/license_usage").Content | ConvertFrom-Json).licenses
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
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
  .DESCRIPTION
   This function lists the Actve Directories that AppVolumes is connected to as well as the user associated with each domain.

  #>

   try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/ad_settings").Content | ConvertFrom-Json).config_ad
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }
    }
    
   
    return $r
      
}
function Get-AppVolumesCurrentAdminGroup
{
  <#
  .DESCRIPTION
   This function lists the current administrator group within the AppVolumes interface.
  #>
  
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/administrator").Content | ConvertFrom-Json).current_admin
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }
    }
    
    return $r
  
}
function Get-AppVolumesvCenterUser
{
  <#
  .DESCRIPTION
   This function lists the vCenter connection information that AppVolumes is using
  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/machine_managers").Content | ConvertFrom-Json).machine_managers
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }
    }
    
    return $r
}
function Get-AppVolumesDatastores
{
  <#
  .DESCRIPTION
   This function lists all datastores that AppVolumes knows about.
  #>
  

  try{
      $r = (Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/datastores").Content | ConvertFrom-Json
      
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r        
}
function Get-AppVolumeDetails
{
  <#  
  .DESCRIPTION
   If given a specific appstack, this function will list details about the specifed appstack

  .PARAMETER AppID
  This is the ID of the appstack you would like to know more about.  If you do not know the ID use Get-AppVolumes
  
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
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumeApps
{
  <#
  .DESCRIPTION
   If given a specific appstack, this function will list the apps that were captured in the specified appstack.

  .PARAMETER AppID
  This is the ID of the appstack you would like to know more about.  If you do not know the ID use Get-AppVolumes
  
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
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumeFileLocation
{
  <#
  .DESCRIPTION
   If given a specific appstack, this function will list the location of the appstack on the datastore

  .PARAMETER AppID
  This is the ID of the appstack you would like to know more about.  If you do not know the ID use Get-AppVolumes
  
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
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumesWritableVolumes
{
  <#
  .DESCRIPTION
   This function will list all writable volumes in the environment

  
  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/writables").Content | ConvertFrom-Json).datastores.writable_volumes
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Get-AppVolumesWritableVolumeDetails
{
  <#
  .DESCRIPTION
   If given a specific writable volume, this function will list details about the specifed writable volume

  .PARAMETER AppID
  This is the ID of the appstack you would like to know more about.  If you do not know the ID use Get-AppVolumesWritableVolumes
  
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
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumesAttachments
{
  <#
  .DESCRIPTION
   This function will list all current appstack attachments

  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/attachments").Content | ConvertFrom-Json).attachments
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumesCurrentAssignments
{
  <#
   .DESCRIPTION
   This function will list all current appstack assignments 

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/assignments").Content | ConvertFrom-Json).assignments
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Get-AppVolumesApps
{
  <#
   .DESCRIPTION
   This function will list all applications that have been captured by the AppVolumes Manager. You can use this function to find which appstack contains the specific app you are looking for.
 
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/applications").Content | ConvertFrom-Json).applications
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumesAppDetails
{
  <#
   .DESCRIPTION
   If given a specific application, this function will list details about the specifed application

  .PARAMETER AppID
  This is the ID of the appstack you would like to know more about.  If you do not know the ID use Get-AppVolumesApps
  
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
            write-host 'An error occurred'
            
        }

    }
    return $r

}
function Get-AppVolumesOnlineEntities
{
  <#
   .DESCRIPTION
   This function will list all AppVolumes agents that are currently online

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/online_entities").Content | ConvertFrom-Json).online.records
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesUsers
{
  <#
  .DESCRIPTION
   This function will list all users who have logged into a managed computer or have had a volume assigned to them

  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/users").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesAgents
{
  <#
   .DESCRIPTION
   This function will list all known AppVolumes agents
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/computers").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesGroups
{
  <#
   .DESCRIPTION
   This function will list all Groups that have been assigned an appstack
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/groups").Content | ConvertFrom-Json).groups
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesOUs
{
  <#
   .DESCRIPTION
   This function will list all OUs that have been assigned an appstack
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/org_units").Content | ConvertFrom-Json).org_units
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesMachines
{
  <#
  .DESCRIPTION
  This function will list all machines that have been assigned an appstack
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/machines").Content | ConvertFrom-Json).machines
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesStorage
{
  <#
  .DESCRIPTION
  This function will list all storage known by the AppVolumes Manager
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storages").Content | ConvertFrom-Json).storages
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r
}
function Get-AppVolumesStorageGroups
{
  <#
  .DESCRIPTION
  This function will list all storage groups in AppVolumes
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storage_groups").Content | ConvertFrom-Json).storage_groups
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }

    return $r

}
function Get-AppVolumesStorageGroupDetails
{
  <#
  .DESCRIPTION
  This function will provide details about a specific storage group

  .PARAMETER StorageGroupID
  The storage group you wish to know more about.  If you do not know the ID use Get-AppVolumesStorageGroups
  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageGroupID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/storage_groups/$StorageGroupID").Content | ConvertFrom-Json).storage_group
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Get-AppVolumesLog
{
  <#
  .DESCRIPTION
  This will return the log of the AppVolumes Manager
  #>

  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/activity_logs").Content | ConvertFrom-Json).actlogs.logs
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Get-AppVolumesSystemMessages
{
  <#
  .DESCRIPTION
  This function will list all AppVolumes Manager System Messages
  #>
  try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/system_messages").Content | ConvertFrom-Json).allmessages.system_messages
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
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
function Get-AppVolumesPendingActions
{
  <#
  .DESCRIPTION
  This function will list all pending actions
  #>

   try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Get -Uri "http://$server/cv_api/pending_activities").Content | ConvertFrom-Json).allactivities.pending_activities
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}
function Start-AppVolumesStorageReplication
{
  <#
  .DESCRIPTION
  This will replicate the appstacks to other datastores within a storage group as defined by the policy selected when the storage group was created in the UI.

  .PARAMETER StorageGroupID
  This is the ID of the storage group you wish to replicate. If you do not know the ID use the function Get-AppVolumesStorageGroups
  #>

  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageGroupID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Post -Uri "http://$server/cv_api/storage_groups/$StorageGroupID/replicate").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r
}

function Import-AppVolumestoStorageGroup
{
  <#
  .DESCRIPTION
  This function will import AppVolumes on an existing datastore into the specified storage group

  .PARAMETER StorageGroupID
  This is the ID of the storage group you wish to replicate. If you do not know the ID use the function Get-AppVolumesStorageGroups
  
  #>
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$StorageID

    )

    try{
      $r = ((Invoke-WebRequest -WebSession $Login -Method Post -Uri "http://$server/cv_api/appstacks/storage_groups/$StorageID/import").Content | ConvertFrom-Json)
            
    }
    catch
    {
        if ($_.Exception.Message -match '401')
        {   
            write-host 'An error occurred'
            
        }

    }
    return $r

}


