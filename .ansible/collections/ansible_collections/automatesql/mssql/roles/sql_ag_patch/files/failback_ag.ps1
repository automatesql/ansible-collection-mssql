[CmdletBinding()]
param (
  [Parameter(Mandatory = $true)]
  [string]$AgFailbackTarget, # This is the ORIGINAL primary, our failback TARGET

  [Parameter(Mandatory = $true)]
  [string]$AgName,

  [Parameter(Mandatory = $true)]
  [string]$DesiredSqlVersion,

  [Parameter(Mandatory = $true)]
  [string]$NewPrimary # This is the CURRENT primary, where we run the failover FROM
)

# Initialize result object
$Ansible.Result = @{
  Success = $false
  Message = ''
  Changed = $false
}

try {
  Import-Module SqlServer -ErrorAction Stop

  # --- Construct correct instance and path names ---
  # The script runs on the CURRENT primary ($NewPrimary)
  $currentPrimaryInstance = if ($NewPrimary -like '*\*') {
      $NewPrimary
  } else {
     $NewPrimary + '\DEFAULT'
  }

  # The SQL provider path requires 'DEFAULT' for the default instance name.
  $agPath = "SQLSERVER:\Sql\$currentPrimaryInstance\AvailabilityGroups\$AgName"

  # --- Idempotency and Sanity Checks ---
  # Get the AG object by connecting to the current primary
  $ag = Get-Item -Path $agPath -ErrorAction Stop

  # Verify who is actually primary right now
  if ($ag.PrimaryReplicaServerName -ne $NewPrimary) {
    # Check if failback has already happened
    if ($ag.PrimaryReplicaServerName -eq $AgFailbackTarget) {
      $Ansible.Result.Success = $true
      $Ansible.Result.Changed = $false
      $Ansible.Result.Message = "Failback is not required. '$AgFailbackTarget' is already the primary replica."
      return
    }
    throw "The current primary is '$($ag.PrimaryReplicaServerName)', not '$NewPrimary' as expected. Cannot determine failback path."
  }

  # --- Check Failback Target Health ---
  # Check 1: Health State. This is done via query for consistency with failover_ag.ps1
  $healthCheckQuery = @"
SELECT
    rs.synchronization_health_desc AS HealthState
FROM
    sys.availability_groups AS ag
JOIN
    sys.availability_replicas AS ar ON ag.group_id = ag.group_id
JOIN
    sys.dm_hadr_availability_replica_states AS rs ON ar.replica_id = rs.replica_id
WHERE
    ag.name = '$AgName'
    AND ar.replica_server_name = '$AgFailbackTarget'
"@
  $targetHealthState = (Invoke-Sqlcmd -ServerInstance $NewPrimary -Query $healthCheckQuery -ErrorAction Stop -Encrypt Optional).HealthState

  # Check 2: Version of the target replica.
  $targetVersion = (Get-SqlInstance -ServerInstance $AgFailbackTarget -ErrorAction Stop).Version.ToString()

  if ($targetVersion -ne $DesiredSqlVersion) {
    throw "Cannot fail back. Target replica '$AgFailbackTarget' is not at the desired version. Expected: '$DesiredSqlVersion', Actual: '$targetVersion'."
  }

  if ($targetHealthState -ne 'HEALTHY') {
    throw "Cannot fail back. Target replica '$AgFailbackTarget' is not healthy. Current state: '$targetHealthState'."
  }

  # --- Perform Failback ---
  # The path must point to the Availability Group on the TARGET replica.
  $instancePathname = if ( $AgFailbackTarget -like '*\*') {
        $AgFailbackTarget
    } else {
        $AgFailbackTarget + '\DEFAULT'
    }

    Write-Verbose "Performing failover to $instancePathname..."

    # The path for Switch-SqlAvailabilityGroup is to the AG on the TARGET replica
    $failoverPath = "SQLSERVER:\Sql\$instancePathname\AvailabilityGroups\$AgName"

    Write-Verbose "Failing over AG '$AgName' from '$newPrimary' to '$AgFailbackTarget'..."
    Switch-SqlAvailabilityGroup -Path $failoverPath -ErrorAction Stop

  $Ansible.Result.Success = $true
  $Ansible.Result.Changed = $true
  $Ansible.Result.Message = "Successfully failed back Availability Group '$AgName' to '$AgFailbackTarget'."

 
}
catch {
  $Ansible.Result.Success = $false
  $Ansible.Result.Message = "Failback failed: $($_.Exception.Message)"
}