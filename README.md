# Ansible Collection: automatesql.mssql

This collection provides a single, powerful role for the complete, automated installation and configuration of Microsoft SQL Server on Windows. It is designed to be idempotent and flexible, handling everything from initial setup to the deployment of essential maintenance solutions.

This role can perform the following actions:
* Prepare and format disks for SQL Server data, logs, and TempDB.
* Install any specified edition of SQL Server from an ISO file.
* Apply cumulative updates.
* Configure service accounts, memory, and security settings.
* Deploy and configure Database Mail.
* Deploy a utility database containing industry-standard maintenance solutions.
* Create and schedule essential SQL Server Agent jobs.

---

### **🚀 Want to Become an Expert?**

This collection provides the tools to manage SQL Server. My comprehensive video course teaches you the advanced patterns and best practices to use it. You'll get access to advanced playbooks, the inventory file examples, and access to the the AutomateSQL Insiders Community to help you master SQL Server automation.

**[Enroll in the Ansible for SQL Server DBAs course now!](https://www.automatesql.com/ansible)**

---

## Requirements

Before using this role, the target Windows host must have the following PowerShell modules installed:
* **SqlServer**
* **SqlServerDsc**

These can be installed using a separate playbook with the `ansible.windows.win_psmodule` module (if the hosts have internet access).

## Role Variables

This role is highly configurable using the following variables.

### Core Installation Settings
| Variable | Default Value | Description |
|---|---|---|
| `rl_mssql_edition` | `"Standard Developer"` | The edition of SQL Server to install (applies to SQL Server 2025)  (e.g., "Standard Developer", "Enterprise Developer"). |
| `rl_mssql_iso_source` | (see defaults) | A list containing the name of the SQL Server ISO, a version identifier, and the configuration template to use. |
| `rl_mssql_update_source` | (see defaults) | A list containing the name of the update package and a version identifier. |
| `rl_mssql_share` | `"/home/username/ISO/"` | The local path on the Ansible control node where the ISO and update files are located. |
| `rl_mssql_temp_folder` | `C:\temp` | A temporary folder on the target host for installation files. |
| `rl_mssql_enableupdates` | `"true"` | Whether to enable Microsoft Updates for SQL Server during installation. |
| `rl_mssql_features` | `SQLENGINE,REPLICATION,FULLTEXT,IS` | A comma-separated list of SQL Server features to install. |
| `rl_mssql_instance_name` | `MSSQLSERVER` | The name of the SQL Server instance. Use `MSSQLSERVER` for the default instance. |
| `rl_mssql_sqlcollation` | `SQL_Latin1_General_CP1_CI_AS` | The collation for the SQL Server instance. |
| `rl_mssql_instance_port` | `1433` | The TCP port for the SQL Server instance. |

### Service Accounts
| Variable | Default Value | Description |
|---|---|---|
| `rl_mssql_svcaccount` | `NT Service\MSSQLSERVER` | The service account for the SQL Server Database Engine. |
| `rl_mssql_svcpassword` | (empty) | The password for the Database Engine service account. Use Ansible Vault for this value. |
| `rl_mssql_svcagentaccount` | `NT Service\SQLSERVERAGENT` | The service account for the SQL Server Agent. |
| `rl_mssql_svcagentpassword` | (empty) | The password for the Agent service account. Use Ansible Vault for this value. |
| `rl_mssql_issvcaccount` | `NT Service\MsDtsServer160` | The service account for SQL Server Integration Services (SSIS). |
| `rl_mssql_issvcpassword` | (empty) | The password for the SSIS service account. Use Ansible Vault for this value. |
| `rl_mssql_sqlsvcinstantfileinit` | `"true"` | Whether to grant the "Perform volume maintenance tasks" permission to the SQL service account for Instant File Initialization. |

### Directory and Path Configuration
| Variable | Default Value | Description |
|---|---|---|
| `rl_mssql_prep_disks` | `"true"` | Whether the role should attempt to format and label disks. |
| `rl_mssql_installshareddir` | `C:\Program Files\Microsoft SQL Server` | The path for shared SQL Server components. |
| `rl_mssql_installsharedwowdir` | `C:\Program Files (x86)\Microsoft SQL Server` | The path for 32-bit shared SQL Server components. |
| `rl_mssql_instance_dir` | `C:\Program Files\Microsoft SQL Server` | The root directory for the SQL Server instance. |
| `rl_mssql_userdb_path` | `E:\SQLDATA` | The default location for user database data files. |
| `rl_mssql_userdblog_path` | `F:\SQLDATA` | The default location for user database log files. |
| `rl_mssql_backup_path` | `T:\BACKUP` | The default location for database backups. |

### TempDB Configuration
| Variable | Default Value | Description |
|---|---|---|
| `rl_mssql_tempdb_path` | `T:\SQLDATA` | The location for TempDB data files. |
| `rl_mssql_tempdblog_path` | `T:\SQLDATA` | The location for TempDB log files. |
| `rl_mssql_tempdbfilecount` | `4` | The number of TempDB data files to create. |
| `rl_mssql_tempdbfilesize` | `256` | The initial size (in MB) of each TempDB data file. |
| `rl_mssql_tempdbfilegrowth` | `256` | The autogrowth increment (in MB) for TempDB data files. |
| `rl_mssql_tempdblogfilesize` | `256` | The initial size (in MB) of the TempDB log file. |
| `rl_mssql_tempdblogfilegrowth` | `64` | The autogrowth increment (in MB) for the TempDB log file. |

### Post-Installation & Maintenance
| Variable | Default Value | Description |
|---|---|---|
| `rl_mssql_install_ssisdb` | `"true"` | Whether to create and configure the SSISDB catalog. |
| `rl_mssql_dbagent_operator` | (see defaults) | A list defining the name and email for a SQL Server Agent operator. |
| `rl_mssql_dbmail` | (see defaults) | A list of settings to configure Database Mail. |

## Utility Database and Maintenance Jobs

This role can deploy a powerful utility database that includes:
* **Ola Hallengren's Maintenance Solution:** The industry standard for database backups, integrity checks, and index maintenance.
* **Brent Ozar's First Responders Kit:** A suite of diagnostic scripts to help troubleshoot performance issues.
* **sp_whoisactive:** A comprehensive activity monitoring stored procedure.

The following SQL Server Agent jobs are deployed and configured as part of the maintenance solution:
* Full, differential, and transaction log backups.
* Index and statistics maintenance.
* Database integrity checks.
* Cleanup of backup and job history from the `msdb` database.
* Daily cycling of the SQL Server error log.

## Dependencies

This collection requires the following collections to be installed:
* `ansible.windows`
* `community.windows`

## Example Playbook

Here is a basic example of how to use this role in a playbook. Create a host inventory file and then run this playbook.

```yaml
---
- name: Install SQL Server using mssql role
  hosts: sqlservers
  gather_facts: true

  tasks:
    - name: Import the mssql role
      ansible.builtin.import_role:
        name: automatesql.mssql.sql_install
```

## License

MIT

## Author Information

This collection was created by [Luke Campbell](https://www.automatesql.com).
