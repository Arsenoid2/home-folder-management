# === Configuration ===
$GroupName    = "AcraStaff"
$HomeRoot     = "N:\Home"
$ArchiveRoot  = "N:\HomeArchive"
$LogFile      = "N:\Logs\HomeFolderManager.log"
$CsvLog       = "N:\Logs\HomeFolderAudit.csv"
$DaysToWait   = 1

# === Ensure log directory exists ===
$logDir = Split-Path $LogFile
if (-not (Test-Path $logDir)) {
    New-Item -Path $logDir -ItemType Directory | Out-Null
}

# === Create CSV headers if not exist ===
if (-not (Test-Path $CsvLog)) {
    "Timestamp,Username,Action,Details" | Out-File -FilePath $CsvLog -Encoding UTF8
}

# === Log helper function ===
function Write-Log {
    param (
        [string]$username,
        [string]$action,
        [string]$details
    )
    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $lineText  = "$timestamp [$username] $action - $details"
    Add-Content -Path $LogFile -Value $lineText
    "$timestamp,$username,$action,""$details""" | Out-File -FilePath $CsvLog -Append -Encoding UTF8
}

# === Import AD Module ===
Import-Module ActiveDirectory

# === Get group members ===
$users = Get-ADGroupMember -Identity $GroupName -Recursive | Where-Object { $_.objectClass -eq 'user' }

foreach ($user in $users) {
    $username      = $user.SamAccountName
    $userDetails   = Get-ADUser -Identity $username -Properties Enabled, WhenChanged
    $homeFolder    = Join-Path $HomeRoot $username
    $archiveFolder = Join-Path $ArchiveRoot $username

    # === Archive if user disabled for more than $DaysToWait days ===
    if (-not $userDetails.Enabled) {
        $disabledSince = $userDetails.WhenChanged
        $daysDisabled = (New-TimeSpan -Start $disabledSince -End (Get-Date)).Days

        if ($daysDisabled -ge $DaysToWait) {
            if ((Test-Path $homeFolder) -and (-not (Test-Path $archiveFolder))) {
                Move-Item -Path $homeFolder -Destination $archiveFolder
                Write-Log -username $username -action "Archived" -details "Moved to archive after $daysDisabled days disabled"
            } else {
                Write-Log -username $username -action "Skipped" -details "Already archived or no home folder"
            }
        } else {
            Write-Log -username $username -action "Pending" -details "User disabled but only $daysDisabled days ago"
        }

        continue
    }

    # === Active user: create home folder if needed ===
    if (-not (Test-Path $homeFolder)) {
        New-Item -Path $homeFolder -ItemType Directory | Out-Null

        # Set NTFS permissions
        $acl = Get-Acl $homeFolder
        $identity = "$($userDetails.SamAccountName)"
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "$identity", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
        )
        $acl.SetAccessRule($rule)
        Set-Acl $homeFolder $acl

        Write-Log -username $username -action "Created" -details "Folder created and permissions set"
    } else {
        Write-Log -username $username -action "Exists" -details "Home folder already present"
    }
}
