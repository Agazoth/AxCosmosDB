function Get-CosmosDBDocument {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
        HelpMessage="The name of your Database. E.g. 'MyDatabase'")]
        [string]$DatabaseName,
        [Parameter(Mandatory=$True,
        HelpMessage="The name of your collection. E.g. 'MyCollection'")]
        [string]$CollectionName,
        [Parameter(Mandatory=$True,
        HelpMessage='https://<Your DB Name>.documents.azure.com')]
        [string]$URI,
        [Parameter(Mandatory=$True,
        HelpMessage="DocumentDB Account key")]
        [string]$Key,
        [ValidateSet('master','resource')]
        [string]$KeyType,
        [string]$tokenVersion
    )
    
    begin {
        if (-not $Global:CosmosDBConnection) {
            Write-Warning "CosmosDB connection not found. Connecting to $URL"
            Connect-CosmosDB -URI $URI -Key $Key -Refresh
        }
    }
    
    process {
        $Database = $Global:CosmosDBConnection[$DatabaseName]
        if ($Database) {
            Write-Verbose "Found $DatabaseName"
        } else {
            Write-Warning "Database: $DatabaseName not found"
            continue
        }
        if ($CollectionName){
            $Collection = $Database[$CollectionName]
            if ($Collection) {
                Write-Verbose "Found $CollectionName"
            } else {
                Write-Warning "Collection: $CollectonName not found"
                continue
            }
        }
        $Verb = 'Get'
        $Url = '{0}/{1}docs' -f $URI,$Collection._self
        Write-Verbose $Url
        $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType docs -Verb $Verb
        $Result = Invoke-RestMethod -Uri $Url -Headers $Header -Method $Verb -ContentType "application/json" 
    }
    
    end {
        $Result.Documents
    }
}