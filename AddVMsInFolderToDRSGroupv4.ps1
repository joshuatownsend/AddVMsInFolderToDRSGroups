# #############################################################################
# SCRIPT - POWERSHELL - VMware PowerCLI
# NAME: AddVMsInFolderToDRSGroup.ps1
#
# AUTHOR:  Josh Townsend
# DATE:  2013/11/21
# EMAIL: josh@vmtoday.com
#
# COMMENT:  This script will find VMs in vCenter 'VMs & Templates' folders and 
#			then add them to DRS groups.  This is helpful for dynamic
#			environments where VMs are automatically created in a stretched
#			cluster configuration.  Initially created for a VMware Horizon View
#			environment running with dynamically provisioned Linked Clone 
#			desktops on an EMC VPLEX supported stretched cluster.
#
# Usage: 
#	1. Create DRS VM and Host Groups in vSphere Client.
#	2. Create affinity or antiaffinity rules per design.
#	3. Update vCenterServer variable then run manually to save credentials.  
#	4. Call from scheduled task with the command below for ongoing use:
#  Command: C:\WINDOWS\system32\windowspowershell\v1.0\powershell.exe 
#  Arguments: -PSConsoleFile "%ProgramFiles(x86)%\VMware\Infrastructure\vSphere PowerCLI\vim.psc1" -File "C:\DRSGroupAutomation\AddVMsInFolderToDRSGroup.ps1"
# 		Note: Schedule at >5min intervals to give DRS time to run.
#
# Note: This will remove/replace all existing DRS Group members with VMs in
# 		folders identified by this script. Backup existing groups first: 
# 		http://www.vnugglets.com/2011/07/backupexport-full-drs-rule-info-via.html
#
# VERSION HISTORY
# 1.0 2013.11.21 Initial Version.
#
# #############################################################################

## add VMware PowerCLI PSSnapin if not already loaded
if ((Get-PSSnapin -Name VMware.VimAutomation.Core -ErrorAction SilentlyContinue) -eq $null ) {Add-PsSnapin VMware.VimAutomation.Core; $bSnapinAdded = $true}

## Update vCenter Server Variable for server that this script will run against
$vCenterServer = "vcenter.domain.local"
## Update vCenter Credentials below.  These can be removed after the first run
## of this script and encrypted credentials are saved to CredentialFilePath.
$vCenterUser = "domain\DRSworker"
$vCenterPassword = "P@ssw0rd"

## We'll used saved credentials to connect so this can be called from a scheduled
# task.  Running this ps1 manually will prompt for credentials and save to an 
# encrypted xml.  Subsequent runs of the script will test-path for credentials.  
# If the credentials exists the script continues.
## Test-Path for existence of credential file
$CredentialFilePath = "c:\DRSGroupAutomation\vCCredentials.xml"
if(!(Test-Path -Path $CredentialFilePath))
  {
# Create Directory for creds
New-Item -ItemType Directory -Path C:\DRSGroupAutomation

## Get and Save Credentials for vCenter
New-VICredentialStoreItem -Host $vCenterServer -User $vCenterUser -Password $vCenterPassword -File $CredentialFilePath
  }
Else
{
## Connect to vCenter Using Saved Creds
Write-Output "Connecting to vCenter. Please stand by..."
$creds = Get-VICredentialStoreItem -File $CredentialFilePath
Connect-VIServer -Server $creds.Host -User $creds.User -Password $creds.Password -Force

#Function for updating the Resource VM Groups
function updateDrsVmGroup ($clusterName,$folderName,$groupVMName){
    $cluster = Get-Cluster -Name $clusterName
	$folder = Get-Folder -Name $folderName
    $spec = New-Object VMware.Vim.ClusterConfigSpecEx
    $groupVM = New-Object VMware.Vim.ClusterGroupSpec 
    #Operation edit will replace the contents of the GroupVMName with the new contents selected below.
    $groupVM.operation = "edit" 
    $groupVM.Info = New-Object VMware.Vim.ClusterVmGroup
    $groupVM.Info.Name = $groupVMName 
# Select VMs based on Folder Name 
    Get-Folder $folderName | get-vm | %{
        $groupVM.Info.VM += $_.Extensiondata.MoRef
    }
    $spec.GroupSpec += $groupVM
    #Apply the settings to the cluster
    $cluster.ExtensionData.ReconfigureComputeResource($spec,$true)
}
# Calling the function. Names are case sensitive.
Write-Output "Updating DRS Groups"
# Multiple folders can be combined in comma-separated format.... see examples below.
#updateDrsVmGroup ("ClusterName") ("FolderName") ("DRS VM Group Name")
#updateDrsVmGroup ("ClusterName") ("FolderName1", "FolderName2") ("DRS VM Group Name")
#updateDrsVmGroup ("Production` Cluster") ("VMware` Infrastructure") ("Group1")
#updateDrsVmGroup ("VDICluster") ("DesktopPool1") ("Site1VMs")
updateDrsVmGroup ("ManagementCluster") ("BackupServers") ("BackupGrp")
Disconnect-VIServer -Confirm:$False
}