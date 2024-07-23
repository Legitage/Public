# Install_PowerShellModules

Automates installation of PSGallery PowerShell modules specified in JSON file

## Description

Automatically elevates the PowerShell script and installs JSON specified PowerShell modules with the latest version.  
Includes upgrade from Pester v3 to Pester v5.  
Installs latest version of PowerShell 7

## Getting Started

- Copy the ```Install_PowerShellModules``` folder to install location.
- Script must run from an elevated command prompt (user should be prompted)
- Requires setting the execution to allow running local scripts if not already set
  - If Get-ExecutionPolicy is the result is "Undefined" -or "Restricted", run:

  ```PowerShell
  Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
  ```

### Dependencies

- User account with Administrative privileges on the local workstation
- ```Install_PowerShellModules.psm1``` PowerShell module
- ```PowerShellModulesList.json``` file

### Configurable information in PowerShellModulesList.json

- List of PowerShell modules to install
- Option to upgrade Pester module
- Option to install/update PowerShell 7

### Log file location

Log file is written to the environment temp directory: ```$env:TEMP```  
Should be the same as: ```%temp%```

## Logic Flow

1. Start script, get start time
   1. Auto-Elevate PowerShell script if not already
   2. Install_PowerShellModules module
   3. Import module install list from JSON file
   4. Set log file path
   5. Get Modules to be installed or updated to the latest version
   6. Begin update log
2. Begin module installation
   1. Always make sure that PSGallery is installed and trusted or all other module install operations will be problematic
      1. Set TLS 1.2
      2. Install the latest NuGet provider
      3. Allow modules to be installed from PS Gallery without prompts
      4. Install PowerShellGet
   2. Install the latest version of specified modules if missing or outdated
      1. Loop through each PowerShell module in the list
      2. Check if the module is already installed
      3. Install/update the specified module
      4. Collect the module install results
   3. Pester is a special case and requires different handling
      1. Check to see if any version of Pester v5 is already installed
      2. Remove Pester v3 module files and reg keys
3. Download and install/upgrade PowerShell 7
    1. Get currently installed version of PowerShell 7
    2. Get the latest version of PowerShell 7
    3. Check if PowerShell version is current or not installed
    4. Install/update PowerShell 7
    5. Collect PowerShell 7 install results
4. Display results
   1. Log script execution time
   2. Display log file path
   3. Leave output on screen for 10 seconds before closing the window

## Version History

- Change history located in Install_PowerShellModules.psd1

```PowerShell
(Import-PowerShellDataFile .\Install_PowerShellModules.psd1).PrivateData.PSData.ReleaseNotes
```
