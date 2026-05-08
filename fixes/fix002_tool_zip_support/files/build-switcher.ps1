Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.Windows.Forms.Application]::EnableVisualStyles()

function Get-ScriptFolder {
    if ($PSScriptRoot -and (Test-Path $PSScriptRoot)) { return $PSScriptRoot }

    if ($PSCommandPath) {
        $p = Split-Path -Parent $PSCommandPath
        if ($p -and (Test-Path $p)) { return $p }
    }$ScriptRoot = $PSScriptRoot

    if ($MyInvocation.MyCommand.Definition) {
        $def = $MyInvocation.MyCommand.Definition
        if (Test-Path $def) { return (Split-Path -Parent $def) }
    }

    return (Get-Location).Path
}

function Find-RetroBatRoot {
    param([string]$StartPath)

    $current = Resolve-Path $StartPath -ErrorAction SilentlyContinue
    if (-not $current) { return $null }

    $currentPath = $current.Path

    while ($true) {
        $candidate = Join-Path $currentPath "emulationstation\.emulationstation\default-es_systems"

        if (Test-Path $candidate) {
            return $currentPath
        }

        $parent = Split-Path -Parent $currentPath
        if (-not $parent -or $parent -eq $currentPath) { break }

        $currentPath = $parent
    }

    return $null
}

$ScriptFolder = Get-ScriptFolder
$Base = Find-RetroBatRoot -StartPath $ScriptFolder

if (-not $Base) {
    [System.Windows.Forms.MessageBox]::Show(
        "Could not locate RetroBat root.`r`n`r`nStarted search from:`r`n$ScriptFolder`r`n`r`nExpected to find:`r`nemulationstation\.emulationstation\default-es_systems",
        "RetroBat Not Found",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit
}

$AppVersion = "v2.1"
$BackupRoot = Join-Path $ScriptFolder "backups"
$DefaultsRoot = Join-Path $ScriptFolder "defaults"
$LogRoot = Join-Path $ScriptFolder "logs"
$ManagerLog = Join-Path $LogRoot "manager.log"
$FixManagerLog = Join-Path $LogRoot "fix-manager.log"

$ActiveProfileFile = Join-Path $ScriptFolder "active-profile.txt"
$MasterProfilesRoot = Join-Path $ScriptFolder "master-profiles"

$FixManifestUrl = "https://raw.githubusercontent.com/tkssitch/Rickbat-Resources/main/fixes.json"
$FixRawBaseUrl = "https://raw.githubusercontent.com/tkssitch/Rickbat-Resources/main"
$InstalledFixesFile = Join-Path $ScriptFolder "installed-fixes.json"
$DownloadsRoot = Join-Path $ScriptFolder "downloads"
$FixBackupsRoot = Join-Path $ScriptFolder "fix-backups"

$DefaultSystemsRoot = Join-Path $Base "emulationstation\.emulationstation\default-es_systems"
$LiveConfig = Join-Path $Base "emulationstation\.emulationstation\es_settings.cfg"

$EsRoot = Join-Path $Base "emulationstation\.emulationstation"
$MusicDir = Join-Path $EsRoot "music"
$MusicFoldersDir = Join-Path $EsRoot "Music Folders"
$ThemesDir = Join-Path $EsRoot "themes"

$EsInputLive = Join-Path $EsRoot "es_input.cfg"
$EsInputDefault = Join-Path $EsRoot "es_input_default\es_input.cfg"

$RomsRoot = Join-Path $Base "roms"

$ToolsRoot = Join-Path $Base "system\tools"
$HookRoot = Join-Path $ToolsRoot "HookOfTheReaper"
$DependenciesRoot = Join-Path $ToolsRoot "Dependencies"
$RS3Root = Join-Path $ToolsRoot "RsCalibration"
$SindenRoot = Join-Path $ToolsRoot "sinden"

$InputMappingRoot = Join-Path $Base "system\resources\inputmapping"
$UserTemplatesRoot = Join-Path $InputMappingRoot "usertemplates"
$TeknoParrotUserTemplate = Join-Path $UserTemplatesRoot "teknoparrot.yml"
$TeknoParrotLive = Join-Path $InputMappingRoot "teknoparrot.yml"
$MameUserTemplateDir = Join-Path $UserTemplatesRoot "mame"
$MameLiveDir = Join-Path $InputMappingRoot "mame"

$EmulatorLauncherLog = Join-Path $Base "emulationstation\emulatorLauncher.log"
$RetroArchConfig = Join-Path $Base "emulators\retroarch\retroarch.cfg"
$RetroBatLog = Join-Path $Base "RetroBat.log"
$GamesDbTemplate = Join-Path $UserTemplatesRoot "resources\gamesdb.xml"
$GamesDbLive = Join-Path $Base "emulationstation\resources\gamesdb.xml"

$UrlLightgunLunatics = "https://www.facebook.com/groups/lightgunlunatics"
$UrlArcadeLunatics = "https://www.facebook.com/groups/arcadelunatics"
$UrlRetroRacingLunatics = "https://www.facebook.com/groups/retroracinglunatics"
$UrlRetroLunaticsDiscord = "https://discord.gg/QdNWB5aeTA"
$UrlRickbatSupportDiscord = "https://discord.gg/QHeKs2vWEH"
$UrlRetroLunaticsWebsite = "https://retrolunatics.com/default.asp"
$RetroBatExe = Join-Path $Base "RetroBat.exe"
$BatGuiExe = Join-Path $Base "BatGui.exe"

$StateFile = Join-Path $PSScriptRoot "manager-state.json"

$PerformanceGamelists = @(
    @{
        Name    = "vpinball"
        Live    = (Join-Path $Base "roms\vpinball\gamelist.xml")
        Default = (Join-Path $DefaultsRoot "roms\vpinball\gamelist.xml")
    },
    @{
        Name    = "quake"
        Live    = (Join-Path $Base "roms\quake\gamelist.xml")
        Default = (Join-Path $DefaultsRoot "roms\quake\gamelist.xml")
    },
    @{
        Name    = "quake2"
        Live    = (Join-Path $Base "roms\quake2\gamelist.xml")
        Default = (Join-Path $DefaultsRoot "roms\quake2\gamelist.xml")
    },
    @{
        Name    = "teknoparrot"
        Live    = (Join-Path $Base "roms\teknoparrot\gamelist.xml")
        Default = (Join-Path $DefaultsRoot "roms\teknoparrot\gamelist.xml")
    }
)

function Load-ManagerState {
    if (Test-Path $StateFile) {
        try {
            return Get-Content $StateFile -Raw | ConvertFrom-Json
        }
        catch {
            return [PSCustomObject]@{
                LastBuildPreset = ""
                LastMusicPreset = ""
                LastUpdated = ""
            }
        }
    }

    return [PSCustomObject]@{
        LastBuildPreset = ""
        LastMusicPreset = ""
        LastUpdated = ""
    }
}

function Save-ManagerState {
    param(
        [string]$BuildPreset,
        [string]$MusicPreset
    )

    $oldState = Load-ManagerState

    if ([string]::IsNullOrWhiteSpace($BuildPreset)) {
        $BuildPreset = $oldState.LastBuildPreset
    }

    if ([string]::IsNullOrWhiteSpace($MusicPreset)) {
        $MusicPreset = $oldState.LastMusicPreset
    }

    $newState = [PSCustomObject]@{
        LastBuildPreset = $BuildPreset
        LastMusicPreset = $MusicPreset
        LastUpdated = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    }

    $newState | ConvertTo-Json | Set-Content -Path $StateFile -Encoding UTF8
}

$script:CurrentMusicSelectionState = "None"
$script:form = $null
$script:cardBuilds = $null
$script:groupMusic = $null
$script:statusLabel = $null
$script:labelCurrent = $null
$script:labelMusic = $null
$script:labelBase = $null
$script:labelScript = $null
$script:checkAutoClose = $null
$script:checkBackup = $null
$script:labelFixGlobal = $null
$script:labelFixStatus = $null
$script:labelFixCurrent = $null
$script:progressFix = $null

$tooltip = New-Object System.Windows.Forms.ToolTip
$tooltip.AutoPopDelay = 5000
$tooltip.InitialDelay = 500
$tooltip.ReshowDelay = 200
$tooltip.ShowAlways = $true

function Show-Message {
    param(
        [string]$Text,
        [string]$Title = "Uncle Rick's RetroBat Manager",
        [System.Windows.Forms.MessageBoxIcon]$Icon = [System.Windows.Forms.MessageBoxIcon]::Information
    )

    [System.Windows.Forms.MessageBox]::Show(
        $Text,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $Icon
    ) | Out-Null
}

function Open-FolderSafe {
    param(
        [string]$Path,
        [string]$Label = "Folder"
    )

    if (Test-Path $Path) {
        Start-Process explorer.exe $Path
        if ($script:statusLabel) { $script:statusLabel.Text = "Opened: $Label" }
    }
    else {
        Show-Message "$Label not found:`r`n$Path" "Missing Folder" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}

function Ensure-ManagerFolders {
    $folders = @(
    	$BackupRoot,
    	$DefaultsRoot,
    	$MasterProfilesRoot,
    	$LogRoot,
    	$DownloadsRoot,
    	$FixBackupsRoot,
        (Join-Path $DefaultsRoot "roms"),
        (Join-Path $DefaultsRoot "roms\vpinball"),
        (Join-Path $DefaultsRoot "roms\quake"),
        (Join-Path $DefaultsRoot "roms\quake2"),
        (Join-Path $DefaultsRoot "roms\teknoparrot"),
        (Join-Path $UserTemplatesRoot "resources")
    )

    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            New-Item -ItemType Directory -Path $folder -Force | Out-Null
        }
    }
}

function Write-ManagerLog {
    param([string]$Message)

    try {
        if (-not (Test-Path $LogRoot)) {
            New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
        }

        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $ManagerLog -Value "$stamp - $Message" -Encoding UTF8
    }
    catch {
        # Logging should never break the tool
    }
}

function Set-LastAction {
    param([string]$Message)

    if ($script:statusLabel) {
        $script:statusLabel.Text = "Last Action: $Message"
    }

    Write-ManagerLog $Message
}

function Write-FixLog {
    param([string]$Message)

    try {
        if (-not (Test-Path $LogRoot)) {
            New-Item -ItemType Directory -Path $LogRoot -Force | Out-Null
        }

        $stamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Add-Content -Path $FixManagerLog -Value "$stamp - $Message" -Encoding UTF8
    }
    catch {
        # Fix logging should never break the tool
    }
}

