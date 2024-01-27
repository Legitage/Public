# New-WinServerUsbInstall

## Description

Copies install files from ISO Windows Server 2016, 2019, or 2022 server image and creates a UEFI or BIOS bootable USB drive

## Getting Started

### Dependencies

- PowerShell 5.1 is required. This is installed by default on all versions of Windows 10 and Windows 11.
- A Windows Server 2016, 2019, or 2022 ISO image

### Installing

- Download script files to the local hard drive

### Executing program

- Run the script from an elevated PowerShell prompt
- Examples:

```PowerShell
# Create UEFI compatible flash drive using the specified Windows Server ISO
.\New-WinServerUsbInstall.ps1 "C:\Temp\WindowsServer2022.iso"

# Create a legacy BIOS compatible flash drive using the specified Windows Server ISO
.\New-WinServerUsbInstall.ps1 -WindowsServerISO "C:\Temp\WindowsServer2022.iso" -BootType MBR
```

## Help

Built-in parameter help is available using Get-Help

```PowerShell
Get-Help New-WinServerUsbInstall.ps1 -Detailed
```

## Authors

Author: Chad Armitage  
Contact: <legitage@hotmail.com>  
Copyright: Chad Armitage

## Version History

- 1.0.0
  - Initial Release

## License

MIT License  
[LICENSE](https://github.com/Legitage/Public/blob/main/LICENSE) file for details

## Acknowledgments

Thanks to Thomas Maurer for the idea: [Create an USB Drive for Windows Server 2022 Installation](https://www.thomasmaurer.ch/2021/11/create-an-usb-drive-for-windows-server-2022-installation/)
