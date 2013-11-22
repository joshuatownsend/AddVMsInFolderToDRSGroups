AddVMsInFolderToDRSGroups
=========================

PowerCLI script to add VMs in vCenter folders to DRS Groups
SCRIPT - POWERSHELL - VMware PowerCLI
NAME: AddVMsInFolderToDRSGroup.ps1

AUTHOR:  Josh Townsend
DATE:  2013/11/21
EMAIL: josh@vmtoday.com

COMMENT:  This script will find VMs in vCenter 'VMs & Templates' folders and 
			then add them to DRS groups.  This is helpful for dynamic
			environments where VMs are automatically created in a stretched
			cluster configuration.  Initially created for a VMware Horizon View
			environment running with dynamically provisioned Linked Clone 
			desktops on an EMC VPLEX supported stretched cluster.

Usage: 
	1. Create DRS VM and Host Groups in vSphere Client.
	2. Create affinity or antiaffinity rules per design.
	3. Update vCenterServer variable then run manually to save credentials.  
	4. Call from scheduled task like string below for ongoing use:
		Command: C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe 
		Arguments: -PSConsoleFile "%ProgramFiles(x86)%\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" -File "C:\DRSGroupAutomation\AddVMsInFolderToDRSGroup.ps1"
		Note: Schedule at >5min intervals to give DRS time to run.

Note: This will remove/replace all existing DRS Group members with VMs in
		folders identified by this script. Backup existing groups first: 
		http://www.vnugglets.com/2011/07/backupexport-full-drs-rule-info-via.html

VERSION HISTORY
1.0 2013.11.21 Initial Version.