function Set-FixStatus {
    param(
        [string]$Status,
        [string]$Current = "",
        [int]$Percent = -1
    )

    if ($script:labelFixGlobal) {
        $script:labelFixGlobal.Text = $Status
    }

    if ($script:labelFixStatus) {
        $script:labelFixStatus.Text = $Status
    }

    if ($script:labelFixCurrent) {
        $script:labelFixCurrent.Text = $Current
    }

    if ($script:progressFix -and $Percent -ge 0) {
        if ($Percent -lt 0) { $Percent = 0 }
        if ($Percent -gt 100) { $Percent = 100 }
        $script:progressFix.Value = $Percent
    }

    if ($script:statusLabel) {
        $script:statusLabel.Text = $Status
    }

    [System.Windows.Forms.Application]::DoEvents()
}

function Read-InstalledFixes {
    $installed = @{}

    if (-not (Test-Path $InstalledFixesFile)) {
        return $installed
    }

    try {
        $json = Get-Content -Path $InstalledFixesFile -Raw -Encoding UTF8 | ConvertFrom-Json

        if ($json.installed -is [System.Management.Automation.PSCustomObject]) {
            foreach ($prop in $json.installed.PSObject.Properties) {
                $installed[$prop.Name] = [string]$prop.Value
            }
        }
        elseif ($json.installed -is [array]) {
            foreach ($id in $json.installed) {
                $installed[[string]$id] = "installed"
            }
        }
    }
    catch {
        Write-FixLog "Failed reading installed fixes: $($_.Exception.Message)"
    }

    return $installed
}

function Save-InstalledFixes {
    param([hashtable]$InstalledMap)

    try {
        if (-not (Test-Path $ScriptFolder)) {
            New-Item -ItemType Directory -Path $ScriptFolder -Force | Out-Null
        }

        $ordered = [ordered]@{}

        foreach ($key in ($InstalledMap.Keys | Sort-Object)) {
            $ordered[$key] = $InstalledMap[$key]
        }

        $data = [ordered]@{
            installed = $ordered
        }

        $data | ConvertTo-Json -Depth 10 | Set-Content -Path $InstalledFixesFile -Encoding UTF8
    }
    catch {
        Write-FixLog "Failed saving installed fixes: $($_.Exception.Message)"
        throw
    }
}

function Mark-FixInstalled {
    param($Fix)

    $installed = Read-InstalledFixes
    $installed[[string]$Fix.id] = [string]$Fix.version
    Save-InstalledFixes -InstalledMap $installed

    Write-FixLog "Marked installed: $($Fix.id) v$($Fix.version)"
}

function Get-RickBatFixManifest {
    try {
        Write-FixLog "Downloading manifest: $FixManifestUrl"
        $manifest = Invoke-RestMethod -Uri $FixManifestUrl -UseBasicParsing -TimeoutSec 8
        return $manifest
    }
    catch {
        Write-FixLog "Failed downloading manifest: $($_.Exception.Message)"
        throw "Could not download fixes.json from GitHub.`r`n`r`n$($_.Exception.Message)"
    }
}

function Get-MissingRickBatFixes {
    param($Manifest)

    $installed = Read-InstalledFixes
    $missing = @()

    foreach ($fix in $Manifest.fixes) {
        $id = [string]$fix.id
        $version = [string]$fix.version

        if (-not $installed.ContainsKey($id)) {
            $missing += $fix
            continue
        }

        if ([string]$installed[$id] -ne $version) {
            $missing += $fix
            continue
        }
    }

    return $missing
}

function Test-FixRequirements {
    param($Fix)

    $installed = Read-InstalledFixes

    if (-not ($Fix.PSObject.Properties.Name -contains "requires")) {
        return $true
    }

    foreach ($requiredFix in $Fix.requires) {
        $requiredId = [string]$requiredFix

        if (-not $installed.ContainsKey($requiredId)) {
            throw "Fix $($Fix.id) requires missing fix: $requiredId"
        }
    }

    return $true
}

function Backup-FixTarget {
    param(
        [string]$FixId,
        [string]$TargetPath
    )

    if (-not (Test-Path $TargetPath)) {
        Write-FixLog "No backup needed. Target does not exist yet: $TargetPath"
        return ""
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $backupFolder = Join-Path $FixBackupsRoot "$FixId\$timestamp"

    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    }

    $backupFile = Join-Path $backupFolder (Split-Path $TargetPath -Leaf)

    Copy-Item -Path $TargetPath -Destination $backupFile -Force
    Write-FixLog "Backup created: $backupFile"

    return $backupFile
}

function Backup-FixTargetRelative {
    param(
        [string]$FixId,
        [string]$TargetPath,
        [string]$RelativePath,
        [string]$Timestamp
    )

    if (-not (Test-Path $TargetPath)) {
        Write-FixLog "No backup needed. Target does not exist yet: $TargetPath"
        return ""
    }

    $safeRelative = $RelativePath -replace "/", "\"
    $backupFile = Join-Path (Join-Path $FixBackupsRoot "$FixId\$Timestamp") $safeRelative
    $backupFolder = Split-Path -Parent $backupFile

    if (-not (Test-Path $backupFolder)) {
        New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    }

    Copy-Item -Path $TargetPath -Destination $backupFile -Force
    Write-FixLog "Backup created: $backupFile"

    return $backupFile
}

