function Connect-CosmosDB {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
        HelpMessage='https://<Your DB Name>.documents.azure.com')]
        [string]$URI,
        [Parameter(Mandatory=$True,
        HelpMessage="DocumentDB Account key")]
        [string]$Key,
        [ValidateSet('master','resource')]
        [string]$KeyType = 'master',
        [string]$tokenVersion = '1.0',
        [switch]$Refresh
    )
    
    begin {
        $URI = $URI.Trim().TrimEnd('/')
        if ($Global:CosmosDBConnection -and !$Refresh){
            Write-Warning "You are already connected to SOMETHING. Use the -Refresh switch to update connection"
            continue
        }
        if ($Refresh){$Global:CosmosDBConnection=@{}}
        $Header = New-CosmosDBHeader -URI $URI -Verb GET -resourceType dbs -Key $Key
        $dbsUri = $URI,'dbs' -join '/'
        $Databases = Invoke-RestMethod -Uri $dbsUri -Headers $Header -Method GET -ContentType "application/json"
        # Set default variables on AxCosmosDB cmdlets
        $Cmdlets = 'New-CosmosDBHeader','Invoke-CosmosDBRequest','New-CosmosDBDocument','Get-CosmosDBDocument'
        $PSParameters = 'Key','URI','KeyType','tokenVersion'
        Foreach ($Cmdlet in $Cmdlets)
        {
            foreach ($ParameterName in $PSParameters)
            {
                $Value = Get-Variable $ParameterName | Select-Object -expand value
                Write-Verbose "Setting $ParameterName to $Value on $Cmdlet"
                $Global:PSDefaultParameterValues["$Cmdlet : $ParameterName"] = $Value
            }
        }
    }
    
    process {
        foreach ($Database in $Databases.Databases) {
            # Get all Collections
            $CollsUri = '{0}/{1}/colls' -f $URI,$Database._self
            $header = New-CosmosDBHeader -resourceId $Database._rid -resourceType colls -Verb get
            $Collections = Invoke-RestMethod -Uri $CollsUri -Headers $Header -Method get -ContentType "application/json"
            $CollHash = @{}
            foreach ($Collection in $Collections.DocumentCollections) {
                $CollHash[$Collection.id] = $Collection
            }
            $Global:CosmosDBConnection[$Database.id] = $CollHash
        }
    }

    end {
    }
}