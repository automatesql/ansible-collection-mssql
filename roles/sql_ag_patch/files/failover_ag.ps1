[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$AgCurrentPrimary, # The CURRENT primary server name, where we run the checks and failover FROM

    [Parameter(Mandatory = $true)]
    [string]$AgName,

    [Parameter(Mandatory = $true)]
    [string]$DesiredSqlVersion
)

# Initialize result object for Ansible
$Ansible.Result = @{
    Success    = $false
    Message    = ''
    NewPrimary = ''
    Changed    = $false
}

try {
    Import-Module SqlServer -ErrorAction Stop

    
    write-verbose "Current primary replica: '$AgCurrentPrimary'"


    # --- Idempotency Check ---
    # We need to check the current state to see if a failover is needed at all.
    # This query gets the name of the current primary replica.
    $primaryCheckQuery = "
        SELECT ags.primary_replica
        FROM sys.dm_hadr_availability_group_states AS ags
        JOIN sys.availability_groups AS ag ON ags.group_id = ag.group_id
        WHERE ag.name = '$AgName'
    "
    $actualPrimary = (Invoke-Sqlcmd -ServerInstance $AgCurrentPrimary -Query $primaryCheckQuery -ErrorAction Stop -Encrypt Optional).primary_replica

    if ($actualPrimary -ne $AgCurrentPrimary) {
        $Ansible.Result.Success = $true
        $Ansible.Result.Changed = $false
        $Ansible.Result.Message = "Failover is not required. '$actualPrimary' is already the primary replica."
        $Ansible.Result.NewPrimary = $actualPrimary
        return
    }

    # --- Find a Suitable Failover Target ---
    Write-Verbose "Querying '$AgCurrentPrimary' to find a suitable failover target for AG '$AgName'..."

    # This single T-SQL query consolidates the first three checks:
    # 1. Is the replica a SECONDARY?
    # 2. Is it in SYNCHRONOUS_COMMIT mode?
    # 3. Is its health state HEALTHY (which implies it is synchronized)?
    $candidateQuery = @"
SELECT
    ar.replica_server_name AS ReplicaServer
FROM
    sys.availability_groups AS ag
JOIN
    sys.availability_replicas AS ar ON ag.group_id = ar.group_id
JOIN
    sys.dm_hadr_availability_replica_states AS rs ON ar.replica_id = rs.replica_id
WHERE
    ag.name = '$AgName'
    AND rs.role = 2 -- 2 = SECONDARY
    AND ar.availability_mode = 1 -- 1 = SYNCHRONOUS_COMMIT
    AND rs.synchronization_health = 2; -- 2 = HEALTHY
"@

    # Get a list of potential failover candidates that passed the first two checks.
    $candidates = Invoke-Sqlcmd -ServerInstance $AgCurrentPrimary -Query $candidateQuery -ErrorAction Stop -Encrypt Optional

    $failoverTargetName = $null

    # Loop through the smaller list of candidates to perform the final version check.
    foreach ($candidate in $candidates) {
        $replicaName = $candidate.ReplicaServer
        Write-Verbose "Checking candidate replica '$replicaName' for version compliance..."

        # Check 3: Must be at the desired (patched) version.
        try {
            $replicaVersion = (Get-SqlInstance -ServerInstance $replicaName -ErrorAction Stop).Version.ToString()
            if ($replicaVersion -ne $DesiredSqlVersion) {
                Write-Verbose "  - Skipping: Version mismatch. Expected: '$DesiredSqlVersion', Actual: '$replicaVersion'"
                continue
            }
        }
        catch {
            # This handles cases where a replica is down or unreachable.
            Write-Warning "  - Skipping: Could not connect to or get version from replica '$replicaName'. Error: $($_.Exception.Message)"
            continue
        }

        # Found a suitable target that passes all checks.
        Write-Verbose "  - Success: Found suitable failover target '$replicaName'."
        $failoverTargetName = $replicaName
        break
    }

    if (-not $failoverTargetName) {
        throw "Could not find a suitable, patched, synchronous, and synchronized secondary replica to fail over to."
    }

    # --- Perform Failover ---
    # The SQL provider path requires 'DEFAULT' for the default instance name,
    # or the instance name for a named instance.
    $instancePathname = if ( $failoverTargetName -like '*\*') {
        $failoverTargetName
    } else {
        "$failoverTargetName\DEFAULT"
    }

    Write-Verbose "Performing failover to $instancePathname..."

    # The path for Switch-SqlAvailabilityGroup is to the AG on the TARGET replica
    $failoverPath = "SQLSERVER:\Sql\$instancePathname\AvailabilityGroups\$AgName"

    Write-Verbose "Failing over AG '$AgName' from '$currentPrimaryInstance' to '$($failoverTargetName)\$instancePathName'..."
    Switch-SqlAvailabilityGroup -Path $failoverPath -ErrorAction Stop

    $Ansible.Result.Success = $true
    $Ansible.Result.Changed = $true
    $Ansible.Result.Message = "Successfully failed over Availability Group '$AgName' to '$failoverTargetName'."
    $Ansible.Result.NewPrimary = $failoverTargetName

}
catch {
    $Ansible.Result.Success = $false
    $Ansible.Result.Message = "Failover failed: $($_.Exception.Message)"
    $Ansible.Result.NewPrimary = $AgCurrentPrimary # On failure, the primary has not changed
}