function Install-RickBatFix {
    param($Fix)

    $fixId = [string]$Fix.id
    $fixName = [string]$Fix.name
    $fixType = [string]$Fix.type

    Write-FixLog "Preparing fix: $fixId - $fixName"
    Test-FixRequirements -Fix $Fix | Out-Null

    $sourceRelative = ([string]$Fix.source) -replace "\\", "/"
    $sourceUrl = "$FixRawBaseUrl/$sourceRelative"

    if (-not (Test-Path $DownloadsRoot)) {
        New-Item -ItemType Directory -Path $DownloadsRoot -Force | Out-Null
    }

    $downloadFileName = "$fixId`_" + (Split-Path $sourceRelative -Leaf)
    $downloadPath = Join-Path $DownloadsRoot $downloadFileName

    Write-FixLog "Download source: $sourceUrl"
    Set-FixStatus "RickBat Updates: Downloading $fixName" "Downloading: $fixId"

    Invoke-WebRequest -Uri $sourceUrl -OutFile $downloadPath -UseBasicParsing

    if (-not (Test-Path $downloadPath)) {
        throw "Download failed. File was not created: $downloadPath"
    }

    $downloadSize = (Get-Item $downloadPath).Length

    if ($downloadSize -le 0) {
        throw "Downloaded file is empty: $downloadPath"
    }

    Write-FixLog "Downloaded file: $downloadPath ($downloadSize bytes)"

    if ($fixType -eq "file_replace") {
        $targetRelative = ([string]$Fix.target) -replace "/", "\"

        if (-not $targetRelative) {
            throw "file_replace fix is missing target path: $fixId"
        }

        $targetPath = Join-Path $Base $targetRelative
        $targetFolder = Split-Path -Parent $targetPath

        Write-FixLog "Install target: $targetPath"

        if (-not (Test-Path $targetFolder)) {
            New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
        }

        if ($Fix.backup -eq $true) {
            Backup-FixTarget -FixId $fixId -TargetPath $targetPath | Out-Null
        }

        Set-FixStatus "RickBat Updates: Installing $fixName" "Installing: $targetRelative"

        Copy-Item -Path $downloadPath -Destination $targetPath -Force

        if (-not (Test-Path $targetPath)) {
            throw "Install failed. Target file was not created: $targetPath"
        }

        Mark-FixInstalled -Fix $Fix
        Write-FixLog "Installed file_replace fix successfully: $fixId - $fixName"
        return
    }

    if ($fixType -eq "zip_extract") {
        Set-FixStatus "RickBat Updates: Extracting $fixName" "Extracting ZIP relative to RetroBat root"

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $baseFullPath = [System.IO.Path]::GetFullPath($Base)

        $zip = $null

        try {
            $zip = [System.IO.Compression.ZipFile]::OpenRead($downloadPath)

            foreach ($entry in $zip.Entries) {
                if ([string]::IsNullOrWhiteSpace($entry.Name)) {
                    continue
                }

                $relativePath = $entry.FullName -replace "/", "\"

                if ($relativePath.StartsWith("\") -or $relativePath.Contains("..\")) {
                    throw "Unsafe ZIP path blocked: $relativePath"
                }

                $targetPath = Join-Path $Base $relativePath
                $targetFullPath = [System.IO.Path]::GetFullPath($targetPath)

                if (-not $targetFullPath.StartsWith($baseFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe ZIP target blocked: $targetFullPath"
                }

                Write-FixLog "ZIP entry target: $targetFullPath"

                if ($Fix.backup -eq $true) {
                    Backup-FixTargetRelative -FixId $fixId -TargetPath $targetFullPath -RelativePath $relativePath -Timestamp $timestamp | Out-Null
                }
            }

            foreach ($entry in $zip.Entries) {
                if ([string]::IsNullOrWhiteSpace($entry.Name)) {
                    continue
                }

                $relativePath = $entry.FullName -replace "/", "\"

                if ($relativePath.StartsWith("\") -or $relativePath.Contains("..\")) {
                    throw "Unsafe ZIP path blocked: $relativePath"
                }

                $targetPath = Join-Path $Base $relativePath
                $targetFullPath = [System.IO.Path]::GetFullPath($targetPath)

                if (-not $targetFullPath.StartsWith($baseFullPath, [System.StringComparison]::OrdinalIgnoreCase)) {
                    throw "Unsafe ZIP target blocked: $targetFullPath"
                }

                $targetFolder = Split-Path -Parent $targetFullPath

                if (-not (Test-Path $targetFolder)) {
                    New-Item -ItemType Directory -Path $targetFolder -Force | Out-Null
                }

                [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $targetFullPath, $true)
                Write-FixLog "Extracted ZIP file: $targetFullPath"
            }
        }
        finally {
            if ($zip) {
                $zip.Dispose()
            }
        }

        Mark-FixInstalled -Fix $Fix
        Write-FixLog "Installed zip_extract fix successfully: $fixId - $fixName"
        return
    }

    throw "Unsupported fix type: $fixType"
}

function Check-RickBatFixes {
    try {
        Set-FixStatus "RickBat Fixes: Checking..." "Downloading fixes.json from GitHub..." 5

        $manifest = Get-RickBatFixManifest
        $missing = @(Get-MissingRickBatFixes -Manifest $manifest)

        $total = @($manifest.fixes).Count
        $missingCount = $missing.Count
        $installedCount = $total - $missingCount

        if ($missingCount -eq 0) {
            Set-FixStatus "RickBat Fixes: $installedCount / $total installed" "RickBat Lite is up to date." 100
            Show-Message "RickBat Lite fixes are up to date.`r`n`r`nInstalled: $installedCount / $total" "Fix Check Complete" ([System.Windows.Forms.MessageBoxIcon]::Information)
      	  }
        	else {
            	    $percent = 0
	if ($total -gt 0) {
    	$percent = [int](($installedCount / $total) * 100)
	}
	Set-FixStatus "RickBat Fixes: $installedCount / $total installed" "$missingCount update(s) available." $percent
            Show-Message "$missingCount RickBat fix update(s) available.`r`n`r`nInstalled: $installedCount / $total" "Fixes Available" ([System.Windows.Forms.MessageBoxIcon]::Information)
        }

        Write-FixLog "Check complete. Installed: $installedCount / $total. Missing: $missingCount"
    }
    catch {
        Set-FixStatus "RickBat Fixes: Check failed" $_.Exception.Message 0
        Show-Message "Fix check failed.`r`n`r`n$($_.Exception.Message)" "Fix Check Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
        Write-FixLog "Fix check failed: $($_.Exception.Message)"
    }
}

function Check-RickBatFixesSilent {
    try {
        Set-FixStatus "RickBat Fixes: Checking online..." "Checking GitHub for RickBat fixes..." 5

        $manifest = Get-RickBatFixManifest

        if (-not $manifest -or -not ($manifest.PSObject.Properties.Name -contains "fixes")) {
            throw "Fix manifest did not contain a fixes list."
        }

        $missing = @(Get-MissingRickBatFixes -Manifest $manifest)

        $total = @($manifest.fixes).Count
        $missingCount = $missing.Count
        $installedCount = $total - $missingCount

        if ($total -le 0) {
            Set-FixStatus "RickBat Fixes: No fixes listed" "Connected, but no fixes were listed in fixes.json." 0
            Write-FixLog "Startup check complete. Manifest had no fixes."
            return
        }

        if ($missingCount -eq 0) {
            Set-FixStatus "RickBat Fixes: Up to date ($installedCount / $total)" "RickBat Lite is up to date." 100
        }
	else {
    	  $percent = [int](($installedCount / $total) * 100)
    	  Set-FixStatus "RickBat Fixes: $missingCount update(s) available" "$installedCount / $total installed. Click Update RickBat Fixes." $percent
	}

        Write-FixLog "Startup fix check complete. Installed: $installedCount / $total. Missing: $missingCount"
    }
    catch {
        Set-FixStatus "RickBat Fixes: No online connection" "Could not check GitHub. Check internet connection or GitHub access." 0
        Write-FixLog "Startup fix check failed: $($_.Exception.Message)"
    }
}

function Update-RickBatFixes {
    try {
        Set-FixStatus "RickBat Fixes: Checking..." "Checking GitHub manifest..." 5
        Write-FixLog "Starting RickBat fix update"

        $manifest = Get-RickBatFixManifest
        $missing = @(Get-MissingRickBatFixes -Manifest $manifest)

        $total = @($manifest.fixes).Count

        if ($missing.Count -eq 0) {
            Set-FixStatus "RickBat Fixes: $total / $total installed" "RickBat Lite is already up to date." 100
            Show-Message "No missing fixes found.`r`n`r`nRickBat Lite is already up to date." "No Updates Needed" ([System.Windows.Forms.MessageBoxIcon]::Information)
            Write-FixLog "No missing fixes found"
            return
        }

        $installedNow = 0
        $failedCount = 0

        for ($i = 0; $i -lt $missing.Count; $i++) {
            $fix = $missing[$i]
            $fixNumber = $i + 1

            $startPercent = [int]((($fixNumber - 1) / $missing.Count) * 100)
	    Set-FixStatus "RickBat Fixes: Installing $fixNumber of $($missing.Count)" "$($fix.name)" $startPercent

            try {
                Install-RickBatFix -Fix $fix
		$donePercent = [int](($fixNumber / $missing.Count) * 100)
                Set-FixStatus "RickBat Fixes: Installed $fixNumber of $($missing.Count)" "$($fix.name)" $donePercent
                $installedNow++
            }
            catch {
                $failedCount++
                Write-FixLog "Failed installing fix $($fix.id): $($_.Exception.Message)"
                throw "Failed installing fix:`r`n$($fix.name)`r`n`r`n$($_.Exception.Message)"
            }
        }

        $manifestAfter = Get-RickBatFixManifest
        $missingAfter = @(Get-MissingRickBatFixes -Manifest $manifestAfter)
        $totalAfter = @($manifestAfter.fixes).Count
        $installedAfter = $totalAfter - $missingAfter.Count

        Set-FixStatus "RickBat Fixes: $installedAfter / $totalAfter installed" "Update complete." 100

        Show-Message "RickBat fixes installed successfully.`r`n`r`nInstalled now: $installedNow`r`nFailed: $failedCount`r`nCurrent status: $installedAfter / $totalAfter installed" "Fix Update Complete" ([System.Windows.Forms.MessageBoxIcon]::Information)

        Write-FixLog "Update complete. Installed now: $installedNow. Failed: $failedCount. Current status: $installedAfter / $totalAfter"
    }
    catch {
        Set-FixStatus "RickBat Fixes: Update failed" $_.Exception.Message 0
        Show-Message "RickBat fix update failed.`r`n`r`n$($_.Exception.Message)" "Fix Update Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
        Write-FixLog "Update failed: $($_.Exception.Message)"
    }
}

function Open-FileSafe {
    param(
        [string]$Path,
        [string]$Label = "File"
    )

    if (Test-Path $Path) {
        Start-Process -FilePath $Path
        if ($script:statusLabel) { $script:statusLabel.Text = "Opened: $Label" }
    }
    else {
        Show-Message "File not found:`r`n$Path" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Warning)
    }
}

function Open-LinkSafe {
    param(
        [string]$Url,
        [string]$Label = "Link"
    )

    try {
        Start-Process $Url
        if ($script:statusLabel) { $script:statusLabel.Text = "Opened: $Label" }
    }
    catch {
        Show-Message "Failed to open link:`r`n$Url`r`n`r`n$($_.Exception.Message)" "Link Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}
function Get-BuildFolders {
    if (-not (Test-Path $DefaultSystemsRoot)) { return @() }

    return Get-ChildItem -Path $DefaultSystemsRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "es_settings.cfg") } |
        Sort-Object Name
}

function Get-BuildSourcePath {
    param([string]$BuildType)
    return (Join-Path $DefaultSystemsRoot "$BuildType\es_settings.cfg")
}

function Get-CurrentBuild {
    if (-not (Test-Path $LiveConfig)) { return "Live config missing" }

    $buildFolders = Get-BuildFolders
    if (-not $buildFolders -or $buildFolders.Count -eq 0) { return "No build folders found" }

    try {
        $liveHash = (Get-FileHash -Path $LiveConfig -Algorithm SHA256).Hash

        foreach ($folder in $buildFolders) {
            $src = Join-Path $folder.FullName "es_settings.cfg"
            if (Test-Path $src) {
                $srcHash = (Get-FileHash -Path $src -Algorithm SHA256).Hash

                if ($liveHash -eq $srcHash) {
                    return $folder.Name
                }
            }
        }
    }
    catch {
        return "Unknown"
    }

    return "Custom / Unknown"
}

function Get-MusicFolders {
    $names = @()

    if (Test-Path $MusicFoldersDir) {
        $names += Get-ChildItem -Path $MusicFoldersDir -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name
    }

    if (Test-Path $MusicDir) {
        $names += Get-ChildItem -Path $MusicDir -Directory -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty Name
    }

    return $names | Sort-Object -Unique
}

function Get-CurrentMusicSelection {
    if ($script:CurrentMusicSelectionState -and $script:CurrentMusicSelectionState -ne "None") {
        return $script:CurrentMusicSelectionState
    }

    if (-not (Test-Path $MusicDir)) { return "None" }

$liveFolders = @(Get-ChildItem -Path $MusicDir -Directory -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty Name)

    if ($liveFolders.Count -eq 1) { return $liveFolders[0] }
    if ($liveFolders.Count -gt 1) { return "Multiple / Grouped" }

    return "None"
}

function Move-AllLiveMusicToStorage {
    if (-not (Test-Path $MusicDir)) {
        throw "music folder not found: $MusicDir"
    }

    if (-not (Test-Path $MusicFoldersDir)) {
        New-Item -ItemType Directory -Path $MusicFoldersDir -Force | Out-Null
    }

    $liveFolders = Get-ChildItem -Path $MusicDir -Directory -ErrorAction SilentlyContinue

    foreach ($folder in $liveFolders) {
        $destPath = Join-Path $MusicFoldersDir $folder.Name

        if (Test-Path $destPath) {
            Remove-Item -Path $destPath -Recurse -Force -ErrorAction Stop
        }

        Move-Item -Path $folder.FullName -Destination $MusicFoldersDir -Force -ErrorAction Stop
    }
}

function Refresh-MusicButtons {
    if (-not $script:groupMusic) { return }

    $script:groupMusic.Controls.Clear()

    $musicTitleLabel = New-UiLabel "Music Selections" 14 10 580 24 10 ([System.Drawing.FontStyle]::Bold) $ColorAccent
    $script:groupMusic.Controls.Add($musicTitleLabel)

    $musicFolders = Get-MusicFolders
    $currentMusicName = Get-CurrentMusicSelection

    if (-not $musicFolders -or $musicFolders.Count -eq 0) {
        $noMusicLabel = New-Object System.Windows.Forms.Label
        $noMusicLabel.Text = "No music folders were found in:`r`n$MusicFoldersDir`r`nor`r`n$MusicDir"
        $noMusicLabel.Location = New-Object System.Drawing.Point(18, 45)
        $noMusicLabel.Size = New-Object System.Drawing.Size(560, 60)
        $noMusicLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
        $noMusicLabel.ForeColor = $ColorMuted
        $noMusicLabel.BackColor = [System.Drawing.Color]::Transparent
        $script:groupMusic.Controls.Add($noMusicLabel)
        return
    }

    $buttonWidth = 180
    $buttonHeight = 42
    $startX = 18
    $startY = 48
    $spacingX = 18
    $spacingY = 14
    $maxCols = 3

    for ($i = 0; $i -lt $musicFolders.Count; $i++) {
        $name = $musicFolders[$i]
        $col = $i % $maxCols
        $row = [math]::Floor($i / $maxCols)

        $x = $startX + (($buttonWidth + $spacingX) * $col)
        $y = $startY + (($buttonHeight + $spacingY) * $row)

        $btn = New-PremiumButton $name $x $y $buttonWidth $buttonHeight {
            param($sender, $eventArgs)
            Apply-MusicFolder $sender.Tag
        } "Activates this music selection using move-based switching."

        $btn.Tag = $name

        if ($name -eq $currentMusicName) {
            Set-PremiumButtonState -Button $btn -Active $true
}

$script:groupMusic.Controls.Add($btn)
    }
}

function Apply-MusicFolder {
    param([string]$MusicName)

    if ((Get-CurrentMusicSelection) -eq $MusicName) {
        $script:statusLabel.Text = "Music already active: $MusicName"
        return
    }

    $selectedRootStorage = Join-Path $MusicFoldersDir $MusicName
    $selectedRootLive = Join-Path $MusicDir $MusicName

    if (Test-Path $selectedRootStorage) {
        $selectedRoot = $selectedRootStorage
        $selectedFromLive = $false
    }
    elseif (Test-Path $selectedRootLive) {
        $selectedRoot = $selectedRootLive
        $selectedFromLive = $true
    }
    else {
        Show-Message "Music folder not found:`r`n$MusicName" "Missing Folder" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        Move-AllLiveMusicToStorage

        if ($selectedFromLive) {
            $selectedRoot = Join-Path $MusicFoldersDir $MusicName
        }

        $selectedChildren = Get-ChildItem -Path $selectedRoot -Directory -ErrorAction SilentlyContinue

        if ($selectedChildren.Count -eq 0) {
            $destPath = Join-Path $MusicDir $MusicName

            if (Test-Path $destPath) {
                Remove-Item -Path $destPath -Recurse -Force -ErrorAction Stop
            }

            Move-Item -Path $selectedRoot -Destination $MusicDir -Force -ErrorAction Stop
        }
        else {
            foreach ($child in $selectedChildren) {
                $destPath = Join-Path $MusicDir $child.Name

                if (Test-Path $destPath) {
                    Remove-Item -Path $destPath -Recurse -Force -ErrorAction Stop
                }

                Move-Item -Path $child.FullName -Destination $MusicDir -Force -ErrorAction Stop
            }

            if (-not (Test-Path $selectedRoot)) {
                New-Item -ItemType Directory -Path $selectedRoot -Force | Out-Null
            }
        }

	$script:CurrentMusicSelectionState = $MusicName
	Save-ManagerState -BuildPreset "" -MusicPreset $MusicName

	Set-LastAction "Applied music: $MusicName"
	Update-Status
	Refresh-MusicButtons

        Show-Message "$MusicName music selection applied successfully." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)

        if ($script:checkAutoClose.Checked) {
            $script:form.Close()
        }
    }
    catch {
        $script:statusLabel.Text = "Music apply failed"
        Show-Message "Failed to apply music selection.`r`n`r`n$($_.Exception.Message)" "Music Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Get-EsSettingsContent {
    if (-not (Test-Path $LiveConfig)) {
        throw "File not found: $LiveConfig"
    }

    return Get-Content -Path $LiveConfig -Raw -Encoding UTF8
}

function Save-EsSettingsContent {
    param([string]$Content)
    Set-Content -Path $LiveConfig -Value $Content -Encoding UTF8
}

function Update-AllProfileEsSettings {
    param(
        [ValidateSet("LowEnd", "MidHigh")]
        [string]$Mode
    )

    $profileFolders = Get-BuildFolders

    foreach ($folder in $profileFolders) {
        $profileConfig = Join-Path $folder.FullName "es_settings.cfg"

        if (-not (Test-Path $profileConfig)) {
            continue
        }

        try {
            $content = Get-Content -Path $profileConfig -Raw -Encoding UTF8

            if ($Mode -eq "LowEnd") {
                $content = Set-Or-Add-EsSetting -Content $content -Name "global.video_driver" -Value "gl"
                $content = Set-Or-Add-EsSetting -Content $content -Name "mame.mame_video_driver" -Value "opengl"
            }
            elseif ($Mode -eq "MidHigh") {
                $content = Remove-EsSetting -Content $content -Name "global.video_driver"
                $content = Remove-EsSetting -Content $content -Name "mame.mame_video_driver"
            }

            Set-Content -Path $profileConfig -Value $content -Encoding UTF8
            Write-ManagerLog "Updated profile es_settings.cfg for $($folder.Name): $Mode"
        }
        catch {
            Write-ManagerLog "Failed updating profile $($folder.Name): $($_.Exception.Message)"
        }
    }
}

function Get-EsSettingValueFromFile {
    param(
        [string]$Path,
        [string]$Name
    )

    if (-not (Test-Path $Path)) {
        return $null
    }

    try {
        $content = Get-Content -Path $Path -Raw -Encoding UTF8
        $escapedName = [regex]::Escape($Name)

        $pattern = '<string\s+name\s*=\s*"' + $escapedName + '"\s+value\s*=\s*"([^"]*)"\s*/>'

        if ($content -match $pattern) {
            return $matches[1]
        }
    }
    catch {
        Write-ManagerLog "Failed reading setting $Name from $Path`: $($_.Exception.Message)"
    }

    return $null
}

function Sync-NetplayNicknameAcrossProfiles {
    $settingName = "global.netplay.nickname"
    $nickname = Get-EsSettingValueFromFile -Path $LiveConfig -Name $settingName

    if ($null -eq $nickname) {
        Write-ManagerLog "Skipped netplay nickname sync: setting not found in live es_settings.cfg"
        return
    }

    $profileFolders = Get-BuildFolders
    $updatedCount = 0

    foreach ($folder in $profileFolders) {
        $profileConfig = Join-Path $folder.FullName "es_settings.cfg"

        if (-not (Test-Path $profileConfig)) {
            continue
        }

        try {
            $content = Get-Content -Path $profileConfig -Raw -Encoding UTF8
            $content = Set-Or-Add-EsSetting -Content $content -Name $settingName -Value $nickname
            Set-Content -Path $profileConfig -Value $content -Encoding UTF8

            $updatedCount++
        }
        catch {
            Write-ManagerLog "Failed syncing netplay nickname to $($folder.Name): $($_.Exception.Message)"
        }
    }

    Write-ManagerLog "Synced netplay nickname across profiles: $nickname ($updatedCount profiles)"
}

function Set-Or-Add-EsSetting {
    param(
        [string]$Content,
        [string]$Name,
        [string]$Value
    )

    $escapedName = [regex]::Escape($Name)
    $pattern = "<string\s+name=`"$escapedName`"\s+value=`"[^`"]*`"\s*/>"

    if ($Content -match $pattern) {
        return [regex]::Replace(
            $Content,
            $pattern,
            "<string name=`"$Name`" value=`"$Value`" />",
            1
        )
    }

    $insertLine = "    <string name=`"$Name`" value=`"$Value`" />`r`n"

    if ($Content -match "</config>") {
        return $Content -replace "</config>", ($insertLine + "</config>")
    }

    return $Content + "`r`n" + $insertLine
}

