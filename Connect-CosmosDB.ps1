function Connect-CosmosDB {
    <#
    .SYNOPSIS
    Connects to a CosmosDB
    
    .DESCRIPTION
    Connects and sets a script wide connection variable hashtable that is used by the other functins in this module
    Follow the instructions here to create a CosmosDB (or do some fancy Azure Powershell stuff :-)):
    https://docs.microsoft.com/en-us/azure/cosmos-db/create-documentdb-dotnet
    
    .PARAMETER URI
    Something like: https://<Your DB Name>.documents.azure.com
    
    .PARAMETER Key
    The (primary) key, a guid formattede like: 9bc7fb04-2992-4033-844f-139eb9c2fe93, for your CosmosDB
    
    .PARAMETER KeyType
    master or resource - depending on your setup
    
    .PARAMETER tokenVersion
    1.0 - until further notice from Microsoft
    
    .EXAMPLE
    Connect-CosmosDB -URI https://MyPrivateCosmosDB.documents.azure.com -Key 9bc7fb04-2992-4033-844f-139eb9c2fe93

    You do not need to set the variables KeyType if you use the masterkey. Likewise with tokenVersion
    
    .NOTES
    This cmdlet should be run before you run the other cmdlets in this module, and every time you need to access a new database account (URI).
    #>
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
        [string]$tokenVersion = '1.0'
    )
    
    begin {
        $URI = $URI.Trim().TrimEnd('/')
        #Setup CosmosDBVariables
        $PSParameters = 'Key','URI','KeyType','tokenVersion'
        $Script:CosmosDBVariables = @{}
        foreach ($ParameterName in $PSParameters) {
            $Value = Get-Variable $ParameterName | Select-Object -expand value
            Write-Verbose "Setting $ParameterName to $Value in CosmosDBVariables"
            $Script:CosmosDBVariables[$ParameterName] = $Value
        }
        $Header = New-CosmosDBHeader -Verb GET -resourceType dbs
        $dbsUri = '{0}/dbs' -f $URI
        try {
            $Databases = Invoke-RestMethod -Uri $dbsUri -Headers $Header -Method GET -ContentType "application/json"
        }
        catch {
            Write-Warning -Message $_.Exception.Message
            continue
        }
    }
    
    process {
        $script:CosmosDBConnection=@{}
        foreach ($Database in $Databases.Databases) {
            Write-Verbose "Adding Database $($Database.id) to CosmosDBConnection"
            $script:CosmosDBConnection[$($Database.id + '_db')] = $Database
            # Get all Collections
            $CollsUri = '{0}/{1}/colls' -f $URI,$Database._self
            $header = New-CosmosDBHeader -resourceId $Database._rid -resourceType colls -Verb get
            $Collections = Invoke-RestMethod -Uri $CollsUri -Headers $Header -Method get -ContentType "application/json"
            $CollHash = @{}
            foreach ($Collection in $Collections.DocumentCollections) {
                Write-Verbose "Adding Collection $($Collection.id) to CosmosDBConnection"
                $CollHash[$Collection.id] = $Collection
            }
            $script:CosmosDBConnection[$Database.id] = $CollHash
        }
    }

    end {
    }
}