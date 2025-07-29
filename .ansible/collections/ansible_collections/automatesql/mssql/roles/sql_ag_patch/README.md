# Ansible Role: SQL Server Availability Group Patcher

This role performs a rolling patch update on SQL Server instances that are part of an Availability Group (AG). It is designed to be idempotent and resilient, ensuring a safe and predictable patching process with minimal downtime.  

> However, every environment comes with its own nuances.  Test thouroughly prior to using in a production environment.  By default, all secondaries will be patched at the same time (up to Ansible's default fork of 5).  To change this behavior, see [Selecting a strategy](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_strategies.html) in Ansible's documentation.

The role handles the entire lifecycle of patching, including:
- Identifying the primary and secondary replicas.
- Patching secondary replicas first.
- Performing a controlled failover to a patched secondary.
- Patching the former primary replica.
- Optionally failing back to the original primary.
- Cleaning up temporary files and modules.

## Requirements

- **Ansible**: Version 2.12 or higher.
- **Target Hosts**: Windows Server with PowerShell 5.1 or higher.
- **SQL Server**: SQL Server instances configured in an Availability Group.
- **PowerShell Modules**: The `SqlServer` PowerShell module is required and must be installed on the target hosts prior to running this role. The `automatesql.mssql.manage_powershell_modules` role can be used for this purpose.

## Role Variables

The following variables can be defined to control the role's behavior.

### Required Variables

- `ag_name`: The name of the SQL Server Availability Group to patch.
  ```yaml
  ag_name: "My-AG"
  ```
- `desired_sql_version`: The exact version string of SQL Server after the patch is applied (e.g., `15.0.4223.1`). This is used for verification.
  ```yaml
  desired_sql_version: "15.0.4223.1"
  ```
- `sql_instance_name`: The name of the SQL Server instance. For a default instance, use `DEFAULT`.
  ```yaml
  sql_instance_name: "DEFAULT"
  ```
- `sql_patch_source`: The remote path (e.g., a UNC share) accessible from the target Windows nodes where the SQL patch executable is located.
  ```yaml
  sql_patch_source: "//FileServer/SQL_Updates/"
  ```
- `sql_patch_filename`: The filename of the SQL patch executable.
  ```yaml
  sql_patch_filename: "SQLServer2019-KB5011644-x64.exe"
  ```
- `sql_patch_checksum`: The SHA256 checksum of the patch executable for verification.
  ```yaml
  sql_patch_checksum: "a1b2c3d4..."
  ```


### Optional Variables

- `patch_primary`: Whether to patch the primary replica. If set to `false`, the role will patch the secondaries and then stop. Defaults to `true`.
  ```yaml
  patch_primary: true
  ```
- `sql_ag_failback`: Whether to fail back to the original primary after patching is complete. Defaults to `true`.
  ```yaml
  sql_ag_failback: false
  ```
- `reboot_secondary`: Whether to reboot secondary replicas after patching. Defaults to `true`.
  ```yaml
  reboot_secondary: true
  ```

- `sql_patch_args`: Command-line arguments to pass to the patch executable.
  ```yaml
  sql_patch_args: "/q /IAcceptSQLServerLicenseTerms /Action=Patch /InstanceName={{ sql_instance_name_to_patch }}"
  ```
- `sql_port`: The TCP port SQL Server is listening on. Used to verify service availability after a reboot. Defaults to `1433`.
  ```yaml
  sql_port: 1433
  ```
- `sql_reboot_timeout`: The time in seconds to wait for the reboot to complete. Defaults to `1800`.
  ```yaml
  sql_reboot_timeout: 1800
  ```
- `sql_patch_temp_folder`: A temporary folder on the target nodes for staging files. Defaults to `C:/temp/`.
  ```yaml
  sql_patch_temp_folder: "C:/temp/"
  ```

## Workflow

1.  **Prerequisites**: On each host, the role verifies the patch file checksum and gathers facts about the current SQL version.
2.  **Identify Primary**: The role connects to each instance to determine which replica is currently primary.
3.  **Patch Secondaries**: For all secondary replicas, the role:
    - Sets the replica's failover mode to `Manual` to prevent accidental failovers.
    - Installs the SQL patch.
    - Reboots the server and waits for the SQL service to come back online.
    - Verifies the new SQL version.
    - Resets the failover mode to `Automatic` (this happens even if patching fails).
4.  **Failover**: The role connects to the primary replica and fails over to a healthy, patched secondary replica.
5.  **Patch Primary**: The now-secondary (original primary) replica is patched using the same process as other secondaries.
6.  **Failback**: If `sql_ag_failback` is `true`, the role fails the AG back to the original primary node.
7.  **Cleanup**: The role removes the temporary staging folder and, if requested, uninstalls the `SqlServer` module from all nodes.  If the module existed prior to running this role, it is left as is.

## Example Playbook

```yaml
---
- name: Patch SQL Server Availability Group
  hosts: sqlservers
  gather_facts: true

  vars:
    ag_name: "My-AG"
    desired_sql_version: "15.0.4223.1"
    sql_instance_name: "DEFAULT"
    sql_patch_source: "//FileServer/SQL_Updates/"
    sql_patch_filename: "SQLServer2019-KB5011644-x64.exe"
    sql_patch_checksum: "a1b2c3d4..." # Replace with actual checksum
    powershell_modules_path: "../"
  
  tasks: 
    - name: Import the sql_ag_patch role
      ansible.builtin.import_role:
        name: automatesql.mssql.sql_install  
```