######################################################################################################################
#
function InstallSoftware($url, $installDir, $displayName) {
    # Check if the software is already installed
    $installPath = Join-Path $installDir $displayName
    if (Test-Path -Path $installPath) {
        Write-Output "$displayName is already installed"
        return
    }

    Write-Output "Installing $displayName..."

    $downloadPath = Join-Path $env:TEMP (Split-Path -Leaf $url)
    if (-not (Test-Path -Path $downloadPath)) {
        Invoke-WebRequest -Uri $url -OutFile $downloadPath
    }

    if ($url -like "*.msi") {
        Start-Process -FilePath msiexec.exe -ArgumentList "/i `"$downloadPath`" /qn /norestart" -Wait
    }
    elseif ($displayName -eq "Audacity") {
        $exeArguments = "/VERYSILENT /NORESTART"
        Start-Process -FilePath $downloadPath -ArgumentList $exeArguments -Wait
    }
    elseif ($displayName -eq "Docker Desktop") {
        $exeArguments = "install", "--quiet", "--accept-license", "--installation-dir=C:\Program Files\Docker\Docker"
        Start-Process -FilePath $downloadPath -ArgumentList $exeArguments -Wait
    }
    elseif ($displayName -eq "Git") {
        $exeArguments = "/VERYSILENT", "/NORESTART"
        Start-Process -FilePath $downloadPath -ArgumentList $exeArguments -Wait
    }
    else {
        Start-Process -FilePath $downloadPath -ArgumentList "/S", "/D=`"$installDir`"" -Wait
    }

    # Check if the software was installed successfully
    if (Test-Path -Path $installPath) {
        Write-Output "$displayName was installed successfully"
    }
    else {
        Write-Output "continuing with next item..."
    }

    Remove-Item $downloadPath
}



#########################################################################################
# Define the URLs and installation directories for each software						#
$softwareList = Import-Csv -Path "softwarelist.csv"										#
foreach ($software in $softwareList) {													#
    $url = $software.Url																#
    $installDir = $software.InstallDir													#
    $displayName = $software.DisplayName												#
																						#
    InstallSoftware $url $installDir $displayName										#
}																						#
#########################################################################################



#########################################################################################
# Enable optional features [during test, these lines will not work in Windows Sandbox]	#
$featureNames = @(																		#
    "Containers",																		#
    "Microsoft-Hyper-V",																#
    "SMB1Protocol",																		#
    "TelnetClient",																		#
    "TFTP",																				#
    "Containers-DisposableClientVM",													#
    "VirtualMachinePlatform",															#
    "Microsoft-Windows-Subsystem-Linux"													#
)																						#
#########################################################################################	

foreach ($featureName in $featureNames) {
    Write-Output "Enabling feature: $featureName"
    Enable-WindowsOptionalFeature -Online -FeatureName $featureName -NoRestart
}
$userInfo = Import-Csv -Path "C:\users\WDAGUtilityAccount\user-info.csv"

foreach ($user in $userInfo) {
    # Check if the user account already exists
    if (Get-LocalUser -Name $user.Username -ErrorAction SilentlyContinue) {
        Write-Host "The user $($user.Username) already exists."
    }
    else {
        # Create the local user account
        New-LocalUser -Name $user.Username -Password (ConvertTo-SecureString "password" -AsPlainText -Force)
        
        # Set the user's privilege level
        if ($user.IsAdmin -eq "True") {
            Add-LocalGroupMember -Group "Administrators" -Member $user.Username
            Write-Host "The user $($user.Username) has been created as a local administrator."
        }
        else {
            Write-Host "The user $($user.Username) has been created as a standard user."
        }
    }
}
