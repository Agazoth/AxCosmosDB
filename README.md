# AxCosmosDB

This module lets you create, modify and delete CosmosDB databases, Collections and Documents. I created this module, because I'm a stubborn old geezer. I wanted to prove, that Powershell can reach and manipulate the Cosmos without wrapping C#.

The trick was to find a way to substitute the huma readable Id with the inhuman _rid, when building the url and authorization string. The intriguing thing is, that the documentation clearly states, that you should use the human readable id NOT the _rid, but all the examples clearly use the _rid.

![alt NOT the _rid](https://github.com/Agazoth/AxCosmosDB/blob/master/NotTheRid.PNG)

![alt But the link says otherwise](https://github.com/Agazoth/AxCosmosDB/blob/master/OrMaybeAnyway.PNG)

Functionality:
Create a CosmosDB, note the URI and the Key and you are good to go.

Converts any hashtable to a JSON document and stores it in a Collection.

#Instructions

```powershell
# One time setup
    # Download the repository
    # Unblock the zip
    # Extract the AxCosmosDB folder to a module path (e.g. $env:USERPROFILE\Documents\WindowsPowerShell\Modules\)

    #Simple alternative, if you have PowerShell 5, or the PowerShellGet module:
        Install-Module AxCosmosDB

# Import the module.
    Import-Module AxCosmosDB 

# Get commands in the module
    Get-Command -Module AxCosmosDB

# Get help for a command
    Get-Help New-CosmosDocument -Full



```

# Caveats
There is some kind of bug in the New-CosmosDocumentQuery. Only a general query returns anything. If additional parameters are added, nothing is returned.