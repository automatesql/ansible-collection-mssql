# manage_powershell_modules

This role manages PowerShell modules on Windows hosts. It can be used to ensure that specific PowerShell modules are installed on a host.

## Requirements

- Ansible 2.9 or higher
- community.windows collection

## Role Variables

- `manage_powershell_modules_to_install`: A list of PowerShell modules to install. Default: `['SqlServerDsc', 'SqlServer']`
- `manage_powershell_modules_path`: The path to install the PowerShell modules to. Default: `C:\Program Files\WindowsPowerShell\Modules`

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
