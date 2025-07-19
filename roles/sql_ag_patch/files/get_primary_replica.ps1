[CmdletBinding()]
param (
  [Parameter(Mandatory = $true)]
  [string]$SqlInstanceName,

  [Parameter(Mandatory = $true)]
  [string]$AgName
)

# Initialize result object
$Ansible.Result = @{
  Success        = $false
  PrimaryReplica = ''
  Message        = ''
}

try {
  Import-Module SqlServer -ErrorAction Stop

  # Get the AG object by connecting to the local instance
  $ag = Get-Item -Path "SQLSERVER:\Sql\localhost\$SqlInstanceName\AvailabilityGroups\$AgName" -ErrorAction Stop

  $Ansible.Result.Success = $true
  $Ansible.Result.PrimaryReplica = $ag.PrimaryReplicaServerName
  $Ansible.Result.Message = "Successfully identified '$($ag.PrimaryReplicaServerName)' as the primary replica for AG '$AgName'."

}
catch {
  $Ansible.Result.Success = $false
  $Ansible.Result.Message = "Failed to get primary replica: $($_.Exception.Message)"
}