function Remove-EsSetting {
    param(
        [string]$Content,
        [string]$Name
    )

    $escapedName = [regex]::Escape($Name)
    $pattern = "^\s*<string\s+name=`"$escapedName`"\s+value=`"[^`"]*`"\s*/>\s*\r?\n?"

    return [regex]::Replace($Content, $pattern, "", [System.Text.RegularExpressions.RegexOptions]::Multiline)
}
function Get-XmlNodeKey {
    param($Node)

    if ($null -eq $Node) { return $null }

    $pathNode = $Node.SelectSingleNode("path")
    if ($pathNode -and $pathNode.InnerText) {
        return "path::" + $pathNode.InnerText.Trim()
    }

    $nameNode = $Node.SelectSingleNode("name")
    if ($nameNode -and $nameNode.InnerText) {
        return "name::" + $nameNode.InnerText.Trim()
    }

    return $null
}

function Restore-HiddenStatesFromDefault {
    param(
        [string]$LivePath,
        [string]$DefaultPath
    )

    if (-not (Test-Path $LivePath)) {
        throw "Live gamelist not found: $LivePath"
    }

    if (-not (Test-Path $DefaultPath)) {
        throw "Default gamelist not found: $DefaultPath"
    }

    [xml]$liveXml = Get-Content -Path $LivePath -Raw -Encoding UTF8
    [xml]$defaultXml = Get-Content -Path $DefaultPath -Raw -Encoding UTF8

    $defaultHiddenKeys = @{}

    foreach ($node in $defaultXml.DocumentElement.ChildNodes) {
        if ($node.NodeType -ne [System.Xml.XmlNodeType]::Element) { continue }

        $key = Get-XmlNodeKey -Node $node
        if (-not $key) { continue }

        $hiddenNode = $node.SelectSingleNode("hidden")
        if ($hiddenNode -and $hiddenNode.InnerText.Trim().ToLower() -eq "true") {
            $defaultHiddenKeys[$key] = $true
        }
    }

    foreach ($node in $liveXml.DocumentElement.ChildNodes) {
        if ($node.NodeType -ne [System.Xml.XmlNodeType]::Element) { continue }

        $key = Get-XmlNodeKey -Node $node
        if (-not $key) { continue }

        if ($defaultHiddenKeys.ContainsKey($key)) {
            $hiddenNode = $node.SelectSingleNode("hidden")

            if ($hiddenNode) {
                $hiddenNode.InnerText = "true"
            }
            else {
                $newHidden = $liveXml.CreateElement("hidden")
                $newHidden.InnerText = "true"
                [void]$node.AppendChild($newHidden)
            }
        }
    }

    $liveXml.Save($LivePath)
}

function Set-AllHiddenTrueToFalse {
    param([string]$LivePath)

    if (-not (Test-Path $LivePath)) {
        throw "Live gamelist not found: $LivePath"
    }

    [xml]$liveXml = Get-Content -Path $LivePath -Raw -Encoding UTF8

    foreach ($node in $liveXml.DocumentElement.ChildNodes) {
        if ($node.NodeType -ne [System.Xml.XmlNodeType]::Element) { continue }

        $hiddenNode = $node.SelectSingleNode("hidden")
        if ($hiddenNode -and $hiddenNode.InnerText.Trim().ToLower() -eq "true") {
            $hiddenNode.InnerText = "false"
        }
    }

    $liveXml.Save($LivePath)
}

function Set-LowEndPerformance {
    try {
        $content = Get-EsSettingsContent
        $content = Set-Or-Add-EsSetting -Content $content -Name "global.video_driver" -Value "gl"
        $content = Set-Or-Add-EsSetting -Content $content -Name "mame.mame_video_driver" -Value "opengl"
        Save-EsSettingsContent -Content $content

        Update-AllProfileEsSettings -Mode "LowEnd"  

        foreach ($entry in $PerformanceGamelists) {
            Restore-HiddenStatesFromDefault -LivePath $entry.Live -DefaultPath $entry.Default
        }

        Set-LastAction "Applied performance: Low-End PCs"
        Show-Message "Low-End performance settings applied successfully." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = "Low-End apply failed"
        Show-Message "Failed to apply Low-End settings.`r`n`r`n$($_.Exception.Message)" "Performance Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Set-HighEndPerformance {
    try {
        $content = Get-EsSettingsContent
        $content = Remove-EsSetting -Content $content -Name "global.video_driver"
        $content = Remove-EsSetting -Content $content -Name "mame.mame_video_driver"
        Save-EsSettingsContent -Content $content

	Update-AllProfileEsSettings -Mode "MidHigh"

        foreach ($entry in $PerformanceGamelists) {
            Set-AllHiddenTrueToFalse -LivePath $entry.Live
        }

        Set-LastAction "Applied performance: Mid to High-End PCs"
        Show-Message "Mid to High-End performance settings applied successfully." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = "Mid to High-End apply failed"
        Show-Message "Failed to apply High-End settings.`r`n`r`n$($_.Exception.Message)" "Performance Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Get-ActiveProfileName {
    if (Test-Path $ActiveProfileFile) {
        $name = (Get-Content -Path $ActiveProfileFile -Raw -ErrorAction SilentlyContinue).Trim()
        if ($name) { return $name }
    }

    $detected = Get-CurrentBuild

    if ($detected -and
        $detected -ne "Custom / Unknown" -and
        $detected -ne "Unknown" -and
        $detected -ne "Live config missing" -and
        $detected -ne "No build folders found") {
        return $detected
    }

    return ""
}

function Set-ActiveProfileName {
    param([string]$BuildType)

    try {
        Set-Content -Path $ActiveProfileFile -Value $BuildType -Encoding UTF8
    }
    catch {
        Write-ManagerLog "Failed to save active profile marker: $($_.Exception.Message)"
    }
}

function Save-LiveConfigToActiveProfile {
    $activeProfile = Get-ActiveProfileName

    if (-not $activeProfile) {
        Write-ManagerLog "Skipped saving live config: no active profile known"
        return
    }

    $profileConfig = Get-BuildSourcePath $activeProfile

    if (-not (Test-Path $LiveConfig)) {
        Write-ManagerLog "Skipped saving live config: live es_settings.cfg missing"
        return
    }

    $profileFolder = Split-Path -Parent $profileConfig

    if (-not (Test-Path $profileFolder)) {
        Write-ManagerLog "Skipped saving live config: profile folder missing for $activeProfile"
        return
    }

    try {
        Copy-Item -Path $LiveConfig -Destination $profileConfig -Force
        Write-ManagerLog "Saved live es_settings.cfg back to active profile: $activeProfile"
    }
    catch {
        Write-ManagerLog "Failed saving live config to $activeProfile`: $($_.Exception.Message)"
    }
}

