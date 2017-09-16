if(-not $PSScriptRoot)
{
    $PSScriptRoot = Split-Path $MyInvocation.MyCommand.Path -Parent
}

$Public  = Get-ChildItem $PSScriptRoot\*.ps1 -ErrorAction SilentlyContinue

 Foreach($import in @($Public))
{
    Try
    {
        #PS2 compatibility
        if($import.fullname)
        {
            . $import.fullname
        }
    }
    Catch
    {
        Write-Error "Failed to import function $($import.fullname): $_"
    }
}
    
Export-ModuleMember -Function $($Public | Select-Object -ExpandProperty BaseName)