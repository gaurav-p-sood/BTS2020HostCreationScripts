<# 
.SYNOPSIS 
    Will create all Hosts, Host Instances and Handlers for the adapters as defined in a provided config.xml file
    
.DESCRIPTION 
    Given a valid XML file with defined hosts, host instances and adapters, this script will create them all
    This will save users a lot of time as they wont have to manually create them all via the BizTalk 
    Admin console.
    There are switchs you can include to skip over parts of the scripts if desired.
.PARAMETER ConfigurationFile 
   the name of the config file to use. Contains info about hosts, host instancea and handlers to create  
.PARAMETER SkipHosts 
   If set, the Host creation section is skipped
.PARAMETER SkipHostInstances 
   If set, the Host Instance section creation is skipped
.PARAMETER SkipHostHandlers 
   If set, the Host Handler creation is skipped
     
.EXAMPLE 
    .\Add-HostInstanceHandlers.ps1 -ConfigFile .\ClientConfig.xml
    Will create all hosts, host instances and handlers as defined in ClientConfig.xml
    
    .\Add-HostInstanceHandlers.ps1 -ConfigFile .\ClientConfig.xml -SkipHosts -SkipHostInstances
    Will just create the handlers as defined in ClientConfig.xml
#> 

param (
    
   [ValidateScript({Test-Path -Path $_ -PathType Leaf})]
   [string] $configurationFile,# = "$pwd\HostConfig_2020.xml",
   
   [switch] $SkipHosts,
   
   [switch] $SkipHostInstances,
   
   [switch] $SkipHostHandlers,

   [string] $regionName
    )

# ensure the Biztalk module is there
if ((Test-Path -Path .\BiztalkScripts.psm1 -PathType Leaf) -eq $false)
{
    Write-Error "Unable to fine the BiztalkScripts.psm1 file. Check the folder and try again." -ErrorAction Stop
}
# import in the biztalk scripts needed (ignore the warnings)
Import-Module -Force -Name .\BizTalkScripts.psm1 -DisableNameChecking
cd\

Write-Host "Loading configuration file: $configurationFile" -f DarkCyan
# load the xml file
[xml]$xmldata = Get-Content $configurationFile


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

Write-Host "Creating Hosts and Host Instances..." -f DarkCyan
# go through all the host names
#hostType = 1 = inProcess, 2 = Isolated
foreach ($hn in $xmlRegionNode.Hosts.Host)
{
    if ($SkipHosts -eq $false)
    {
        Write-Host "Creating new Host: " -f DarkCyan -NoNewline; Write-Host $hn.HostName -f Cyan
        [int]$hostType = 1
        if ($hn.isolated -eq "true")
        {
            [int]$hostType = 2
        }
	    [bool]$trustBool = [Convert]::ToBoolean($hn.trusted)
	    [bool]$trackBool = [Convert]::ToBoolean($hn.tracking)
	    [bool]$is32BitBool = [Convert]::ToBoolean($hn.Is32Bit)
        $output = Create-Bts-Host $hn.HostName $hostType "$($hn.NtGroupName)" $trustBool $trackBool $is32BitBool 
	}
    else
    {
        Write-Host "Skipping creation of Hosts." -f Yellow
    }

    if ($SkipHostInstances -eq $false)
    {
	    foreach ($hi in $xmlRegionNode.HostInstances.HostInstance)
        {
            if($hn.HostName -eq $hi.host)
	        {
                Write-Host "Creating instance of $($hi.Host) on server $($hi.Server)" -f DarkCyan
		        #$output = Create-Bts-Instance $hn.HostName "$($hi.account)" $hi.password $hi.Server
                switch ($hi.Type)
                {
                    R {
                            foreach ($sv in $xmlRegionNode.Servers.Receive.Server)
                            {
                                $output = Create-Bts-Instance $hi.Host "$($hi.Login)" $hi.Password $sv
                            }
                      }
                    S {
                            foreach ($sv in $xmlRegionNode.Servers.Send.Server)
                            {
                                $output = Create-Bts-Instance $hi.Host "$($hi.Login)" $hi.Password $sv
                            }
                      }
                    P {
                           foreach ($sv in $xmlRegionNode.Servers.Process.Server)
                            {
                                $output = Create-Bts-Instance $hi.Host "$($hi.Login)" $hi.Password $sv
                            }
                      }
                    default {$output = "Unknown HostType"}


                }
            
	        }
        }
    }
    else
    {
        Write-Host "Skipping creation of Host Instances." -f Yellow
    }
    
	# for each of the adapters
    if (($SkipHostHandlers -eq $false))#-and ($hn.tracking -eq "false"))
    {
        Write-Host "Creating Handlers for host $($hn.HostName)..." -f DarkCyan
	    foreach ($ad in $xmlRegionNode.Handlers.Handler)
	    {
		    if ($hn.isolated -eq "false")
		    {
                if($hn.HostName -eq $ad.HostName)
                {

			        if ($ad.Type -eq "Send")
			        {
				        $output = Create-Bts-SendHandler $ad.Adapter $hn.HostName
			        }
			        if ($ad.Type -eq "Receive")
			        {
				        $output = Create-Bts-ReceiveHandler $ad.Adapter $hn.HostName
			        }
                }
		    }
		    else
		    {
                if( ($hn.HostName -eq $ad.HostName) -and ($hn.tracking -eq "false"))
                {
			        if ($hn.isolated -eq "true")
			        {
				        $output = Create-Bts-ReceiveHandler $ad.Adapter $hn.HostName
			        }
                }
		    }
	    }
    }
    else
    {
        Write-Host "Skipping creation of Hosts Handlers." -f Yellow
    }
}
Write-Host "All done!" -f DarkCyan