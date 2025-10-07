param (
    [string]$localBackupPath = "D:\DCP Online\",
    [string]$destinationPath = "D:\WatchFolder\",
    [switch]$DebugMode
)

Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force

$global:DebugMode = $DebugMode
$global:locationName = "Cevahir"
$global:connectionString = "Server=GMDCMUCARERNB;Database=MarsDcNocMVC;Integrated Security=True;"

if ($global:DebugMode) {
    Write-DebugLog "Debug Mode ENABLED - Database operations will be logged" -Level "INFO"
} else {
    Write-Host "Debug Mode DISABLED - Use -DebugMode parameter to see detailed logs" -ForegroundColor Yellow
}

$global:scriptStartTime = Get-Date
$global:scriptStatus = "Running"
$global:processedFolders = 0
$global:successfulFolders = 0
$global:failedFolders = 0

$mutexName = "Global\MarsDcNocBackup"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

if (-not $mutex.WaitOne(100)) {
    Write-Host "Başka bir backup işlemi çalışıyor. Çıkılıyor..." -ForegroundColor Yellow
    exit 2
}

function Start-GracefulShutdown {
    param (
        [int]$ExitCode = 0,
        [string]$Reason = "Normal completion"
    )
    
    $global:scriptStatus = if ($ExitCode -eq 0) { "Completed Successfully" } else { "Completed with Errors" }
    $endTime = Get-Date
    $duration = $endTime - $global:scriptStartTime
    $durationStr = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds
    
    Write-DebugLog "=== SCRIPT SHUTDOWN BAŞLATILIYOR ===" -Level "INFO"
    Write-DebugLog "Shutdown Reason: $Reason" -Level "INFO"
    Write-DebugLog "Total Duration: $durationStr" -Level "INFO"
    Write-DebugLog "Processed Folders: $global:processedFolders" -Level "INFO"
    Write-DebugLog "Successful: $global:successfulFolders" -Level "SUCCESS"
    Write-DebugLog "Failed: $global:failedFolders" -Level $(if ($global:failedFolders -gt 0) { "ERROR" } else { "INFO" })
    
    if ($global:session -ne $null) {
        try {
            if ($global:session.Opened) {
                $global:session.Close()
                Write-DebugLog "WinSCP session closed successfully" -Level "SUCCESS"
            }
            $global:session.Dispose()
            Write-DebugLog "WinSCP session disposed successfully" -Level "SUCCESS"
        }
        catch {
            Write-DebugLog "WinSCP session cleanup error: $($_.Exception.Message)" -Level "WARNING"
        }
        finally {
            $global:session = $null
        }
    }
    
    try {
        Write-ToDatabase -folderName "SYSTEM_SUMMARY" `
                        -action "Script Completed" `
                        -status $(if ($ExitCode -eq 0) { 1 } else { 0 }) `
                        -duration $durationStr `
                        -fileSize "$global:processedFolders folders" `
                        -totalFileSize "Success: $global:successfulFolders, Failed: $global:failedFolders"
        Write-DebugLog "Final summary logged to database" -Level "SUCCESS"
    }
    catch {
        Write-DebugLog "Failed to log final summary: $($_.Exception.Message)" -Level "WARNING"
    }
    
    try {
        $jobs = Get-Job
        if ($jobs.Count -gt 0) {
            Write-DebugLog "Cleaning up $($jobs.Count) background jobs..." -Level "INFO"
            Get-Job | Remove-Job -Force
            Write-DebugLog "Background jobs cleaned up" -Level "SUCCESS"
        }
    }
    catch {
        Write-DebugLog "Job cleanup error: $($_.Exception.Message)" -Level "WARNING"
    }
    
    try {
        if ($mutex -ne $null) {
            $mutex.ReleaseMutex()
            $mutex.Dispose()
            Write-DebugLog "Mutex released successfully" -Level "SUCCESS"
        }
    }
    catch {
        Write-DebugLog "Mutex cleanup error: $($_.Exception.Message)" -Level "WARNING"
    }
    
    $statusColor = if ($ExitCode -eq 0) { "Green" } else { "Red" }
    $statusMessage = if ($ExitCode -eq 0) { 
        "✅ Backup Script başarıyla tamamlandı!" 
    } else { 
        "❌ Backup Script hatalarla tamamlandı!" 
    }
    
    Write-DebugLog "=== SCRIPT SHUTDOWN TAMAMLANDI ===" -Level $(if ($ExitCode -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-Host $statusMessage -ForegroundColor $statusColor
    Write-Host "Toplam Süre: $durationStr | İşlenen: $global:processedFolders | Başarılı: $global:successfulFolders | Başarısız: $global:failedFolders" -ForegroundColor Cyan
    
    exit $ExitCode
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host "`n🛑 Script interrupted by user" -ForegroundColor Yellow
    Start-GracefulShutdown -ExitCode 130 -Reason "User Interruption"
}

try {

$ftpHost = "178.132.50.11"
$ftpUser = "marsreklamsys"

$ftpPassword = if ($env:MARS_FTP_PASSWORD) { 
    $env:MARS_FTP_PASSWORD 
} else { 
    "0VvObepFTxjBdZQ"
    Write-DebugLog "Warning: Using hardcoded password. Set MARS_FTP_PASSWORD environment variable." -Level "WARNING"
}

Write-DebugLog "=== MARS DC NOC BACKUP SCRIPT BAŞLATILIYOR ===" -Level "INFO"
Write-DebugLog "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level "INFO"
Write-DebugLog "FTP Connection info: Host=$ftpHost, User=$ftpUser" -Level "INFO"

$logRetentionDays = 30
$sourcePaths = @("/REKLAM_DATA/Mars Reklam/REKLAM/", "/FRAGMAN_DATA/Fragman/")

New-Item -ItemType Directory -Path $localBackupPath -Force | Out-Null
New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null

$minimumRequiredSpace = 50
function Get-DiskSpace {
    param (
        [string]$driveLetter
    )
    try {
        $drive = Get-PSDrive $driveLetter -ErrorAction Stop
        $freeSpace = [math]::Round($drive.Free / 1GB, 2)
        $usedSpace = [math]::Round(($drive.Used) / 1GB, 2)
        $totalSpace = [math]::Round(($drive.Used + $drive.Free) / 1GB, 2)
        
        return @{
            FreeSpace = $freeSpace
            UsedSpace = $usedSpace  
            TotalSpace = $totalSpace
        }
    }
    catch {
        Write-DebugLog "Disk space calculation error for drive '$driveLetter': $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

function Check-DiskSpace {
    param (
        [string]$driveLetter,
        [double]$requiredSpace
    )
    $diskSpace = Get-DiskSpace -driveLetter $driveLetter
    if ($diskSpace.FreeSpace -lt $requiredSpace) {
        Write-Host "UYARI: $driveLetter sürücüsünde yeterli alan yok!" -ForegroundColor Red
        Write-Host "Boş alan: $($diskSpace.FreeSpace) GB, Gerekli alan: $requiredSpace GB" -ForegroundColor Red
        
        # Veritabanına kayıt ekle
        Write-ToDatabase -folderName "SYSTEM" `
                        -action "Disk Alanı Yetersiz" `
                        -status 0 `
                        -fileSize "$($diskSpace.FreeSpace) GB" `
                        -totalFileSize "$requiredSpace GB"
        
        return $false
    }
    return $true
}

# Dosya boyutunu formatlayan fonksiyon (B, KB, MB, GB, TB)
function Format-FileSize {
    param (
        [long]$size
    )
    $suffix = "B", "KB", "MB", "GB", "TB"
    $index = 0
    while ($size -gt 1024 -and $index -lt $suffix.Count) {
        $size = $size / 1024
        $index++
    }
    return "{0:N2} {1}" -f $size, $suffix[$index]
}

# İndirme hızını hesaplayan fonksiyon
function Get-DownloadSpeed {
    param (
        [long]$totalSize,
        [datetime]$startTime
    )
    $elapsedTime = (Get-Date) - $startTime
    if ($elapsedTime.TotalSeconds -eq 0) {
        return "0 MB/s"
    }
    $speed = $totalSize / $elapsedTime.TotalSeconds
    return "$([math]::Round($speed/1MB, 2)) MB/s"
}

# İndirilmiş klasörleri kontrol eden fonksiyon
function Get-DownloadedFolders {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        
        # BackupLogs tablosunda başarıyla indirilmiş klasörleri al
        $query = @"
            SELECT DISTINCT FolderName 
            FROM BackupLogs 
            WHERE Action = 'Indirme Tamamlandi' 
            AND Status = 1
"@
        
        Write-DebugLog "İndirilmiş klasörler kontrol ediliyor..." -Level "INFO"
        Write-DebugLog "SQL Sorgusu: $query" -Level "INFO"
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        
        $reader = $command.ExecuteReader()
        $downloadedFolders = @()
        
        while ($reader.Read()) {
            $downloadedFolders += $reader["FolderName"]
        }
        
        $reader.Close()
        $connection.Close()
        
        Write-DebugLog "Toplam $($downloadedFolders.Count) adet indirilmiş klasör bulundu." -Level "INFO"
        return $downloadedFolders
    }
    catch {
        Write-DebugLog "İndirilmiş klasörler kontrol hatası: $_" -Level "ERROR"
        return @()
    }
}

# Önceki işlem durumunu kontrol eden fonksiyon - İyileştirilmiş
# folderName: Kontrol edilecek klasör adı
# Dönüş: Önceki işlemin durumu, aksiyonu ve zamanı
function Get-PreviousStatus {
    param (
        [string]$folderName
    )
    
    if ([string]::IsNullOrWhiteSpace($folderName)) {
        Write-DebugLog "Warning: FolderName is empty in Get-PreviousStatus" -Level "WARNING"
        return $null
    }
    
    try {
        return Invoke-SafeDatabaseOperation {
            param($connection)
            
            $query = "SELECT Status, Action, Timestamp FROM BackupLogs WHERE FolderName = @folderName ORDER BY Timestamp DESC"
            $command = $connection.CreateCommand()
            $command.CommandText = $query
            $command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@folderName", $folderName)))
            
            $reader = $command.ExecuteReader()
            $result = @{
                Status = $null
                Action = $null
                Timestamp = $null
            }
            
            try {
                if ($reader.Read()) {
                    $result.Status = $reader["Status"]
                    $result.Action = $reader["Action"]
                    $result.Timestamp = $reader["Timestamp"]
                }
            }
            finally {
                $reader.Close()
            }
            
            return $result
        }
    } 
    catch {
        Write-DebugLog "Database read error for folder '$folderName': $($_.Exception.Message)" -Level "ERROR"
        return $null
    }
}

# WinSCP .NET assembly'sini yükle
try {
    Add-Type -Path "C:\Users\mustafa.ucarer\AppData\Local\Programs\WinSCP\WinSCPnet.dll"
    Write-DebugLog "WinSCP DLL başarıyla yüklendi" -Level "SUCCESS"
} 
catch [System.IO.FileNotFoundException] {
    Write-DebugLog "WinSCP DLL dosyası bulunamadı: C:\Program Files (x86)\WinSCP\WinSCPnet.dll" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "WinSCP DLL not found"
}
catch {
    Write-DebugLog "WinSCP DLL yükleme hatası: $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "WinSCP DLL load error"
}

# Gerekli dizinleri oluştur
try {
    New-Item -ItemType Directory -Path $localBackupPath -Force | Out-Null
    New-Item -ItemType Directory -Path $destinationPath -Force | Out-Null
}
catch {
    Write-DebugLog "Dizin oluşturma hatası: $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "Directory creation error"
}

# WinSCP oturumu oluştur
$global:session = $null
try {
    $global:session = New-Object WinSCP.Session
    $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
        Protocol = [WinSCP.Protocol]::Ftp
        HostName = $ftpHost
        UserName = $ftpUser
        Password = $ftpPassword
        Timeout = [TimeSpan]::FromSeconds(60)  # 60 saniye timeout
    }
    Write-DebugLog "WinSCP oturumu oluşturuldu" -Level "SUCCESS"
} 
catch {
    Write-DebugLog "WinSCP oturumu oluşturma hatası: $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "WinSCP session creation error"
}

# FTP bağlantısını aç
try {
    Write-DebugLog "FTP bağlantısı açılıyor..." -Level "INFO"
    $global:session.Open($sessionOptions)
    Write-DebugLog "FTP bağlantısı başarıyla açıldı" -Level "SUCCESS"
} 
catch [WinSCP.SessionException] {
    Write-DebugLog "FTP bağlantı hatası: $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "FTP connection error"
}
catch {
    Write-DebugLog "FTP bağlantı hatası (genel): $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "FTP connection error (general)"
}

# Log rotasyonunu başlat
Clean-OldLogs -logRetentionDays $logRetentionDays

# İndirme işlemi için transfer options - İyileştirilmiş
$transferOptions = New-Object WinSCP.TransferOptions
$transferOptions.ResumeSupport.State = [WinSCP.TransferResumeSupportState]::Off
$transferOptions.TransferMode = [WinSCP.TransferMode]::Binary
$transferOptions.FilePermissions = $null
$transferOptions.PreserveTimestamp = $false
$transferOptions.SpeedLimit = 0  # Hız sınırı yok
$transferOptions.OverwriteMode = [WinSCP.OverwriteMode]::Overwrite

# Transfer timeout ayarları
$global:session.Timeout = [TimeSpan]::FromMinutes(30)  # 30 dakika timeout

# İlerleme takibi için değişkenler
$progressUpdateInterval = 5  # saniye
$lastProgressUpdate = Get-Date
$lastDownloadedSize = 0

# Ana işlem akışı
Write-DebugLog "Script starting..." -Level "INFO"

# Veritabanı bağlantısını test et
Write-DebugLog "Testing database connection..." -Level "INFO"
if (-not (Test-DatabaseConnection)) {
    Write-DebugLog "Veritabani baglantisi kurulamadi, script sonlandiriliyor" -Level "ERROR"
    Write-Host "❌ Veritabanı bağlantısı başarısız! Bağlantı dizesi: $global:connectionString" -ForegroundColor Red
    Start-GracefulShutdown -ExitCode 1 -Reason "Database connection failed"
} else {
    Write-DebugLog "Database connection successful" -Level "SUCCESS"
    Write-Host "✅ Veritabanı bağlantısı başarılı!" -ForegroundColor Green
}

# İndirilmiş klasörleri al
$downloadedFolders = Get-DownloadedFolders

# İndirme işlemleri
foreach ($sourcePath in $sourcePaths) {
    Write-DebugLog "Kaynak dizin isleniyor: $sourcePath" -Level "INFO"
    
    # Disk alanı kontrolü
    if (-not (Check-DiskSpace -driveLetter "D" -requiredSpace $minimumRequiredSpace)) {
        Write-DebugLog "Yeterli disk alani yok!" -Level "ERROR"
        Start-GracefulShutdown -ExitCode 1 -Reason "Insufficient disk space"
    }

    try {
        $files = $global:session.ListDirectory($sourcePath)
        Write-DebugLog "Dizin listelendi: $($files.Files.Count) dosya/klasor bulundu" -Level "SUCCESS"
    } catch {
        Write-DebugLog "Dizin listeleme hatasi: $_" -Level "ERROR"
        continue
    }
    
    # Son 3 gün içindeki klasörleri filtrele
    $threeDaysAgo = (Get-Date).AddDays(-3)
    $recentFolders = $files.Files | Where-Object { $_.IsDirectory -and $_.LastWriteTime -ge $threeDaysAgo }
    Write-DebugLog "Son 3 gun icindeki klasor sayisi: $($recentFolders.Count)" -Level "INFO"

    # Her klasör için indirme işlemi
    foreach ($folder in $recentFolders) {
        $global:processedFolders++
        Write-DebugLog "Klasor isleniyor ($global:processedFolders): $($folder.Name)" -Level "INFO"
        
        # Eğer klasör daha önce indirilmişse atla
        if ($downloadedFolders -contains $folder.Name) {
            Write-DebugLog "Klasor daha once basariyla indirilmis. Atlaniyor: $($folder.Name)" -Level "WARNING"
            continue
        }
        
        $localFolderPath = Get-SafePath -BasePath $localBackupPath -SubPath $folder.Name
        $localFolderPath = "$localFolderPath\"
        
        try {
            New-Item -ItemType Directory -Path $localFolderPath -Force | Out-Null
        }
        catch {
            Write-DebugLog "Local folder creation error for '$($folder.Name)': $($_.Exception.Message)" -Level "ERROR"
            $global:failedFolders++
            continue
        }
        
        try {
            $remoteFiles = $global:session.ListDirectory("$sourcePath$($folder.Name)").Files
            Write-DebugLog "Uzak klasorde $($remoteFiles.Count) dosya bulundu" -Level "INFO"
            
            # Toplam boyut hesaplama
            $totalSize = 0
            foreach ($remoteFile in $remoteFiles) {
                if (-not $remoteFile.IsDirectory) {
                    $totalSize += $remoteFile.Length
                }
            }
            $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
            Write-DebugLog "Toplam dosya boyutu: $totalSizeMB MB" -Level "INFO"
            
            # İndirme başlangıcında toplam boyutu kaydet
            $startTime = Get-Date
            Write-ToDatabase -folderName $folder.Name `
                            -action "Indirme Basladi" `
                            -status 0 `
                            -totalFileSize "$totalSizeMB MB" `
                            -fileSize "0 MB" `
                            -duration "Indiriliyor"
            
            # İndirme işlemi
            $downloadedSize = 0
            foreach ($remoteFile in $remoteFiles) {
                if (-not $remoteFile.IsDirectory) {
                    $remoteFilePath = "$sourcePath$($folder.Name)/$($remoteFile.Name)"
                    $localFilePath = Join-Path -Path $localFolderPath -ChildPath $remoteFile.Name
                    
                    Write-DebugLog "Dosya indiriliyor: $($remoteFile.Name)" -Level "INFO"
                    
                    try {
                        $transferResult = $global:session.GetFiles($remoteFilePath, $localFilePath, $false, $transferOptions)
                        $transferResult.Check()
                        
                        # Dosya boyutu kontrolü
                        $remoteFileSize = $remoteFile.Length
                        $localFileSize = (Get-Item $localFilePath).Length
                        if ($remoteFileSize -ne $localFileSize) {
                            throw "Dosya boyutu uyusmuyor: $($remoteFile.Name)"
                        }
                        
                        $downloadedSize += $remoteFileSize
                        $downloadedSizeMB = [math]::Round($downloadedSize / 1MB, 2)
                        Write-DebugLog "Dosya indirildi: $($remoteFile.Name) ($([math]::Round($remoteFileSize/1MB, 2)) MB)" -Level "SUCCESS"
                    } catch {
                        Write-ErrorLog -FolderName $folder.Name `
                                     -ErrorMessage $_.Exception.Message `
                                     -ErrorType $_.Exception.GetType().Name `
                                     -FilePath $remoteFilePath
                        throw
                    }
                }
            }
            
            # İndirme tamamlandığında son durumu kaydet
            $endTime = Get-Date
            $duration = $endTime - $startTime
            $durationStr = "{0:D2}:{1:D2}:{2:D2}" -f $duration.Hours, $duration.Minutes, $duration.Seconds

            # Ortalama hız hesaplama (MB/s)
            $averageSpeed = if ($duration.TotalSeconds -gt 0) {
                [math]::Round($totalSizeMB / $duration.TotalSeconds, 2)
            } else {
                0
            }

            $localTotalSize = Get-FolderSize -folderPath $localFolderPath
            $localTotalSizeMB = [math]::Round($localTotalSize / 1MB, 2)
            Write-DebugLog "Indirme tamamlandi - FTP Boyutu: $totalSizeMB MB, Local Boyut: $localTotalSizeMB MB, Sure: $durationStr, Ortalama Hiz: $averageSpeed MB/s" -Level "SUCCESS"
            Write-ToDatabase -folderName $folder.Name `
                            -action "Indirme Tamamlandi" `
                            -status 1 `
                            -totalFileSize "$totalSizeMB MB" `
                            -fileSize "$localTotalSizeMB MB" `
                            -duration $durationStr `
                            -averageSpeed "$averageSpeed MB/s"
            
            # WatchFolder'a kopyala
            try {
                $destinationFolderPath = Join-Path -Path $destinationPath -ChildPath $folder.Name
                Copy-Item -Path $localFolderPath -Destination $destinationFolderPath -Recurse -Force
                Write-DebugLog "Klasor WatchFolder'a kopyalandi: $destinationFolderPath" -Level "SUCCESS"
                $global:successfulFolders++
            } catch {
                Write-ErrorLog -FolderName $folder.Name `
                             -ErrorMessage "WatchFolder kopyalama hatasi: $($_.Exception.Message)" `
                             -ErrorType $_.Exception.GetType().Name `
                             -FilePath $destinationFolderPath
                $global:failedFolders++
                throw
            }
        } catch {
            Write-DebugLog "Indirme hatasi: $_" -Level "ERROR"
            Remove-Item -Recurse -Force $localFolderPath -ErrorAction SilentlyContinue
            $global:failedFolders++
        }
    }
}

# Normal completion
Start-GracefulShutdown -ExitCode 0 -Reason "All operations completed successfully"

} 
catch {
    Write-DebugLog "Critical script error: $($_.Exception.Message)" -Level "ERROR"
    $global:failedFolders++
    Start-GracefulShutdown -ExitCode 1 -Reason "Critical script error: $($_.Exception.Message)"
}



