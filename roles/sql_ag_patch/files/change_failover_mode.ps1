[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SqlInstanceName,

    [Parameter(Mandatory=$true)]
    [string]$AgName,

    [Parameter(Mandatory=$true)]
    [string]$AgCurrentPrimary,

    [Parameter(Mandatory=$true)]
    [string]$NewPrimary,

    [Parameter(Mandatory=$true)]
    [string]$HostName,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Manual", "Automatic")]
    [string]$TargetMode
)

# Initialize result object
$Ansible.Result = @{
  Success = $false
  Message = ''
  Changed = $false
}

try {
    Import-Module SqlServer -ErrorAction Stop

    # Determine which primary to connect to. If a failover has occurred, NewPrimary will be set.
    if ($NewPrimary -and $NewPrimary -ne "default_value") {
        $primaryToConnect = $NewPrimary
    }
    else {
        $primaryToConnect = $AgCurrentPrimary
    }

    # Build the full instance path for the primary replica.
    if ($primaryToConnect -like '*\*') {
        $PrimaryInstancePath = $primaryToConnect
    }
    else {
        $PrimaryInstancePath = "$primaryToConnect\DEFAULT"
    }
    Write-Verbose "Connecting to primary instance: $PrimaryInstancePath"

    # Build the replica name string. For a default instance, it's just the hostname.
    $replicaNameString = $HostName
    if ($SqlInstanceName -ne 'DEFAULT') {
        $replicaNameString = "$HostName\$SqlInstanceName"
    }

    # Get the target secondary replica object.
    $EncodedSecondaryName = ConvertTo-EncodedSqlName -SqlName $replicaNameString
    $replicaPath = "SQLSERVER:\Sql\$PrimaryInstancePath\AvailabilityGroups\$AgName\AvailabilityReplicas\$EncodedSecondaryName"
    $replica = Get-Item -Path $replicaPath -ErrorAction Stop

    if ($null -eq $replica) {
        throw "Replica '$replicaNameString' not found at path '$replicaPath'."
    }

    # If the replica's current failover mode is not the target, update it.
    if ($replica.FailoverMode -ne $TargetMode) {
        Write-Verbose "Changing failover mode for '$($replica.Name)' to '$TargetMode'."
        Set-SqlAvailabilityReplica -InputObject $replica -FailoverMode $TargetMode -ErrorAction Stop | Out-Null
        $Ansible.Result.Message = "Replica '$($replica.Name)' failover mode changed to '$TargetMode'."
        $Ansible.Result.Changed = $true
    }
    else {
        $Ansible.Result.Message = "Replica '$($replica.Name)' is already set to '$TargetMode'. No changes made."
        $Ansible.Result.Changed = $false
    }
    $Ansible.Result.Success = $true
}
catch {
    $Ansible.Result.Success = $false
    $Ansible.Result.Message = "Failed to change failover mode: $($_.Exception.Message)"
}