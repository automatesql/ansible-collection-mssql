# Ansible Collection: automatesql.mssql

This collection provides a suite of powerful Ansible roles for the complete, automated lifecycle management of Microsoft SQL Server on Windows. It is designed to be idempotent, flexible, and scalable, handling everything from initial installation to ongoing maintenance like patching.

This collection will grow over time to include more roles for comprehensive SQL Server administration.

---

### **🚀 Want to Become an Expert?**

This collection provides the tools to manage SQL Server. My comprehensive course teaches you the advanced patterns and best practices to use it. You'll get access to advanced playbooks, the inventory file examples, and access to the the AutomateSQL Insiders Community to help you master SQL Server automation.

**[Enroll in the Ansible for SQL Server DBAs course now!](https://www.automatesql.com/ansible)**

---

## Available Roles

This collection currently includes the following roles:

*   **`sql_install`**: Performs a complete, automated installation and configuration of a standalone SQL Server instance.
*   **`sql_ag_patch`**: Manages the rolling patch process for a SQL Server Always On Availability Group with minimal downtime.
*   **`manage_powershell_modules`**: Installs PowerShell modules on Windows hosts, either from the PowerShell Gallery or a local path.

For detailed information on role-specific variables, requirements, and workflows, please refer to the `README.md` file within each role's directory.

## Collection Dependencies

This collection requires the following collections to be installed:
* `ansible.windows`
* `community.windows`

## Example Playbooks

Here are basic examples of how to use the roles in this collection.

### Example 1: Install a New SQL Server Instance

This playbook uses the `sql_install` role to deploy a new, standalone SQL Server instance.

```yaml
---
- name: Install SQL Server using the sql_install role
  hosts: sqlservers
  gather_facts: true

  tasks:
    - name: Import the sql_install role
      ansible.builtin.import_role:
        name: automatesql.mssql.sql_install
```

### Example 2: Patch a SQL Server Availability Group

This playbook uses the `sql_ag_patch` role to apply updates to an existing Availability Group.

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
    
  
  tasks: 
    - name: Import the sql_ag_patch role
      ansible.builtin.import_role:
        name: automatesql.mssql.sql_ag_patch  
```

## License

See the LICENSE file in this collection.

## Author Information

This collection was created by [Luke Campbell](https://www.automatesql.com).

## Third-Party Components

This collection utilizes the following PowerShell modules as prerequisites:

*   **SqlServer**: For managing SQL Server instances. This module can be installed from the PowerShell Gallery using the `manage_powershell_modules` role.
*   **SqlServerDSC**: For declarative configuration of SQL Server. This module can be installed from the PowerShell Gallery using the `manage_powershell_modules` role.