function Restore-CurrentProfileFromMaster {
    $activeProfile = Get-ActiveProfileName

    if (-not $activeProfile) {
        Show-Message "No active profile could be detected.`r`n`r`nSwitch to a profile once, then try again." "No Active Profile" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    $masterConfig = Join-Path $MasterProfilesRoot "$activeProfile\es_settings.cfg"
    $profileConfig = Get-BuildSourcePath $activeProfile

    if (-not (Test-Path $masterConfig)) {
        Show-Message "Master profile backup not found for:`r`n$activeProfile`r`n`r`nExpected file:`r`n$masterConfig" "Missing Master Profile" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        if (-not (Test-Path $BackupRoot)) {
            New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        }

        if (Test-Path $LiveConfig) {
            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $liveBackup = Join-Path $BackupRoot "before_restore_current_profile_$activeProfile`_$timestamp.cfg"
            Copy-Item -Path $LiveConfig -Destination $liveBackup -Force
        }

        $profileFolder = Split-Path -Parent $profileConfig

        if (-not (Test-Path $profileFolder)) {
            New-Item -ItemType Directory -Path $profileFolder -Force | Out-Null
        }

        Copy-Item -Path $masterConfig -Destination $profileConfig -Force
        Copy-Item -Path $masterConfig -Destination $LiveConfig -Force

        Set-ActiveProfileName $activeProfile

        Refresh-BuildButtons
        Update-Status
        Refresh-BuildButtons

        Set-LastAction "Restored current profile from master: $activeProfile"

        Show-Message "Current profile restored from master backup:`r`n`r`n$activeProfile" "Profile Restored" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Set-LastAction "Profile restore failed: $activeProfile"
        Show-Message "Failed to restore current profile.`r`n`r`n$($_.Exception.Message)" "Restore Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Restore-AllProfilesFromMaster {
    if (-not (Test-Path $MasterProfilesRoot)) {
        Show-Message "Master profiles folder not found:`r`n$MasterProfilesRoot" "Missing Master Profiles" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $masterProfiles = Get-ChildItem -Path $MasterProfilesRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName "es_settings.cfg") }

    if (-not $masterProfiles -or $masterProfiles.Count -eq 0) {
        Show-Message "No master profile backups were found in:`r`n$MasterProfilesRoot" "No Master Profiles" ([System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }

    try {
        if (-not (Test-Path $BackupRoot)) {
            New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $bulkBackupFolder = Join-Path $BackupRoot "before_restore_all_profiles_$timestamp"
        New-Item -ItemType Directory -Path $bulkBackupFolder -Force | Out-Null

        $restoredCount = 0
        $skippedCount = 0

        foreach ($profile in $masterProfiles) {
            $profileName = $profile.Name
            $masterConfig = Join-Path $profile.FullName "es_settings.cfg"
            $liveProfileFolder = Join-Path $DefaultSystemsRoot $profileName
            $liveProfileConfig = Join-Path $liveProfileFolder "es_settings.cfg"

            try {
                if (-not (Test-Path $liveProfileFolder)) {
                    New-Item -ItemType Directory -Path $liveProfileFolder -Force | Out-Null
                }

                if (Test-Path $liveProfileConfig) {
                    $profileBackupFolder = Join-Path $bulkBackupFolder $profileName
                    New-Item -ItemType Directory -Path $profileBackupFolder -Force | Out-Null
                    Copy-Item -Path $liveProfileConfig -Destination (Join-Path $profileBackupFolder "es_settings.cfg") -Force
                }

                Copy-Item -Path $masterConfig -Destination $liveProfileConfig -Force
                $restoredCount++
                Write-ManagerLog "Restored profile from master: $profileName"
            }
            catch {
                $skippedCount++
                Write-ManagerLog "Failed restoring profile $profileName`: $($_.Exception.Message)"
            }
        }

        $activeProfile = Get-ActiveProfileName

        if ($activeProfile) {
            $activeRestoredConfig = Join-Path $DefaultSystemsRoot "$activeProfile\es_settings.cfg"

            if (Test-Path $activeRestoredConfig) {
                Copy-Item -Path $activeRestoredConfig -Destination $LiveConfig -Force
                Write-ManagerLog "Updated live es_settings.cfg after restore all using active profile: $activeProfile"
            }
        }

        Refresh-BuildButtons
        Update-Status
        Refresh-BuildButtons

        Set-LastAction "Restored all profiles from master: $restoredCount restored, $skippedCount skipped"

        Show-Message "All profiles restored from master backups.`r`n`r`nRestored: $restoredCount`r`nSkipped: $skippedCount`r`n`r`nSafety backup created:`r`n$bulkBackupFolder" "Profiles Restored" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Set-LastAction "Restore all profiles failed"
        Show-Message "Failed to restore all profiles.`r`n`r`n$($_.Exception.Message)" "Restore Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Apply-BuildType {
    param([string]$BuildType)

    $src = Get-BuildSourcePath $BuildType
    $dest = $LiveConfig

    if (-not (Test-Path $src)) {
        $script:statusLabel.Text = "Missing source for $BuildType"
        Show-Message "Source file not found:`r`n$src" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    $destFolder = Split-Path -Parent $dest

    if (-not (Test-Path $destFolder)) {
        $script:statusLabel.Text = "Destination folder missing"
        Show-Message "Destination folder not found:`r`n$destFolder" "Missing Folder" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        Save-LiveConfigToActiveProfile
	Sync-NetplayNicknameAcrossProfiles

        if ($script:checkBackup.Checked -and (Test-Path $dest)) {
            if (-not (Test-Path $BackupRoot)) {
                New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
            }

            $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
            $backupFile = Join-Path $BackupRoot "es_settings_$timestamp.cfg"
            Copy-Item -Path $dest -Destination $backupFile -Force
        }

        Copy-Item -Path $src -Destination $dest -Force

	Set-ActiveProfileName $BuildType
	Save-ManagerState -BuildPreset $BuildType -MusicPreset ""

	Set-LastAction "Applied build: $BuildType"
	Update-Status
	Refresh-BuildButtons

        Show-Message "$BuildType build applied successfully." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)

        if ($script:checkAutoClose.Checked) {
            $script:form.Close()
        }
    }
    catch {
        $script:statusLabel.Text = "Build copy failed"
        Show-Message "Failed to copy file.`r`n`r`n$($_.Exception.Message)" "Copy Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Reset-InputConfig {
    if (-not (Test-Path $EsInputDefault)) {
        Show-Message "Default input file not found:`r`n$EsInputDefault" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        if (Test-Path $EsInputLive) {
            Remove-Item -Path $EsInputLive -Force -ErrorAction Stop
        }

        Copy-Item -Path $EsInputDefault -Destination $EsInputLive -Force -ErrorAction Stop

        Set-LastAction "Input config reset"
        Show-Message "Input config reset successfully." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = "Input reset failed"
        Show-Message "Failed to reset input config.`r`n`r`n$($_.Exception.Message)" "Input Reset Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Restore-TeknoParrotMapping {
    if (-not (Test-Path $TeknoParrotUserTemplate)) {
        Show-Message "Source not found:`r`n$TeknoParrotUserTemplate" "Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        Copy-Item $TeknoParrotUserTemplate $TeknoParrotLive -Force

        Set-LastAction "TeknoParrot mapping restored"
        Show-Message "TeknoParrot mapping restored." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Show-Message $_.Exception.Message "Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Restore-MameMappings {
    if (-not (Test-Path $MameUserTemplateDir)) {
        Show-Message "Source folder not found:`r`n$MameUserTemplateDir" "Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        if (-not (Test-Path $MameLiveDir)) {
            New-Item -ItemType Directory -Path $MameLiveDir -Force | Out-Null
        }

        Get-ChildItem $MameUserTemplateDir -File | ForEach-Object {
            $destFile = Join-Path $MameLiveDir $_.Name
            Copy-Item $_.FullName $destFile -Force
        }

        Set-LastAction "MAME mappings restored"
        Show-Message "MAME mappings restored." "Success" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        Show-Message $_.Exception.Message "Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Normalize-GamesDbLine {
    param([string]$Line)

    $clean = ($Line -replace '#REMOVE_LINE#', '').Trim()
    $clean = $clean -replace '\s+', ' '
    $clean = $clean -replace '\s*/>', '/>'

    return $clean.ToLowerInvariant()
}

function Get-GamesDbRemoveSpecs {
    param([string]$ReferencePath)

    $specs = @{}
    $currentSystem = ""
    $currentGame = ""

    foreach ($line in Get-Content -Path $ReferencePath -Encoding UTF8) {

        if ($line -match '<system\s+[^>]*id="([^"]+)"') {
            $currentSystem = $matches[1]
        }

        if ($line -match '<game\s+[^>]*id="([^"]+)"') {
            $currentGame = $matches[1]
        }

        if ($line -match '#REMOVE_LINE#') {
            $targetLine = Normalize-GamesDbLine $line

            if ($currentSystem -and $currentGame -and $targetLine) {
                $key = "$currentSystem|$currentGame|$targetLine"
                $specs[$key] = $true
            }
        }

        if ($line -match '</game>') {
            $currentGame = ""
        }

        if ($line -match '</system>') {
            $currentSystem = ""
        }
    }

    return $specs
}

function Update-GamesDbFromReference {
    if (-not (Test-Path $GamesDbTemplate)) {
        Show-Message "GamesDB reference file not found:`r`n$GamesDbTemplate" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not (Test-Path $GamesDbLive)) {
        Show-Message "Live GamesDB file not found:`r`n$GamesDbLive" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        $removeSpecs = Get-GamesDbRemoveSpecs -ReferencePath $GamesDbTemplate

        if (-not $removeSpecs -or $removeSpecs.Count -eq 0) {
            Show-Message "No #REMOVE_LINE# markers were found in:`r`n$GamesDbTemplate" "Nothing To Remove" ([System.Windows.Forms.MessageBoxIcon]::Warning)
            return
        }

        if (-not (Test-Path $BackupRoot)) {
            New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        }

        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $backupFile = Join-Path $BackupRoot "gamesdb_$timestamp.xml"
        Copy-Item -Path $GamesDbLive -Destination $backupFile -Force

        $liveLines = Get-Content -Path $GamesDbLive -Encoding UTF8
        $newLines = New-Object System.Collections.Generic.List[string]

        $currentSystem = ""
        $currentGame = ""
        $removedCount = 0

        foreach ($line in $liveLines) {

            if ($line -match '<system\s+[^>]*id="([^"]+)"') {
                $currentSystem = $matches[1]
            }

            if ($line -match '<game\s+[^>]*id="([^"]+)"') {
                $currentGame = $matches[1]
            }

            $normalizedLine = Normalize-GamesDbLine $line
            $key = "$currentSystem|$currentGame|$normalizedLine"

            if ($currentSystem -and $currentGame -and $removeSpecs.ContainsKey($key)) {
                $removedCount++
            }
            else {
                $newLines.Add($line)
            }

            if ($line -match '</game>') {
                $currentGame = ""
            }

            if ($line -match '</system>') {
                $currentSystem = ""
            }
        }

        Set-Content -Path $GamesDbLive -Value $newLines -Encoding UTF8

        Set-LastAction "GamesDB updated: $removedCount lines removed"

        Show-Message "GamesDB update complete.`r`n`r`nRemoved lines: $removedCount`r`nBackup created:`r`n$backupFile" "GamesDB Updated" ([System.Windows.Forms.MessageBoxIcon]::Information)
    }
    catch {
        $script:statusLabel.Text = "GamesDB update failed"
        Show-Message "Failed to update GamesDB.`r`n`r`n$($_.Exception.Message)" "GamesDB Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Launch-Utility {
    param(
        [string]$Name,
        [string]$WorkingDir,
        [string]$Target,
        [switch]$UseCmd
    )

    if (-not (Test-Path $WorkingDir)) {
        Show-Message "Working folder not found:`r`n$WorkingDir" "Missing Folder" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    if (-not (Test-Path $Target)) {
        Show-Message "Target not found:`r`n$Target" "Missing File" ([System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    try {
        if ($UseCmd) {
            Start-Process -FilePath "cmd.exe" -WindowStyle Hidden -ArgumentList "/c `"$Target`"" -WorkingDirectory $WorkingDir
        }
        else {
            Start-Process -FilePath $Target -WorkingDirectory $WorkingDir
        }

        Set-LastAction "Launched: $Name"
    }
    catch {
        Show-Message "Failed to launch $Name.`r`n`r`n$($_.Exception.Message)" "Launch Error" ([System.Windows.Forms.MessageBoxIcon]::Error)
    }
}

function Launch-HookOfTheReaper {
    $target = Join-Path $HookRoot "HookOfTheReaper.exe"
    Launch-Utility -Name "Hook Of The Reaper" -WorkingDir $HookRoot -Target $target
}

function Launch-InstallDependencies {
    $target = Join-Path $DependenciesRoot "install_all.bat"
    Launch-Utility -Name "Install All Dependencies" -WorkingDir $DependenciesRoot -Target $target -UseCmd
}

function Launch-RS3Calibration {
    $target = Join-Path $RS3Root "Launcher.bat"
    Launch-Utility -Name "Retro Shooter RS3 Calibration" -WorkingDir $RS3Root -Target $target -UseCmd
}

function Launch-SindenCalibration {
    $target = Join-Path $SindenRoot "Lightgun.exe"
    Launch-Utility -Name "Sinden Calibration" -WorkingDir $SindenRoot -Target $target
}

function Launch-RetroBat {
    Launch-Utility -Name "RetroBat" -WorkingDir $Base -Target $RetroBatExe
}

function Launch-BatGui {
    Launch-Utility -Name "RetroBat GUI" -WorkingDir $Base -Target $BatGuiExe
}

function Update-Status {
    $managerState = Load-ManagerState
    $detectedBuild = Get-CurrentBuild

    $rememberedBuild = ""
    if ($managerState -and $managerState.LastBuildPreset) {
        $rememberedBuild = $managerState.LastBuildPreset
    }

    if (-not [string]::IsNullOrWhiteSpace($rememberedBuild)) {
        if ($detectedBuild -eq $rememberedBuild) {
            $script:labelCurrent.Text = "Current config: $rememberedBuild"
        }
        else {
            $script:labelCurrent.Text = "Current config: $rememberedBuild / Modified"
        }
    }
    else {
        $script:labelCurrent.Text = "Current config: $detectedBuild"
    }

    $musicSelection = Get-CurrentMusicSelection
    if ($managerState -and $managerState.LastMusicPreset -and $musicSelection -eq "None") {
        $musicSelection = $managerState.LastMusicPreset
    }

    $script:labelMusic.Text = "Music: $musicSelection"
    $script:labelBase.Text = "Root: $Base"
    $script:labelScript.Text = "Launcher: $ScriptFolder"

    if (Test-Path $LiveConfig) {
        $script:statusLabel.Text = "Ready"
    }
    else {
        $script:statusLabel.Text = "Warning: live es_settings.cfg not found"
    }
}

$ColorBg = [System.Drawing.Color]::FromArgb(18, 18, 22)
$ColorPanel = [System.Drawing.Color]::FromArgb(24, 24, 30)
$ColorCard = [System.Drawing.Color]::FromArgb(31, 31, 39)
$ColorButton = [System.Drawing.Color]::FromArgb(45, 45, 56)
$ColorButtonHover = [System.Drawing.Color]::FromArgb(58, 58, 72)
$ColorBorder = [System.Drawing.Color]::FromArgb(70, 70, 86)
$ColorAccent = [System.Drawing.Color]::FromArgb(0, 200, 255)
$ColorText = [System.Drawing.Color]::FromArgb(238, 238, 242)
$ColorMuted = [System.Drawing.Color]::FromArgb(165, 165, 175)

function New-UiLabel {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [int]$Size = 9,
        [System.Drawing.FontStyle]$Style = [System.Drawing.FontStyle]::Regular,
        [System.Drawing.Color]$Color = $ColorText
    )

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Location = New-Object System.Drawing.Point($X, $Y)
    $label.Size = New-Object System.Drawing.Size($W, $H)
    $label.Font = New-Object System.Drawing.Font("Segoe UI", $Size, $Style)
    $label.ForeColor = $Color
    $label.BackColor = [System.Drawing.Color]::Transparent

    return $label
}

function New-Card {
    param(
        [string]$Title,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [System.Windows.Forms.Control]$Parent
    )

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($X, $Y)
    $panel.Size = New-Object System.Drawing.Size($W, $H)
    $panel.BackColor = $ColorCard
    $panel.BorderStyle = "FixedSingle"
    $Parent.Controls.Add($panel)

    $titleLabel = New-UiLabel $Title 14 10 ($W - 28) 24 10 ([System.Drawing.FontStyle]::Bold) $ColorAccent
    $panel.Controls.Add($titleLabel)

    return $panel
}

function New-PremiumButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$W,
        [int]$H,
        [scriptblock]$Click,
        [string]$Tip = ""
    )

    $btn = New-Object System.Windows.Forms.Button
    $btn.Text = $Text
    $btn.Location = New-Object System.Drawing.Point($X, $Y)
    $btn.Size = New-Object System.Drawing.Size($W, $H)
    $btn.Font = New-Object System.Drawing.Font("Segoe UI", 8.75, [System.Drawing.FontStyle]::Bold)
    $btn.BackColor = $ColorButton
    $btn.ForeColor = $ColorText
    $btn.FlatStyle = "Flat"
    $btn.FlatAppearance.BorderColor = $ColorBorder
    $btn.FlatAppearance.BorderSize = 1
    $btn.Cursor = [System.Windows.Forms.Cursors]::Hand
    $btn.Add_Click($Click)

    $btn.Add_MouseEnter({
        param($sender, $eventArgs)
        $sender.BackColor = $ColorButtonHover
        $sender.FlatAppearance.BorderColor = $ColorAccent
    })

$btn.Add_MouseLeave({
    param($sender, $eventArgs)

    if ($sender.AccessibleDescription -eq "ACTIVE") {
        $sender.BackColor = [System.Drawing.Color]::FromArgb(38, 52, 62)
        $sender.FlatAppearance.BorderColor = $ColorAccent
    }
    else {
        $sender.BackColor = $ColorButton
        $sender.FlatAppearance.BorderColor = $ColorBorder
    }
})

    if ($Tip) {
        $tooltip.SetToolTip($btn, $Tip)
    }

    return $btn
}

function Set-PremiumButtonState {
    param(
        [System.Windows.Forms.Button]$Button,
        [bool]$Active
    )

    if ($Active) {
        $Button.AccessibleDescription = "ACTIVE"
        $Button.BackColor = [System.Drawing.Color]::FromArgb(38, 52, 62)
        $Button.FlatAppearance.BorderColor = $ColorAccent
        $Button.ForeColor = $ColorText
    }
    else {
        $Button.AccessibleDescription = ""
        $Button.BackColor = $ColorButton
        $Button.FlatAppearance.BorderColor = $ColorBorder
        $Button.ForeColor = $ColorText
    }
}

function Refresh-BuildButtons {
    if (-not $script:cardBuilds) { return }

    $script:cardBuilds.Controls.Clear()

    $titleLabel = New-UiLabel "Collection / Build Presets" 14 10 580 24 10 ([System.Drawing.FontStyle]::Bold) $ColorAccent
    $script:cardBuilds.Controls.Add($titleLabel)

    $buildFolders = Get-BuildFolders
    $managerState = Load-ManagerState
    $currentBuildName = Get-CurrentBuild

if ($managerState -and -not [string]::IsNullOrWhiteSpace($managerState.LastBuildPreset)) {
    $currentBuildName = $managerState.LastBuildPreset
}
    if (-not $buildFolders -or $buildFolders.Count -eq 0) {
        $noBuildsLabel = New-UiLabel "No build folders with es_settings.cfg were found." 18 48 570 50 9 ([System.Drawing.FontStyle]::Regular) $ColorMuted
        $script:cardBuilds.Controls.Add($noBuildsLabel)
        return
    }

    $buttonWidth = 180
    $buttonHeight = 42
    $startX = 18
    $startY = 48
    $spacingX = 18
    $spacingY = 14
    $maxCols = 3

    for ($i = 0; $i -lt $buildFolders.Count; $i++) {
        $folder = $buildFolders[$i]
        $col = $i % $maxCols
        $row = [math]::Floor($i / $maxCols)

        $x = $startX + (($buttonWidth + $spacingX) * $col)
        $y = $startY + (($buttonHeight + $spacingY) * $row)

        $btn = New-PremiumButton "Apply $($folder.Name)" $x $y $buttonWidth $buttonHeight {
            param($sender, $eventArgs)
            Apply-BuildType $sender.Tag
        } "Applies this collection/build preset."

        $btn.Tag = $folder.Name

        if ($folder.Name -eq $currentBuildName) {
            Set-PremiumButtonState -Button $btn -Active $true
        }

        $script:cardBuilds.Controls.Add($btn)
    }
}

Ensure-ManagerFolders
Write-ManagerLog "Manager started"
$script:form = New-Object System.Windows.Forms.Form
$script:form.Text = "Uncle Rick's RetroBat Manager $AppVersion"
$script:form.Size = New-Object System.Drawing.Size(730, 830)
$script:form.StartPosition = "CenterScreen"
$script:form.FormBorderStyle = "FixedDialog"
$script:form.MaximizeBox = $false
$script:form.MinimizeBox = $true
$script:form.BackColor = $ColorBg
$script:form.ForeColor = $ColorText

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Location = New-Object System.Drawing.Point(20, 15)
$headerPanel.Size = New-Object System.Drawing.Size(675, 120)
$headerPanel.BackColor = $ColorPanel
$headerPanel.BorderStyle = "FixedSingle"
$script:form.Controls.Add($headerPanel)

$topBadgeLabel = New-UiLabel "Rickbat Control Center" 0 6 675 18 8.25 ([System.Drawing.FontStyle]::Bold) $ColorAccent
$topBadgeLabel.TextAlign = "MiddleCenter"
$headerPanel.Controls.Add($topBadgeLabel)

$titleLabel = New-UiLabel "Uncle Rick's RetroBat Manager $AppVersion" 0 24 675 30 16 ([System.Drawing.FontStyle]::Bold) $ColorText
$titleLabel.TextAlign = "MiddleCenter"
$headerPanel.Controls.Add($titleLabel)

$subTitleLabel = New-UiLabel "Retro Lunatics Edition" 0 54 675 22 9 ([System.Drawing.FontStyle]::Italic) $ColorAccent
$subTitleLabel.TextAlign = "MiddleCenter"
$headerPanel.Controls.Add($subTitleLabel)

$separator = New-Object System.Windows.Forms.Panel
$separator.Location = New-Object System.Drawing.Point(35, 78)
$separator.Size = New-Object System.Drawing.Size(605, 1)
$separator.BackColor = $ColorBorder
$headerPanel.Controls.Add($separator)

$script:labelCurrent = New-UiLabel "" 25 86 300 20 8.75 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$headerPanel.Controls.Add($script:labelCurrent)

$script:labelMusic = New-UiLabel "" 350 86 300 20 8.75 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$headerPanel.Controls.Add($script:labelMusic)

$script:labelBase = New-UiLabel "" 25 104 300 18 8 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$headerPanel.Controls.Add($script:labelBase)

$script:labelScript = New-UiLabel "" 350 104 300 18 8 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$headerPanel.Controls.Add($script:labelScript)

$fixGlobalPanel = New-Object System.Windows.Forms.Panel
$fixGlobalPanel.Location = New-Object System.Drawing.Point(20, 140)
$fixGlobalPanel.Size = New-Object System.Drawing.Size(675, 28)
$fixGlobalPanel.BackColor = $ColorPanel
$fixGlobalPanel.BorderStyle = "FixedSingle"
$script:form.Controls.Add($fixGlobalPanel)

$script:labelFixGlobal = New-UiLabel "RickBat Fixes: Checking online..." 14 5 645 18 8.75 ([System.Drawing.FontStyle]::Bold) $ColorAccent
$fixGlobalPanel.Controls.Add($script:labelFixGlobal)

$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Location = New-Object System.Drawing.Point(20, 178)
$tabs.Size = New-Object System.Drawing.Size(675, 490)
$tabs.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$script:form.Controls.Add($tabs)

$tabMain = New-Object System.Windows.Forms.TabPage
$tabMain.Text = "Main"
$tabMain.BackColor = $ColorBg
$tabMain.ForeColor = $ColorText
$tabs.TabPages.Add($tabMain)

$tabTools = New-Object System.Windows.Forms.TabPage
$tabTools.Text = "Tools"
$tabTools.BackColor = $ColorBg
$tabTools.ForeColor = $ColorText
$tabs.TabPages.Add($tabTools)

$tabPerformance = New-Object System.Windows.Forms.TabPage
$tabPerformance.Text = "Performance"
$tabPerformance.BackColor = $ColorBg
$tabPerformance.ForeColor = $ColorText
$tabs.TabPages.Add($tabPerformance)

$tabPostUpdate = New-Object System.Windows.Forms.TabPage
$tabPostUpdate.Text = "Post Update"
$tabPostUpdate.BackColor = $ColorBg
$tabPostUpdate.ForeColor = $ColorText
$tabs.TabPages.Add($tabPostUpdate)

$tabCommunity = New-Object System.Windows.Forms.TabPage
$tabCommunity.Text = "Community"
$tabCommunity.BackColor = $ColorBg
$tabCommunity.ForeColor = $ColorText
$tabs.TabPages.Add($tabCommunity)

$tabShortcuts = New-Object System.Windows.Forms.TabPage
$tabShortcuts.Text = "Shortcuts"
$tabShortcuts.BackColor = $ColorBg
$tabShortcuts.ForeColor = $ColorText
$tabs.TabPages.Add($tabShortcuts)
$tabFixManager = New-Object System.Windows.Forms.TabPage
$tabFixManager.Text = "Fix Manager"
$tabFixManager.BackColor = $ColorBg
$tabFixManager.ForeColor = $ColorText
$tabs.TabPages.Add($tabFixManager)

$script:cardBuilds = New-Card "Collection / Build Presets" 14 14 635 190 $tabMain
Refresh-BuildButtons

$script:groupMusic = New-Card "Music Selections" 14 220 635 180 $tabMain
Refresh-MusicButtons

$cardRetroBatLaunch = New-Card "RetroBat Launchers" 14 410 635 80 $tabMain
$cardRetroBatLaunch.Controls.Add((New-PremiumButton "Launch RetroBat" 18 35 185 32 { Launch-RetroBat } "Launches RetroBat.exe from the RetroBat root folder."))
$cardRetroBatLaunch.Controls.Add((New-PremiumButton "Launch BatGui" 225 35 185 32 { Launch-BatGui } "Launches BatGui.exe from the RetroBat root folder."))

$cardUtilities = New-Card "Utilities" 14 14 635 135 $tabTools
$cardUtilities.Controls.Add((New-PremiumButton "Hook Of The Reaper" 18 48 140 42 { Launch-HookOfTheReaper } "Launches Hook Of The Reaper."))
$cardUtilities.Controls.Add((New-PremiumButton "Install Dependencies" 172 48 140 42 { Launch-InstallDependencies } "Runs RetroBat dependency installer."))
$cardUtilities.Controls.Add((New-PremiumButton "RS3 Calibration" 326 48 140 42 { Launch-RS3Calibration } "Launches Retro Shooter RS3 calibration."))
$cardUtilities.Controls.Add((New-PremiumButton "Sinden Calibration" 480 48 140 42 { Launch-SindenCalibration } "Launches Sinden calibration utility."))
$cardUtilities.Controls.Add((New-PremiumButton "Open HOTR" 18 95 140 28 { Open-FolderSafe -Path $HookRoot -Label "Hook Of The Reaper Folder" } "Opens HOTR folder."))
$cardUtilities.Controls.Add((New-PremiumButton "Open Tools" 172 95 140 28 { Open-FolderSafe -Path $ToolsRoot -Label "Tools Folder" } "Opens RetroBat tools folder."))
$cardUtilities.Controls.Add((New-PremiumButton "Open RS3" 326 95 140 28 { Open-FolderSafe -Path $RS3Root -Label "RS3 Folder" } "Opens RS3 folder."))
$cardUtilities.Controls.Add((New-PremiumButton "Open Sinden" 480 95 140 28 { Open-FolderSafe -Path $SindenRoot -Label "Sinden Folder" } "Opens Sinden folder."))

$cardLogs = New-Card "Logs / Debug" 14 170 635 100 $tabTools
$cardLogs.Controls.Add((New-PremiumButton "EmulatorLauncher Log" 18 45 185 38 { Open-FileSafe -Path $EmulatorLauncherLog -Label "EmulatorLauncher Log" } "Opens emulatorLauncher.log."))
$cardLogs.Controls.Add((New-PremiumButton "RetroBat Log" 225 45 185 38 { Open-FileSafe -Path $RetroBatLog -Label "RetroBat Log" } "Opens RetroBat.log."))
$cardLogs.Controls.Add((New-PremiumButton "RetroArch Config" 432 45 185 38 { Open-FileSafe -Path $RetroArchConfig -Label "RetroArch Config" } "Opens retroarch.cfg."))

$perfNote = New-UiLabel "Applies low-end or high-end display behavior without replacing your full config." 22 18 610 22 8.75 ([System.Drawing.FontStyle]::Italic) $ColorMuted
$tabPerformance.Controls.Add($perfNote)

$cardPerformance = New-Card "Display Profiles" 14 52 635 125 $tabPerformance
$cardPerformance.Controls.Add((New-PremiumButton "Low-End PCs" 18 52 185 42 { Set-LowEndPerformance } "Best for older CPUs, 5th gen-era systems, or systems without a dedicated GPU."))
$cardPerformance.Controls.Add((New-PremiumButton "Mid to High-End PCs" 225 52 185 42 { Set-HighEndPerformance } "Removes low-end video overrides and unhides entries in supported gamelists."))
$cardPerformance.Controls.Add((New-PremiumButton "Open Defaults" 432 52 185 42 { Open-FolderSafe -Path $DefaultsRoot -Label "Defaults Folder" } "Opens defaults folder."))
$postNote = New-UiLabel "Restores custom mappings after RetroBat updates overwrite them." 22 18 610 22 8.75 ([System.Drawing.FontStyle]::Italic) $ColorMuted
$tabPostUpdate.Controls.Add($postNote)

$cardPost = New-Card "Mapping Restore" 14 52 635 125 $tabPostUpdate
$cardPost.Controls.Add((New-PremiumButton "Restore TeknoParrot" 18 52 185 42 { Restore-TeknoParrotMapping } "Restores teknoparrot.yml from usertemplates."))
$cardPost.Controls.Add((New-PremiumButton "Restore MAME Mappings" 225 52 185 42 { Restore-MameMappings } "Copies usertemplates\mame files into live mame mappings."))
$cardPost.Controls.Add((New-PremiumButton "Open UserTemplates" 432 52 185 42 { Open-FolderSafe -Path $UserTemplatesRoot -Label "UserTemplates" } "Opens your custom inputmapping usertemplates folder."))
$cardGamesDb = New-Card "GamesDB Cleanup" 14 195 635 125 $tabPostUpdate
$cardGamesDb.Controls.Add((New-PremiumButton "Update GamesDB" 18 52 185 42 { Update-GamesDbFromReference } "Removes #REMOVE_LINE# hardware lines from the live gamesdb.xml using the reference file."))
$cardProfileRecovery = New-Card "Profile Recovery" 14 335 635 125 $tabPostUpdate
$cardProfileRecovery.Controls.Add((New-PremiumButton "Restore Current Profile" 18 52 220 42 { Restore-CurrentProfileFromMaster } "Restores the currently active profile from the protected master profile backup."))
$cardProfileRecovery.Controls.Add((New-PremiumButton "Restore All Profiles" 260 52 220 42 { Restore-AllProfilesFromMaster } "Restores every profile from the protected master profile backups. Great for quick testing resets."))
$cardCommunity = New-Card "Retro Lunatics Network" 14 14 635 190 $tabCommunity
$cardCommunity.Controls.Add((New-PremiumButton "Lightgun Lunatics" 18 48 185 38 { Open-LinkSafe -Url $UrlLightgunLunatics -Label "Lightgun Lunatics" } "Opens the Lightgun Lunatics Facebook group."))
$cardCommunity.Controls.Add((New-PremiumButton "Arcade Lunatics" 225 48 185 38 { Open-LinkSafe -Url $UrlArcadeLunatics -Label "Arcade Lunatics" } "Opens the Arcade Lunatics Facebook group."))
$cardCommunity.Controls.Add((New-PremiumButton "Retro Racing Lunatics" 432 48 185 38 { Open-LinkSafe -Url $UrlRetroRacingLunatics -Label "Retro Racing Lunatics" } "Opens the Retro Racing Lunatics Facebook group."))
$cardCommunity.Controls.Add((New-PremiumButton "Retro Lunatics Discord" 18 98 185 38 { Open-LinkSafe -Url $UrlRetroLunaticsDiscord -Label "Retro Lunatics Discord" } "Opens the Retro Lunatics Discord invite."))
$cardCommunity.Controls.Add((New-PremiumButton "Rickbat Support" 225 98 185 38 { Open-LinkSafe -Url $UrlRickbatSupportDiscord -Label "Rickbat Support Discord" } "Opens the Rickbat Support Discord invite."))
$cardCommunity.Controls.Add((New-PremiumButton "Retro Lunatics Site" 432 98 185 38 { Open-LinkSafe -Url $UrlRetroLunaticsWebsite -Label "Retro Lunatics Website" } "Opens the Retro Lunatics website."))

$communityNote = New-UiLabel "Discord membership requires membership in one of the three Facebook groups." 18 152 590 20 8.25 ([System.Drawing.FontStyle]::Italic) $ColorMuted
$cardCommunity.Controls.Add($communityNote)

$cardShortcuts = New-Card "Quick Access" 14 14 635 205 $tabShortcuts
$cardShortcuts.Controls.Add((New-PremiumButton "Open RetroBat" 18 48 140 34 { Open-FolderSafe -Path $Base -Label "RetroBat Root" } "Opens RetroBat root folder."))
$cardShortcuts.Controls.Add((New-PremiumButton "Open Roms" 172 48 140 34 { Open-FolderSafe -Path $RomsRoot -Label "Roms Folder" } "Opens roms folder."))
$cardShortcuts.Controls.Add((New-PremiumButton "Open Music" 326 48 140 34 { Open-FolderSafe -Path $MusicFoldersDir -Label "Music Folders" } "Opens Music Folders."))
$cardShortcuts.Controls.Add((New-PremiumButton "Open Themes" 480 48 140 34 { Open-FolderSafe -Path $ThemesDir -Label "Themes Folder" } "Opens themes folder."))
$cardShortcuts.Controls.Add((New-PremiumButton "Refresh Status" 18 98 140 34 { Refresh-MusicButtons; Update-Status } "Refreshes music buttons and status."))
$cardShortcuts.Controls.Add((New-PremiumButton "Open Builds" 172 98 140 34 { Open-FolderSafe -Path $DefaultSystemsRoot -Label "Build Folder" } "Opens build presets."))
$cardShortcuts.Controls.Add((New-PremiumButton "Open Config" 326 98 140 34 { Open-FolderSafe -Path (Split-Path -Parent $LiveConfig) -Label "Live Config Folder" } "Opens live config folder."))
$cardShortcuts.Controls.Add((New-PremiumButton "Input Reset" 480 98 140 34 { Reset-InputConfig } "Deletes es_input.cfg and restores default."))
$cardShortcuts.Controls.Add((New-PremiumButton "Exit" 480 148 140 34 { $script:form.Close() } "Closes the manager."))
$cardFixManager = New-Card "RickBat Lite Fix Manager" 14 14 635 255 $tabFixManager

$script:labelFixStatus = New-UiLabel "RickBat Fixes: Checking online..." 18 48 580 24 10 ([System.Drawing.FontStyle]::Bold) $ColorAccent
$cardFixManager.Controls.Add($script:labelFixStatus)

$script:labelFixCurrent = New-UiLabel "Checking GitHub for available RickBat fixes..." 18 75 580 38 8.75 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$cardFixManager.Controls.Add($script:labelFixCurrent)

$progressLabel = New-UiLabel "Progress" 18 120 160 18 8.5 ([System.Drawing.FontStyle]::Bold) $ColorMuted
$cardFixManager.Controls.Add($progressLabel)

$script:progressFix = New-Object System.Windows.Forms.ProgressBar
$script:progressFix.Location = New-Object System.Drawing.Point(18, 142)
$script:progressFix.Size = New-Object System.Drawing.Size(584, 18)
$script:progressFix.Minimum = 0
$script:progressFix.Maximum = 100
$script:progressFix.Value = 0
$cardFixManager.Controls.Add($script:progressFix)

$cardFixManager.Controls.Add((New-PremiumButton "Check Fixes" 18 185 180 42 { Check-RickBatFixes } "Checks GitHub for available RickBat Lite fixes."))
$cardFixManager.Controls.Add((New-PremiumButton "Update RickBat Fixes" 220 185 180 42 { Update-RickBatFixes } "Downloads and installs missing RickBat Lite fixes."))
$cardFixManager.Controls.Add((New-PremiumButton "Open Fix Log" 422 185 180 42 { Open-FileSafe -Path $FixManagerLog -Label "Fix Manager Log" } "Opens fix-manager.log."))

$bottomPanel = New-Object System.Windows.Forms.Panel
$bottomPanel.Location = New-Object System.Drawing.Point(20, 680)
$bottomPanel.Size = New-Object System.Drawing.Size(675, 75)
$bottomPanel.BackColor = $ColorPanel
$bottomPanel.BorderStyle = "FixedSingle"
$script:form.Controls.Add($bottomPanel)

$script:checkAutoClose = New-Object System.Windows.Forms.CheckBox
$script:checkAutoClose.Text = "Close after successful apply"
$script:checkAutoClose.Location = New-Object System.Drawing.Point(20, 12)
$script:checkAutoClose.Size = New-Object System.Drawing.Size(220, 24)
$script:checkAutoClose.ForeColor = $ColorMuted
$script:checkAutoClose.BackColor = [System.Drawing.Color]::Transparent
$script:checkAutoClose.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$bottomPanel.Controls.Add($script:checkAutoClose)

$script:checkBackup = New-Object System.Windows.Forms.CheckBox
$script:checkBackup.Text = "Create backup before replace"
$script:checkBackup.Location = New-Object System.Drawing.Point(260, 12)
$script:checkBackup.Size = New-Object System.Drawing.Size(220, 24)
$script:checkBackup.ForeColor = $ColorMuted
$script:checkBackup.BackColor = [System.Drawing.Color]::Transparent
$script:checkBackup.Font = New-Object System.Drawing.Font("Segoe UI", 8.5)
$script:checkBackup.Checked = $true
$bottomPanel.Controls.Add($script:checkBackup)

$script:statusLabel = New-UiLabel "Ready" 20 42 635 22 9 ([System.Drawing.FontStyle]::Italic) $ColorAccent
$bottomPanel.Controls.Add($script:statusLabel)

$footerLabel = New-UiLabel "Powered by Retro Lunatics - $AppVersion - Lightgun Lunatics - Arcade Lunatics - Retro Racing Lunatics" 0 760 715 22 8.25 ([System.Drawing.FontStyle]::Regular) $ColorMuted
$footerLabel.TextAlign = "MiddleCenter"
$script:form.Controls.Add($footerLabel)

$script:form.Add_Shown({
    Update-Status

    $script:startupFixTimer = New-Object System.Windows.Forms.Timer
    $script:startupFixTimer.Interval = 800

    $script:startupFixTimer.Add_Tick({
        $script:startupFixTimer.Stop()
        $script:startupFixTimer.Dispose()
        Check-RickBatFixesSilent
    })

    $script:startupFixTimer.Start()
})

[void]$script:form.ShowDialog()