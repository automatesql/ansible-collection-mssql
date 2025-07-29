[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)]
  [string]$SqlInstanceName,

  [Parameter(Mandatory=$true)]
  [string]$AgName
)

import-module SqlServer
(Test-SqlAvailabilityGroup -Path "SQLSERVER:\Sql\LOCALHOST\$SqlInstanceName\AvailabilityGroups\$AgName" -ErrorAction Stop).HealthState
$Ansible.Changed = $false
