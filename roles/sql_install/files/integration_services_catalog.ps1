# Requires -Modules SqlServer
#template to manage the SQL Server Integration Services Catalog (SSISDB)

function Get-SsisCatalog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstanceName
    )

    try {
        $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $InstanceName
        $db_count = ($srv.Databases | Where-Object { $_.Name -eq "SSISDB" }).Count
        $is_installed = if ($db_count -gt 0) { $true } else { $false }

        return @{
            Installed = $is_installed
        }
    }
    catch {
        Write-Error "Error getting SSIS Catalog status: $_"
        throw
    }
}

function Test-SsisCatalog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstanceName
    )

    try {
        $srv = New-Object Microsoft.SQLServer.Management.SMO.Server $InstanceName
        $db_count = ($srv.Databases | Where-Object { $_.Name -eq "SSISDB" }).Count

        if ($db_count -gt 0) {
            Write-Verbose "Integration Services Catalog 'SSISDB' already exists on instance '$InstanceName'."
            return $true
        }
        else {
            Write-Verbose "Integration Services Catalog 'SSISDB' does not exist on instance '$InstanceName'."
            return $false
        }
    }
    catch {
        Write-Error "Error testing for SSIS Catalog: $_"
        throw
    }
}

function Set-SsisCatalog {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$InstanceName,

        [Parameter(Mandatory = $true)]
        [string]$Password,

        [Parameter(Mandatory = $true)]
        [ValidateSet("SQL2019", "sQL2022", "SQL2025")]
        [string]$SqlVersion
    )

    try {
        # Load dependent assemblies and modules
        import-module SqlServer
        $dependentAssemblies = @(
            "Microsoft.SqlServer.Management.IntegrationServicesEnum",
            "Microsoft.SqlServer.Management.IntegrationServices"
        )

        foreach ($assembly in $dependentAssemblies) {
            Write-Verbose "Loading assembly: $assembly"
            [System.Reflection.Assembly]::LoadWithPartialName($assembly) | Out-Null
        }

        $ISNamespace = "Microsoft.SqlServer.Management.IntegrationServices"
        $sqlConnectionString = "Data Source=$InstanceName;Initial Catalog=master;Integrated Security=SSPI;Encrypt=False"
        $sqlConnection = $null

        Write-Verbose "Connecting to server '$InstanceName' and starting Integration Services catalog setup..."

        # Conditional logic for SQL client library
        if ($SqlVersion -eq "SQL2025") {
            Write-Verbose "SQL Server 2025 detected. Using Microsoft.Data.SqlClient."
            try {
                Add-Type -AssemblyName "Microsoft.Data.SqlClient"
                $sqlConnection = New-Object Microsoft.Data.SqlClient.SqlConnection $sqlConnectionString
            }
            catch {
                throw "Failed to load Microsoft.Data.SqlClient and create a connection. Ensure the module is available on the target node."
            }
        }
        else {
            Write-Verbose "SQL Server $SqlVersion detected. Using System.Data.SqlClient."
            try {
                # System.Data.SqlClient is part of .NET Framework
                $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $sqlConnectionString
            }
            catch {
                throw "Failed to create a connection using System.Data.SqlClient: $_"
            }
        }

        $integrationServices = New-Object "$ISNamespace.IntegrationServices" $sqlConnection
        $catalog = New-Object "$ISNamespace.Catalog" ($integrationServices, "SSISDB", $Password)

        Write-Verbose "Creating the SSISDB catalog..."
        $catalog.Create()
        Write-Verbose "SSISDB catalog created successfully."
    }
    catch {
        Write-Error "Failed to set up the Integration Services Catalog: $_"
        throw
    }
}
