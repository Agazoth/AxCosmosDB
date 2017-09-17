function Invoke-CosmosDBCommand {
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory=$false,
            HelpMessage="The name of your Database. E.g. 'MyDatabase'")]
            [Parameter(ParameterSetName="NewCollection",Mandatory=$true)]
            [Parameter(ParameterSetName="ListCollections",Mandatory=$true)]
            [Parameter(ParameterSetName="NewDatabase",Mandatory=$False)]
            [string]$DatabaseName,

        [Parameter(ParameterSetName="NewDatabase",
            HelpMessage='Name of your new database')]
            [string]$NewDatabase,

         [Parameter(ParameterSetName="ListDatabases",
            HelpMessage='List all databases in your CosmosDB')]
            [switch]$ListDatabases,

        [Parameter(ParameterSetName="GetDatabase",
            HelpMessage='Get a databases in your CosmosDB')]
            [string]$GetDatabase,

        [Parameter(ParameterSetName="DeleteDatabase",
            HelpMessage='Get a databases in your CosmosDB')]
            [string]$DeleteDatabase,

        [Parameter(ParameterSetName="NewCollection",
            HelpMessage='Create a new Collection in a CosmosDB Database')]
            [string]$NewCollection,
        
        [Parameter(ParameterSetName="ListCollections",
            HelpMessage='List all Collections in a CosmosDB Database')]
            [switch]$ListCollections,

       [Parameter(Mandatory=$False,
            HelpMessage="The name of your collection. E.g. 'MyCollection'")]
            [Parameter(ParameterSetName='NewDocument',
            Mandatory=$true)]
            [Parameter(ParameterSetName='ListDocuments',
            Mandatory=$True)]
            [Parameter(ParameterSetName='GetDocument',
            Mandatory=$True)]
            [string]$CollectionName,

        [Parameter(ParameterSetName='NewDocument',
            Mandatory=$True,
            HelpMessage="A hash table containing your Document E.g. @{id=123;Name='MyNewEntry'")]
            [Hashtable]$NewDocument,

        [Parameter(ParameterSetName='ListDocuments',
            Mandatory=$True)]
            [Switch]$ListDocuments,

        [Parameter(ParameterSetName='GetDocument',
            Mandatory=$True,
            HelpMessage="Gets a specific document by id E.g. MyDocument")]
            [String]$GetDocument,

        [Parameter(ParameterSetName='Query',
            Mandatory=$True,
            HelpMessage="Any SQL query E.g. 'SELECT * FROM root'")]
            [String]$Query,

        [Parameter(ParameterSetName='Query',
            Mandatory=$false,
            HelpMessage="A hashtable containing parameters for your query")]
            [Hashtable]$Parameter,

        [Parameter(Mandatory=$false,
            HelpMessage='GET, POST, etc.')]
            $Verb = 'POST',

        [Parameter(Mandatory=$false,
            HelpMessage='dbs, colls, docs, etc.')]
            $ResourceType = 'docs',

        [Parameter(Mandatory=$True,
            HelpMessage='https://<Your DB Name>.documents.azure.com')]
            [string]$URI,

        [Parameter(Mandatory=$True,
            HelpMessage="DocumentDB Account key")]
            [string]$Key,

        [ValidateSet('master','resource')]
            [string]$KeyType,

            [string]$tokenVersion,

            [HashTable]$CosmosDBConnection,

            [switch]$UpdateCosmosDBConnection
    )
    
    begin {
        if (-not $CosmosDBConnection) {
            Write-Warning "CosmosDB connection not found. Connecting to $URL"
            Connect-CosmosDB -URI $URI -Key $Key
        }
    }
    
    process {
        Write-Verbose "Current ParameterSet: $($PSCmdlet.ParameterSetName)"
        if ($DatabaseName){
            $Database = $CosmosDBConnection[($DatabaseName + '_db')]
            if (-not $Database -and $PSCmdlet.ParameterSetName -ne 'NewDatabase'){
                Write-Warning "Database $DatabaseName not found"
                continue
            }
            if ($CollectionName) {
                $Collection = $CosmosDBConnection[$DatabaseName][$CollectionName]
                if (-not $Collection) {
                    Write-Warning "Collection $CollectionName not found in Database $DatabaseName"
                    continue
                }
            }
        }
        $Url = '{0}/{1}docs' -f $URI,$Collection._self
        if ($PSCmdlet.ParameterSetName -eq 'NewDatabase') {
            $Verb = 'POST'
            $Url = '{0}/{1}' -f $URI,'dbs'
            $ResourceType = 'dbs'
            $Header = New-CosmosDBHeader -resourceType $ResourceType -Verb $Verb
            $Body = @{id=$NewDatabase} | ConvertTo-Json
            $UpdateCosmosDBConnection=$True
        }
        if ($PSCmdlet.ParameterSetName -eq 'ListDatabases') {
            $Verb = 'GET'
            $Url = '{0}/{1}' -f $URI,'dbs'
            $ResourceType = 'dbs'
            $Header = New-CosmosDBHeader -resourceType $ResourceType -Verb $Verb
        }
        if ($PSCmdlet.ParameterSetName -eq 'GetDatabase') {
            $CosmosDBConnection[$($GetDatabase + '_db')]
            continue
        }
        if ($PSCmdlet.ParameterSetName -eq 'DeleteDatabase') {
            $Verb = 'DELETE'
            $Url = '{0}/{1}' -f $URI,$DB._self
            $ResourceType = 'dbs'
            $Header = New-CosmosDBHeader -resourceId $DB._rid -resourceType $ResourceType -Verb $Verb
            $UpdateCosmosDBConnection = $True
        }
        if ($PSCmdlet.ParameterSetName -eq 'NewCollection') {
            $Verb = 'POST'
            $Url = '{0}/{1}/colls' -f $URI,$Database._self
            $ResourceType = 'colls'
            $Header = New-CosmosDBHeader -resourceId $Database._rid -resourceType $ResourceType -Verb $Verb
            $Body = @{id=$NewCollection} | ConvertTo-Json
            $UpdateCosmosDBConnection = $True
        }
        if ($PSCmdlet.ParameterSetName -eq 'ListCollections') {
            $Verb = 'GET'
            $Url = '{0}/{1}/colls' -f $URI,$Database._self
            $ResourceType = 'colls'
            $Header = New-CosmosDBHeader -resourceId $Database._rid -resourceType $ResourceType -Verb $Verb
        }
        if ($PSCmdlet.ParameterSetName -eq 'Query') {
            $Verb = 'POST'
            $ResourceType = 'docs'
            $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $ResourceType -Verb $Verb
            $Header["x-ms-documentdb-isquery"] = 'true'
            $Header["Content-Type"] = "application/query+json"
            $BodyHash = @{
                'query' = $Query
            }
            if ($Parameter) {
                $BodyHash['parameter'] = $Parameter
            }
            $Body = $BodyHash | ConvertTo-Json
        }
        if ($PSCmdlet.ParameterSetName -eq 'NewDocument') {
            $Verb = 'POST'
            $ResourceType = 'docs'
            $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $ResourceType -Verb $Verb
            $Body = $NewDocument | ConvertTo-Json
        }
        if ($PSCmdlet.ParameterSetName -eq 'ListDocuments') {
            $Verb = 'GET'
            $ResourceType = 'docs'
            $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $ResourceType -Verb $Verb
        }
        if ($PSCmdlet.ParameterSetName -eq 'GetDocument') {
            <#$Verb = 'POST'
            $ResourceType = 'docs'
            $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $ResourceType -Verb $Verb
            $Header["x-ms-documentdb-isquery"] = 'true'
            $Header["Content-Type"] = "application/query+json"
            $BodyHash = @{
                'query' = "Select * from $CollectionName c where c.id = @id"
                'parameters' = [ordered]@{
                    name = '@id'
                    value = $GetDocument
                }
            }
            $Body = $BodyHash | ConvertTo-Json #>
            $Verb = 'GET'
            $ResourceType = 'docs'
            $Header = New-CosmosDBHeader -resourceId $Collection._rid -resourceType $ResourceType -Verb $Verb
            $Url += ('/{0}' -f $GetDocument)

        }
        Write-Verbose "Url: $Url"
        Write-Verbose $($Header | ConvertTo-Json)
        if ($Body) {
            Write-Verbose $Body
        }
        $Global:Return = $Null
        try {
            $Global:Return = Invoke-RestMethod -Uri $Url -Headers $Header -Method $Verb -Body $Body -ErrorAction Stop
        }
        catch {
            Write-Warning -Message $_.Exception.Message
        }
        
    }
    end {
        if ($UpdateCosmosDBConnection){
            Connect-CosmosDB -URI $URI -Key $Key
        }
        if ($Return){
            $PayloadType = $Return | Get-Member | Where-Object {$_.MemberType -eq 'NoteProperty' -and $_.Name -notmatch '^_'} | Select-Object -First 1 -ExpandProperty Name            
            Write-Verbose "Got $($Return._count) $PayloadType"
            $Return.$PayloadType
        }
    }
}