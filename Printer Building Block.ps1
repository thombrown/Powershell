Param(
   [parameter(Mandatory=$false)]
   [string]$PrintServer,
   [parameter(Mandatory=$false)]
   [string]$OutputFile = "$env:temp\RESBuildingBlock.xml"
)


$Now = Get-Date –f yyyyMMddHHmmss
if ((test-path $outputfile) -eq $true) {Remove-Item $outputfile}
$XmlWriter = New-Object System.XMl.XmlTextWriter($OutputFile,$Null)
$xmlWriter.Formatting = 'Indented'
$xmlWriter.Indentation = 1
$XmlWriter.IndentChar = "`t"
$xmlWriter.WriteStartDocument()
$XmlWriter.WriteComment('RES ONE Workspace Building Block')
$XmlWriter.WriteComment('Created by Powershell on ' + $Now)
$xmlWriter.WriteStartElement('respowerfuse')
    $guidgen =  [System.GUID]::NewGuid().ToString().ToUpper()
    $guid = "{$guidgen}"
    $XmlWriter.WriteElementString('version', '9.10.1.5')
    $xmlWriter.WriteStartElement('buildingblock')
        $xmlWriter.WriteStartElement('powerlaunch')

if ($PrintServer -eq $Null){$PrintServer = "localhost"}

$printers = Get-Printer -ComputerName $PrintServer

ForEach ($printer in $printers){

            $xmlWriter.WriteStartElement('printermapping')
            $printerpath = "\\"+$PrintServer+"\"+$printer.Name
            $xmlWriter.WriteElementString('printer',$printerpath)
            $xmlWriter.WriteElementString('backupprinter','')
            $xmlWriter.WriteElementString('default','no')
            $xmlWriter.WriteElementString('fastconnect','no')
            $xmlWriter.WriteElementString('failover','no')
            $xmlWriter.WriteElementString('printerpreference','default')
            $xmlWriter.WriteElementString('waitfortask','no')
            $xmlWriter.WriteElementString('description','')
            $xmlWriter.WriteElementString('driver',$printer.DriverName)
            $xmlWriter.WriteElementString('location','')
            $xmlWriter.WriteElementString('state','both')
            $xmlWriter.WriteStartElement('accesscontrol')
                $XmlWriter.WriteAttributeString('access_mode', "or")
                    $XmlWriter.WriteAttributeString('zone_mode', "or")
                    $xmlWriter.WriteStartElement('access')
                        $XmlWriter.WriteElementString('type', 'global')
                    $xmlWriter.WriteEndElement()
            $xmlWriter.WriteEndElement()


            $guidgen =  [System.GUID]::NewGuid().ToString().ToUpper()
            $guid = "{$guidgen}"
            $xmlWriter.WriteElementString('guid',$guid)
            $xmlWriter.WriteElementString('enabled','no')
            $xmlWriter.WriteEndElement()
}


        $xmlWriter.WriteEndElement()        
$xmlWriter.WriteEndElement() 
$xmlWriter.WriteEndElement() 
$xmlWriter.WriteEndDocument()
$xmlWriter.Flush()
$xmlWriter.Close()
