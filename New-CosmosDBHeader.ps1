function New-CosmosDBHeader {
    <#
    .SYNOPSIS
    Creates a Header for CosmosDB queries
    
    .DESCRIPTION
    Creates a token used for executing a specific operation on a CosmosDB
    
    .PARAMETER URI
    Parameter description
    
    .PARAMETER Verb
    Parameter description
    
    .PARAMETER resourceName
    Parameter description
    
    .PARAMETER resourceId
    Parameter description
    
    .PARAMETER resourceType
    Parameter description
    
    .PARAMETER Key
    Parameter description
    
    .PARAMETER KeyType
    Parameter description
    
    .PARAMETER APIVersion
    Parameter description
    
    .EXAMPLE
    An example
    
    .NOTES
    General notes
    #>
    [CmdletBinding(DefaultParameterSetName='Default')]
    param (
        [Parameter(Mandatory=$True,
        HelpMessage='https://<Your DB Name>.documents.azure.com')]
        [string]$URI,
        [Parameter(Mandatory=$True,
        HelpMessage='GET, POST, etc.')]
        [string]$Verb,
        [Parameter(ParameterSetName='Name',
        Mandatory=$True,
        HelpMessage="Contains the relative path of the resource, as derived using the URI format. E.g. 'dbs/MyDatabase/colls/MyCollection/docs/MyDocument'")]
        [string]$resourceName,
        [Parameter(ParameterSetName='Rid',
        Mandatory=$false,
        HelpMessage="Contains the relative path of the resource, as derived using the URI format. E.g. 'dbs/MyDatabase/colls/MyCollection/docs/MyDocument'")]
        [string]$resourceId,
        [Parameter(Mandatory=$true,
        HelpMessage="Identifies the type of resource that the request is for, Eg. 'dbs', 'colls', 'docs'")]
        [string]$resourceType,
        [Parameter(Mandatory=$True,
        HelpMessage="DocumentDB Account key")]
        [string]$Key,
        [ValidateSet('master','resource')]
        [string]$KeyType,
        [string]$tokenVersion
    )
    
    begin {

    }
    
    process {
        $UTCDate = [DateTime]::UtcNow.ToString("r")
        Write-Verbose "Date: $UTCDate"
        $keyBytes = [System.Convert]::FromBase64String($Key)
        $hmacSha256 = new-object -TypeName System.Security.Cryptography.HMACSHA256 -ArgumentList (,$keyBytes)
        [string]$Payload = "{0}`n{1}`n{2}`n{3}`n{4}`n" -f $Verb.ToLowerInvariant(),$resourceType.ToLowerInvariant(),$resourceId.ToLowerInvariant(),$UTCDate.ToLowerInvariant(),''
        Write-Verbose $Payload
        $hashPayLoad = $hmacSha256.ComputeHash([Text.Encoding]::UTF8.GetBytes($PayLoad.ToLowerInvariant()))
        $signature = [System.Convert]::ToBase64String($hashPayLoad)
        Write-Verbose "Signature: $Signature"
        [string]$authorizationFormat = 'type={0}&ver={1}&sig={2}' -f $keyType,$tokenVersion,$signature
        $header=@{
            "authorization" = [System.Web.HttpUtility]::UrlEncode($authorizationFormat)
            "x-ms-version" = "2015-12-16"
            "x-ms-date" = $UTCDate
            }
    }
    
    end {
        $header
    }
}