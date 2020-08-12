# BTS2020HostScripts
Contains Host Creation Script for BTS 2020 

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

Special thanks to @sandroasp and @mattcorr , I used their code and bring up this scrips 
