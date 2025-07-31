# manage_powershell_modules

This role manages PowerShell modules on Windows hosts. It can be used to ensure that specific PowerShell modules are installed on a host.

## Requirements

- Ansible 2.9 or higher
- community.windows collection

## Role Variables

- `manage_powershell_modules_to_install`: A list of PowerShell modules to install. Default: `['SqlServerDsc', 'SqlServer']`
- `manage_powershell_modules_install_method`: The method to install PowerShell modules. Can be `'gallery'` (from PowerShell Gallery) or `'local'` (from a local path on the Ansible controller). Default: `'gallery'`
- `manage_powershell_modules_local_path`: If `manage_powershell_modules_install_method` is set to `'local'`, specify the absolute path on the Ansible control node where the module files are located. Example: `'/home/user/ansible_modules'`


## Dependencies

- community.windows

## Example Playbook

```yaml
- hosts: all
  roles:
    - role: manage_powershell_modules
      vars:
        manage_powershell_modules_to_install:
          - SqlServerDsc
          - SqlServer
```

## License

MIT

## Author Information

- Luke Campbell (<Luke.Campbell@automatesql.com>)