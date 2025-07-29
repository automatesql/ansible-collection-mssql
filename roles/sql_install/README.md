## SQL_INSTALL

This role can perform the following actions:
* Prepare and format disks for SQL Server data, logs, and TempDB.
* Install any specified edition of SQL Server from an ISO file.
* Apply cumulative updates.
* Configure service accounts, memory, and security settings.
* Deploy and configure Database Mail.
* Deploy a utility database containing industry-standard maintenance solutions.
* Create and schedule essential SQL Server Agent jobs.

---

### **Want to Become an Expert?**

This collection provides the tools to manage SQL Server. My comprehensive course teaches you the advanced patterns and best practices to use it. You'll get access to advanced playbooks, the inventory file examples, and access to the the AutomateSQL Insiders Community to help you master SQL Server automation.

**[Enroll in the Ansible for SQL Server DBAs course now!](https://www.automatesql.com/ansible)**

---

## Requirements

Before using this role, the target Windows host must have the following PowerShell modules installed:
* **SqlServer**
* **SqlServerDsc**

These can be installed using a separate playbook with the `ansible.windows.win_psmodule` module (if the hosts have internet access).

## Role Variables

This role is highly configurable using the following variables.

### Prerequisite Settings
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_powershell_modules_path` | `"../"` | The path on the Ansible controller where the `SqlServer` and `SqlServerDsc` module source directories are located. |


### Core Installation Settings
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_edition` | `"Standard Developer"` | The edition of SQL Server to install (e.g., "Standard Developer", "Enterprise Developer"). |
| `sql_install_iso_source` | (see defaults) | A list containing the name of the SQL Server ISO and a version identifier. |
| `sql_install_update_source` | (see defaults) | A list containing the name of the update package and a version identifier. |
| `sql_install_share` | `"/home/username/ISO/"` | The local path on the Ansible control node where the ISO and update files are located. |
| `sql_install_temp_folder` | `C:\temp` | A temporary folder on the target host for installation files. |
| `sql_install_enableupdates` | `"true"` | Whether to enable Microsoft Updates for SQL Server during installation. |
| `sql_install_features` | `SQLENGINE,REPLICATION,FULLTEXT,IS` | A comma-separated list of SQL Server features to install. |
| `sql_install_instance_name` | `MSSQLSERVER` | The name of the SQL Server instance. Use `MSSQLSERVER` for the default instance. |
| `sql_install_sqlcollation` | `SQL_Latin1_General_CP1_CI_AS` | The collation for the SQL Server instance. |
| `sql_install_instance_port` | `1433` | The TCP port for the SQL Server instance. |
| `sql_install_security_mode` | `SQL` | The authentication mode for SQL Server. Can be `SQL` or `Windows`. |
| `sql_install_tcp_enabled` | `true` | Whether to enable the TCP/IP protocol for the SQL Server instance. |

### Service Accounts
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_sql_svc_account` | `NT Service\MSSQLSERVER` | The service account for the SQL Server Database Engine. |
| `sql_install_sql_svc_password` | (empty) | The password for the Database Engine service account. Use Ansible Vault for this value. |
| `sql_install_agent_svc_account` | `NT Service\SQLSERVERAGENT` | The service account for the SQL Server Agent. |
| `sql_install_agent_svc_password` | (empty) | The password for the Agent service account. Use Ansible Vault for this value. |
| `sql_install_issvcaccount` | `NT Service\MsDtsServer160` | The service account for SQL Server Integration Services (SSIS). |
| `sql_install_issvcpassword` | (empty) | The password for the SSIS service account. Use Ansible Vault for this value. |
| `sql_install_sqlsvcinstantfileinit` | `"true"` | Whether to grant the "Perform volume maintenance tasks" permission to the SQL service account for Instant File Initialization. |

### Directory and Path Configuration
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_disks_to_format` | (see defaults) | A list of dictionaries defining the disks to partition and format. Each item needs a `number`, `letter`, and `label`. |
| `sql_install_prep_disks` | `"true"` | Whether the role should attempt to format and label disks. |
| `sql_install_installshareddir` | `C:\Program Files\Microsoft SQL Server` | The path for shared SQL Server components. |
| `sql_install_installsharedwowdir` | `C:\Program Files (x86)\Microsoft SQL Server` | The path for 32-bit shared SQL Server components. |
| `sql_install_instance_dir` | `C:\Program Files\Microsoft SQL Server` | The root directory for the SQL Server instance. |
| `sql_install_userdb_path` | `E:\SQLDATA` | The default location for user database data files. |
| `sql_install_userdblog_path` | `F:\SQLDATA` | The default location for user database log files. |
| `sql_install_backup_path` | `T:\BACKUP` | The default location for database backups. |

### TempDB Configuration
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_tempdb_path` | `T:\SQLDATA` | The location for TempDB data files. |
| `sql_install_tempdblog_path` | `T:\SQLDATA` | The location for TempDB log files. |
| `sql_install_tempdbfilecount` | `4` | The number of TempDB data files to create. |
| `sql_install_tempdbfilesize` | `256` | The initial size (in MB) of each TempDB data file. |
| `sql_install_tempdbfilegrowth` | `256` | The autogrowth increment (in MB) for TempDB data files. |
| `sql_install_tempdblogfilesize` | `256` | The initial size (in MB) of the TempDB log file. |
| `sql_install_tempdblogfilegrowth` | `64` | The autogrowth increment (in MB) for the TempDB log file. |

### Post-Installation & Maintenance
| Variable | Default Value | Description |
|---|---|---|
| `sql_install_install_ssisdb` | `"true"` | Whether to create and configure the SSISDB catalog. |
| `sql_install_dbagent_operator` | (see defaults) | A list defining the name and email for a SQL Server Agent operator. |
| `sql_install_dbmail` | (see defaults) | A list of settings to configure Database Mail. |

## Utility Database and Maintenance Jobs

This role can deploy a powerful utility database that includes:
* **Ola Hallengren's Maintenance Solution:** The industry standard for database backups, integrity checks, and index maintenance.
* **Brent Ozar's First Responders Kit:** A suite of diagnostic scripts to help troubleshoot performance issues.

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
- name: Install SQL Server using sql_install role
  hosts: sqlservers
  gather_facts: true

  tasks:
    - name: Import the sql_install role
      ansible.builtin.import_role:
        name: automatesql.mssql.sql_install
```

## License

See the LICENSE file in this collection.

## Author Information

This collection was created by [Luke Campbell](https://www.automatesql.com).