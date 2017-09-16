function Invoke-CosmosDBRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
        HelpMessage='https://<Your DB Name>.documents.azure.com')]
        [string]$URI,
        [Parameter(Mandatory=$True,
        HelpMessage='GET, POST, etc.')]
        [string]$Verb,
        [Parameter(Mandatory=$True,
        HelpMessage="The name of your Database. E.g. 'MyDatabase'")]
        [string]$DatabaseName,
        [Parameter(ParameterSetName='docs',
        Mandatory=$True,
        HelpMessage="The name of your collection. E.g. 'MyCollection'")]
        [string]$CollectionName,
        [Parameter(ParameterSetName='Rid',
        Mandatory=$false,
        HelpMessage="Contains the relative path of the resource, as derived using the URI format. E.g. 'dbs/MyDatabase/colls/MyCollection/docs/MyDocument'")]
        [string]$resourceId,
        [Parameter(Mandatory=$true,
        HelpMessage="Identifies the type of resource that the request is for, Eg. 'dbs', 'colls', 'docs'")]
        [string]$resourceType,
        [Parameter(Mandatory=$false,
        HelpMessage='Hashed document content, Eg @{"id"="123";"Name"="Name";"Description"="Description"}')]
        $Body,
        [Parameter(Mandatory=$True,
        HelpMessage="DocumentDB Account key")]
        [string]$Key,
        [ValidateSet('master','resource')]
        [string]$KeyType,
        [string]$tokenVersion
    )
    
    begin {
        if (-not $Global:CosmosDBConnection) {
            Write-Verbose "CosmosDB connection not found. Connecting to $URL"
            $Global:CosmosDBConnection=@{}
            Connect-CosmosDB -URI $URI -Key $Key -Refresh
        }
        if (-not $resourceId) {
            $resourceId = ''
        }
        if ($Body) {
            try {
                $Body = $Body | ConvertTo-Json -ErrorAction Stop
            }
            catch {
                Write-Warning -Message $_.Exception.Message
                continue
            }
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
        if ($resourceType -eq 'docs') {
            $Url = '{0}/{1}/docs' -f $URI,$Collection._self
        }
        $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $resourceType -Verb $Verb 
        Invoke-RestMethod -Uri $Url -Headers $Header -Method $Verb -ContentType "application/json" -Body $Body
    }
    
    end {
    }
}