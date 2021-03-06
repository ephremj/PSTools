<#
.Synopsis
   Enumerates SRV records of a Domain Controller
.DESCRIPTION
   Enumerates SRV records of a Domain Controller from domain, forest and AD site zones. 
   Requires the neccessary elevated permission to delete  SRV DNS records.  
.EXAMPLE
   Get-DomainControllerSRVRecords -dcName "dc-01.corp.contoso.local" 
   Get-DomainControllerSRVRecords -dcName "dc-01.corp" 
.EXAMPLE
   Get-DomainControllerSRVRecords -dcName "testdc01.testdomain.local" -forestFQDN "testdomain.local" -domainFQDN "testdomain.local"
.Notes
   Auther:  Ephrem J. Woldesemaite
   Version: 0.0.1
#>
function Get-DomainControllerSRVRecords
{    
    [CmdletBinding()]
    Param
    (
        # dcName domain controller's name
        [Parameter(Mandatory = $true)]                        
        [System.String]$dcName,

        # forestFQDN domain controller's forest               
        [System.String]$forestFQDN = (Get-ADDomain -Server $dcName).forest,

        # domainFQDN domain controller's domain                
        [System.String]$domainFQDN = (Get-ADDomain -Server $dcName).DNSRoot
    )

    Begin
    {
       if ($dcName -notcontains $doaminFQDN) {$dcName = $dcname + "." + $domainFQDN}
        Write-Host "Listing SRV records of domain controller: $dcNAme"
        Write-Host "It could take longer if the domain controller has been responsible to autosite cover  large number AD sites."
        # Intialize forest and domain possible zones where the domain controller registger its SRV records
        $zonesToCheck = @()
        $zonesToCheck += "_gc._tcp." + $forestFQDN + "."
        $zonesToCheck += "_kerberos._tcp.dc._msdcs." + $domainFQDN + "."
        $zonesToCheck += "_kerberos._tcp." + $domainFQDN + "."
        $zonesToCheck += "_kerberos._udp." + $domainFQDN + "."
        $zonesToCheck += "_kpasswd._tcp." + $domainFQDN + "."
        $zonesToCheck += "_kpasswd._udp." + $domainFQDN + "."
        $zonesToCheck += "_ldap._tcp.dc._msdcs." + $domainFQDN + "."
        $zonesToCheck += "_ldap._tcp.DomainDnsZones." + $domainFQDN + "."
        $zonesToCheck += "_ldap._tcp.ForestDnsZones." + $forestFQDN + "."
        $zonesToCheck += "_ldap._tcp.gc._msdcs." + $forestFQDN + "."
        $zonesToCheck += "_ldap._tcp." + $domainFQDN + "."
        
    }
    Process
    {        
        try
        {
            # Add AD site based possible zones that the domain controller could have registred its SRV records 
            #$sites = (Get-ADReplicationSite -filter * -Server $forestFQDN).Name             
            $sites = nltest /DSGETSITECOV /server:$dcName                            
            foreach ($site in $sites)
            {
                $zonesToCheck += "_kerberos._tcp." + $site + "._sites.dc._msdcs." + $domainFQDN + "."
                $zonesToCheck += "_kerberos._tcp." + $site + "._sites." + $domainFQDN + "."
                $zonesToCheck += "_ldap._tcp." + $site + "._sites.dc._msdcs." + $domainFQDN + "."
                $zonesToCheck += "_ldap._tcp." + $site + "._sites.DomainDnsZones." + $domainFQDN + "."
                $zonesToCheck += "_ldap._tcp." + $site + "._sites.ForestDnsZones." + $forestFQDN + "."
                $zonesToCheck += "_ldap._tcp." + $site + "._sites.gc._msdcs." + $forestFQDN + "."
                $zonesToCheck += "_ldap._tcp." + $site + "._sites." + $domainFQDN + "."
                $zonesToCheck += "_gc._tcp." + $site + "._sites." + $forestFQDN + "."
            }            
        }
        catch 
        {
            Write-Host "No sites discovered to remove SRV records from AD site based zones" -ForegroundColor Yellow
        }        

        try 
        {
            foreach ($zone in $zonesToCheck)
            {
                $srvRecordsinInZone = $null
                $srvRecordsinInZone = (Resolve-DnsName -Type SRV -Name $zone -Server $dcName -ErrorAction SilentlyContinue).Name 
                if ($null -ne $srvRecordsinInZone)
                {
                    if ($dcName -in $srvRecordsinInZone)
                    {
                        Write-Host "SRV records of $dcName found in $zone ...." -ForegroundColor Green                        
                    }
                }
            }  
        }
        catch 
        {
            Write-Host "Remove has failed " $_
        }
    } 
    End
    {
    }
}
