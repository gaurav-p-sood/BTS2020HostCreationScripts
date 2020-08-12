<# 
.SYNOPSIS 
    Will remove all Hosts, Host Instances and Handlers for the adapters as defined in a provided config.xml file
    
.DESCRIPTION 
    Given a valid XML file with defined hosts, host instances and adapters, this script will remove them all
    This will save users a lot of time as they wont have to manually remove them all via the BizTalk 
    Admin console.
.PARAMETER ConfigurationFile 
   the name of the config file to use. Contains info about hosts, host instancea and handlers to create  
     
.EXAMPLE 
    .\Remove-HostInstanceHandlers.ps1 -ConfigFile .\ClientConfig.xml
    Will create all hosts, host instances and handlers as defined in ClientConfig.xml
#> 
param (
    
   [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
   [string] $configurationFile,# = "$pwd\HostConfig_2020.xml",
   
   [string] $regionName
    )

if ((Test-Path -Path .\BiztalkScripts.psm1 -PathType Leaf) -eq $false)
{
    Write-Error "Unable to fine the BiztalkScripts.psm1 file. Check the folder and try again." -ErrorAction Stop
}
# import in the biztalk scripts needed (ignore the warnings)
Import-Module -Force -Name .\BizTalkScripts.psm1 -DisableNameChecking

# load the xml file
[xml] $xmldata = get-content $configurationFile

#reading region specific xml node.
if($regionName -eq "DEV")
{
    [System.Xml.XmlNode] $xmlRegionNode= $xmldata.SelectSingleNode('//Region[@Name="DEV"]')
}
if($regionName -eq "TEST")
{
    [System.Xml.XmlNode] $xmlRegionNode= $xmldata.SelectSingleNode('//Region[@Name="TEST"]')
}
if($regionName -eq "PROD")
{
    [System.Xml.XmlNode] $xmlRegionNode= $xmldata.SelectSingleNode('//Region[@Name="PROD"]')
}

# go through all the host names
foreach ($hn in $xmlRegionNode.Hosts.Host)
{
    # for each of the adapters
    foreach ($ad in $xmlRegionNode.Handlers.Handler)
    {
            if ($hn.isolated -eq "false")
            {		
                if($hn.HostName -eq $ad.HostName)
                {

			        if ($ad.Type -eq "Send")
			        {
                        Delete-Bts-Send-Handler $ad.Adapter $hn.HostName
                    }
			        if ($ad.Type -eq "Receive")
			        {
                        Delete-Bts-Receive-Handler $ad.Adapter $hn.HostName
                    }
                }
            }
            else
            {
                if( ($hn.HostName -eq $ad.HostName) -and ($hn.tracking -eq "false"))
                {
                    if ($hn.isolated -eq "true")
                    {
                        Delete-Bts-Receive-Handler $ad.Adapter $hn.HostName
                    }
                }
            }
        }
        
    # for each host instance
    foreach ($hi in $xmlRegionNode.HostInstances.HostInstance)
    {
        if($hn.HostName -eq $hi.host)
	    {
            Write-Host "Stopping and then deleting instance of $($hi.Host) on server $($hi.Server)" -f DarkCyan
            switch ($hi.Type)
            {
                    R {
                            foreach ($sv in $xmlRegionNode.Servers.Receive.Server)
                            {
                                $output = Stop-Bts-HostInstance $hi.Host $sv
                                $output = Delete-Bts-Instance $hi.Host $sv
                            }
                      }
                    S {
                            foreach ($sv in $xmlRegionNode.Servers.Send.Server)
                            {
                                $output = Stop-Bts-HostInstance $hi.Host $sv
                                $output = Delete-Bts-Instance $hi.Host $sv
                            }
                      }
                    P {
                           foreach ($sv in $xmlRegionNode.Servers.Process.Server)
                            {
                                $output = Stop-Bts-HostInstance $hi.Host $sv
                                $output = Delete-Bts-Instance $hi.Host $sv
                            }
                      }
                    default {$output = "Unknown HostType"}
                    
                }
        }
    }

    #for each host

    #$output = Delete-Bts-Host $hn.HostName

}
