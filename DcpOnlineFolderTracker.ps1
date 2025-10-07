param (
    [string]$dcpOnlinePath = "D:\DCP Online\",
    [string]$watchFolderPath = "D:\WatchFolder\",
    [int]$stableWaitMinutes = 0,
    [int]$oldFolderHours = 72,
    [switch]$DebugMode
)

Import-Module "$PSScriptRoot\CommonFunctions.psm1" -Force

$global:DebugMode = $DebugMode
$global:locationName = "Cevahir"
$global:connectionString = "Server=GMDCMUCARERNB;Database=MarsDcNocMVC;Trusted_Connection=True;TrustServerCertificate=True;"
$global:scriptStartTime = Get-Date
$global:scriptStatus = "Running"
$global:totalFoldersChecked = 0
$global:newFoldersFound = 0
$global:stableFolders = 0
$global:copiedFolders = 0
$global:failedCopies = 0
$global:oldFoldersDeleted = 0
$global:skippedDueToBackup = 0

Write-DebugLog "=== DCP Online Folder Tracker Başlatılıyor ===" -Level "INFO"
Write-DebugLog "Start Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -Level "INFO"
Write-DebugLog "DCP Online Path: $dcpOnlinePath" -Level "INFO"
Write-DebugLog "Watch Folder Path: $watchFolderPath" -Level "INFO"
Write-DebugLog "Stable Wait Time: $stableWaitMinutes dakika" -Level "INFO"
Write-DebugLog "Old Folder Cleanup: $oldFolderHours saat" -Level "INFO"

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
    Write-DebugLog "=== İSTATİSTİKLER ===" -Level "INFO"
    Write-DebugLog "Toplam Kontrol Edilen Klasör: $global:totalFoldersChecked" -Level "INFO"
    Write-DebugLog "Yeni Bulunan Klasör: $global:newFoldersFound" -Level "INFO"
    Write-DebugLog "Stabil Klasör: $global:stableFolders" -Level "INFO"
    Write-DebugLog "Başarıyla Kopyalanan: $global:copiedFolders" -Level "SUCCESS"
    Write-DebugLog "Kopyalama Başarısız: $global:failedCopies" -Level $(if ($global:failedCopies -gt 0) { "ERROR" } else { "INFO" })
    Write-DebugLog "BackupLogs'da İşlenmiş (Atlanan): $global:skippedDueToBackup" -Level "INFO"
    Write-DebugLog "Silinen Eski Klasör: $global:oldFoldersDeleted" -Level "INFO"
    
    Write-DebugLog "BackupLogs cleanup disabled - logs will be preserved" -Level "INFO"
    
    $statusColor = if ($ExitCode -eq 0) { "Green" } else { "Red" }
    $statusMessage = if ($ExitCode -eq 0) { 
        "✅ DCP Online Folder Tracker başarıyla tamamlandı!" 
    } else { 
        "❌ DCP Online Folder Tracker hatalarla tamamlandı!" 
    }
    
    Write-DebugLog "=== SCRIPT SHUTDOWN TAMAMLANDI ===" -Level $(if ($ExitCode -eq 0) { "SUCCESS" } else { "ERROR" })
    Write-Host $statusMessage -ForegroundColor $statusColor
    Write-Host "Süre: $durationStr | Kontrol: $global:totalFoldersChecked | Kopyalanan: $global:copiedFolders | Başarısız: $global:failedCopies | BackupLogs İşlenmiş: $global:skippedDueToBackup | Silinen: $global:oldFoldersDeleted" -ForegroundColor Cyan
    
    exit $ExitCode
}

Register-EngineEvent -SourceIdentifier PowerShell.Exiting -Action {
    Write-Host "`n🛑 Script interrupted by user" -ForegroundColor Yellow
    Start-GracefulShutdown -ExitCode 130 -Reason "User Interruption"
}

function Get-FolderStatus {
    param (
        [string]$folderName,
        [double]$currentSizeKB
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        
        $query = @"
            SELECT TOP 1 FileSize, LastCheckDate, Status 
            FROM DcpOnlineFolderTracking 
            WHERE FolderName = @folderName 
            ORDER BY LastCheckDate DESC
"@
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $command.Parameters.AddWithValue("@folderName", $folderName)
        
        $reader = $command.ExecuteReader()
        
        if ($reader.Read()) {
            $lastSize = if ($reader["FileSize"] -ne [DBNull]::Value) { [double]$reader["FileSize"] } else { 0 }
            $lastCheck = [datetime]$reader["LastCheckDate"]
            $status = $reader["Status"].ToString()
            
            $reader.Close()
            $connection.Close()
            
            return @{
                Exists = $true
                LastSize = $lastSize
                LastCheck = $lastCheck
                Status = $status
                IsStable = ($lastSize -eq $currentSizeKB)
                MinutesSinceLastChange = ((Get-Date) - $lastCheck).TotalMinutes
            }
        } else {
            $reader.Close()
            $connection.Close()
            
            return @{
                Exists = $false
                IsStable = $false
                MinutesSinceLastChange = 0
            }
        }
    }
    catch {
        Write-DebugLog "Folder status kontrol hatası: $($_.Exception.Message)" -Level "ERROR"
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        return @{ Exists = $false; IsStable = $false; MinutesSinceLastChange = 0 }
    }
}

function Update-FolderStatusWithProcessed {
    param (
        [string]$folderName,
        [double]$sizeKB,
        [string]$status,
        [bool]$isProcessed = $false
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        
        # Klasör var mı kontrol et
        $checkQuery = "SELECT COUNT(*) FROM DcpOnlineFolderTracking WHERE FolderName = @folderName"
        $checkCommand = $connection.CreateCommand()
        $checkCommand.CommandText = $checkQuery
        $checkCommand.Parameters.AddWithValue("@folderName", $folderName)
        $exists = [int]$checkCommand.ExecuteScalar() -gt 0
        
        if ($exists) {
            # Güncelle
            $updateQuery = @"
                UPDATE DcpOnlineFolderTracking 
                SET FileSize = @fileSize, 
                    LastCheckDate = @lastCheckDate, 
                    Status = @status,
                    IsProcessed = @isProcessed,
                    LocationName = @locationName
                WHERE FolderName = @folderName
"@
            $updateCommand = $connection.CreateCommand()
            $updateCommand.CommandText = $updateQuery
            $updateCommand.Parameters.AddWithValue("@fileSize", $sizeKB)
            $updateCommand.Parameters.AddWithValue("@lastCheckDate", (Get-Date))
            $updateCommand.Parameters.AddWithValue("@status", $status)
            $updateCommand.Parameters.AddWithValue("@isProcessed", $isProcessed)
            $updateCommand.Parameters.AddWithValue("@locationName", $global:locationName)
            $updateCommand.Parameters.AddWithValue("@folderName", $folderName)
            $updateCommand.ExecuteNonQuery()
        } else {
            # Yeni kayıt ekle
            $insertQuery = @"
                INSERT INTO DcpOnlineFolderTracking 
                (FolderName, FirstSeenDate, LastCheckDate, FileSize, Status, IsProcessed, LocationName) 
                VALUES (@folderName, @firstSeenDate, @lastCheckDate, @fileSize, @status, @isProcessed, @locationName)
"@
            $insertCommand = $connection.CreateCommand()
            $insertCommand.CommandText = $insertQuery
            $insertCommand.Parameters.AddWithValue("@folderName", $folderName)
            $insertCommand.Parameters.AddWithValue("@firstSeenDate", (Get-Date))
            $insertCommand.Parameters.AddWithValue("@lastCheckDate", (Get-Date))
            $insertCommand.Parameters.AddWithValue("@fileSize", $sizeKB)
            $insertCommand.Parameters.AddWithValue("@status", $status)
            $insertCommand.Parameters.AddWithValue("@isProcessed", $isProcessed)
            $insertCommand.Parameters.AddWithValue("@locationName", $global:locationName)
            $insertCommand.ExecuteNonQuery()
            
            # Yeni klasör sayacını artır
            $global:newFoldersFound++
        }
        
        $connection.Close()
        return $true
    }
    catch {
        Write-DebugLog "Folder status güncelleme hatası: $($_.Exception.Message)" -Level "ERROR"
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        return $false
    }
}

# Klasör durumunu güncelle
function Update-FolderStatus {
    param (
        [string]$folderName,
        [double]$sizeKB,
        [string]$status
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        
        # Klasör var mı kontrol et
        $checkQuery = "SELECT COUNT(*) FROM DcpOnlineFolderTracking WHERE FolderName = @folderName"
        $checkCommand = $connection.CreateCommand()
        $checkCommand.CommandText = $checkQuery
        $checkCommand.Parameters.AddWithValue("@folderName", $folderName)
        $exists = [int]$checkCommand.ExecuteScalar() -gt 0
        
        if ($exists) {
            # Güncelle
            $updateQuery = @"
                UPDATE DcpOnlineFolderTracking 
                SET FileSize = @fileSize, 
                    LastCheckDate = @lastCheckDate, 
                    Status = @status,
                    LocationName = @locationName
                WHERE FolderName = @folderName
"@
            $updateCommand = $connection.CreateCommand()
            $updateCommand.CommandText = $updateQuery
            $updateCommand.Parameters.AddWithValue("@fileSize", $sizeKB)
            $updateCommand.Parameters.AddWithValue("@lastCheckDate", (Get-Date))
            $updateCommand.Parameters.AddWithValue("@status", $status)
            $updateCommand.Parameters.AddWithValue("@locationName", $global:locationName)
            $updateCommand.Parameters.AddWithValue("@folderName", $folderName)
            $updateCommand.ExecuteNonQuery()
        } else {
            # Yeni kayıt ekle
            $insertQuery = @"
                INSERT INTO DcpOnlineFolderTracking 
                (FolderName, FirstSeenDate, LastCheckDate, FileSize, Status, IsProcessed, LocationName) 
                VALUES (@folderName, @firstSeenDate, @lastCheckDate, @fileSize, @status, 0, @locationName)
"@
            $insertCommand = $connection.CreateCommand()
            $insertCommand.CommandText = $insertQuery
            $insertCommand.Parameters.AddWithValue("@folderName", $folderName)
            $insertCommand.Parameters.AddWithValue("@firstSeenDate", (Get-Date))
            $insertCommand.Parameters.AddWithValue("@lastCheckDate", (Get-Date))
            $insertCommand.Parameters.AddWithValue("@fileSize", $sizeKB)
            $insertCommand.Parameters.AddWithValue("@status", $status)
            $insertCommand.Parameters.AddWithValue("@locationName", $global:locationName)
            $insertCommand.ExecuteNonQuery()
            
            # Yeni klasör sayacını artır
            $global:newFoldersFound++
        }
        
        $connection.Close()
        return $true
    }
    catch {
        Write-DebugLog "Folder status güncelleme hatası: $($_.Exception.Message)" -Level "ERROR"
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
        }
        return $false
    }
}

# Klasörü WatchFolder'a kopyala
function Copy-ToWatchFolder {
    param (
        [string]$folderName,
        [string]$sourcePath
    )
    
    $destinationPath = Get-SafePath -BasePath $watchFolderPath -SubPath $folderName
    
    # Hedef klasör zaten var mı?
    if (Test-Path $destinationPath) {
        Write-DebugLog "$folderName zaten WatchFolder'da mevcut. Atlanıyor." -Level "WARNING"
        return $true
    }
    
    try {
        Write-DebugLog "$folderName WatchFolder'a kopyalanıyor..." -Level "INFO"
        Copy-Item -Path $sourcePath -Destination $destinationPath -Recurse -Force
        Write-DebugLog "$folderName başarıyla kopyalandı." -Level "SUCCESS"
        
        # Durumu güncelle - IsProcessed = true olarak işaretle
        Update-FolderStatusWithProcessed -folderName $folderName -sizeKB (Get-FolderSize $sourcePath | ForEach-Object { [math]::Round($_ / 1KB, 2) }) -status "MovedToWatchFolder" -isProcessed $true
        
        # Başarılı kopyalama sayacını artır
        $global:copiedFolders++
        
        return $true
    }
    catch {
        Write-DebugLog "$folderName kopyalama hatası: $($_.Exception.Message)" -Level "ERROR"
        Update-FolderStatus -folderName $folderName -sizeKB 0 -status "CopyError"
        
        # Başarısız kopyalama sayacını artır
        $global:failedCopies++
        
        return $false
    }
}

# BackupLogs'da işlenmiş klasörleri al (başarılı, hatalı, indiriliyor - hepsini dahil et)
function Get-BackupProcessedFolders {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        
        # BackupLogs tablosunda herhangi bir şekilde işlenmiş klasörleri al
        $query = @"
            SELECT DISTINCT FolderName 
            FROM BackupLogs
"@
        
        Write-DebugLog "BackupLogs'dan işlenmiş klasörler kontrol ediliyor..." -Level "INFO"
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        
        $reader = $command.ExecuteReader()
        $processedFolders = @()
        
        while ($reader.Read()) {
            $processedFolders += $reader["FolderName"]
        }
        
        $reader.Close()
        $connection.Close()
        
        Write-DebugLog "BackupLogs'da $($processedFolders.Count) adet işlenmiş klasör bulundu." -Level "INFO"
        return $processedFolders
    }
    catch {
        Write-DebugLog "BackupLogs kontrol hatası: $_" -Level "ERROR"
        return @()
    }
}

# Ana klasör kontrol fonksiyonu
function Process-DcpOnlineFolders {
    Write-DebugLog "DCP Online klasörler kontrol ediliyor..." -Level "INFO"
    
    # DCP Online klasörünün varlığını kontrol et
    if (-not (Test-Path $dcpOnlinePath)) {
        Write-DebugLog "DCP Online klasörü bulunamadı: $dcpOnlinePath" -Level "ERROR"
        Start-GracefulShutdown -ExitCode 1 -Reason "DCP Online folder not found"
    }
    
    # BackupLogs'dan işlenmiş klasörleri al (başarılı/hatalı/indiriliyor - hepsini dahil et)
    $backupProcessedFolders = Get-BackupProcessedFolders
    
    # Tüm klasörleri al
    $folders = Get-ChildItem -Path $dcpOnlinePath -Directory
    Write-DebugLog "Toplam $($folders.Count) klasör bulundu" -Level "INFO"
    
    foreach ($folder in $folders) {
        $global:totalFoldersChecked++
        $folderName = $folder.Name
        $folderPath = $folder.FullName
        
        Write-DebugLog "Kontrol ediliyor ($global:totalFoldersChecked/$($folders.Count)): $folderName" -Level "INFO"
        
        # BackupLogs'da zaten işlenmiş mi kontrol et (başarılı/hatalı/indiriliyor durumu fark etmez)
        if ($backupProcessedFolders -contains $folderName) {
            Write-DebugLog "⚠️ $folderName zaten BackupLogs'da işlenmiş (başarılı/hatalı/indiriliyor). DCP Online Tracker işlemi atlanıyor." -Level "WARNING"
            $global:skippedDueToBackup++
            continue
        }
        
        # Klasör boyutunu hesapla
        $folderSize = Get-FolderSize -folderPath $folderPath
        $folderSizeKB = [math]::Round($folderSize / 1KB, 2)
        Write-DebugLog "$folderName boyutu: $folderSizeKB KB" -Level "INFO"
        
        # Klasörün durumunu al
        $status = Get-FolderStatus -folderName $folderName -currentSizeKB $folderSizeKB
        
        if (-not $status.Exists) {
            # 1. İLK KONTROL: Yeni klasör
            Write-DebugLog "$folderName yeni klasör. Veritabanına ekleniyor (Status: New, IsProcessed: false)." -Level "INFO"
            Update-FolderStatus -folderName $folderName -sizeKB $folderSizeKB -status "New"
        }
        elseif ($status.Status -eq "New" -and $status.IsStable -and $status.MinutesSinceLastChange -ge $stableWaitMinutes) {
            # 2. İKİNCİ KONTROL: 5+ dakika boyut değişmemiş -> Stable yap
            Write-DebugLog "$folderName stabil hale geldi ($([math]::Round($status.MinutesSinceLastChange, 1)) dakika boyut değişmemiş). Status: Stable yapılıyor." -Level "SUCCESS"
            Update-FolderStatus -folderName $folderName -sizeKB $folderSizeKB -status "Stable"
        }
        elseif ($status.Status -eq "Stable" -and $status.IsStable) {
            # 3. ÜÇÜNCÜ KONTROL: Stable durumda -> WatchFolder'a kopyala
            $global:stableFolders++
            Write-DebugLog "$folderName stabil durumda. WatchFolder'a kopyalanıyor." -Level "SUCCESS"
            
            if (Copy-ToWatchFolder -folderName $folderName -sourcePath $folderPath) {
                Write-DebugLog "$folderName başarıyla işlendi (Status: MovedToWatchFolder, IsProcessed: true)." -Level "SUCCESS"
            }
        }
        elseif (-not $status.IsStable) {
            # BOYUT DEĞİŞMİŞ: Boyut değiştiğinde tekrar New yap
            Write-DebugLog "$folderName boyutu değişmiş. Önceki: $($status.LastSize) KB, Yeni: $folderSizeKB KB. Status: New'e döndürülüyor." -Level "WARNING"
            Update-FolderStatus -folderName $folderName -sizeKB $folderSizeKB -status "New"
        }
        else {
            # HENÜZ BEKLEMEDE: Yeterince zaman geçmemiş
            $remainingMinutes = $stableWaitMinutes - $status.MinutesSinceLastChange
            Write-DebugLog "$folderName daha $([math]::Round($remainingMinutes, 1)) dakika beklemeli (Status: $($status.Status))." -Level "INFO"
        }
    }
    
    Write-DebugLog "Klasör kontrolü tamamlandı. İşlem özeti:" -Level "INFO"
    Write-DebugLog "  - Toplam kontrol edilen: $global:totalFoldersChecked" -Level "INFO"
    Write-DebugLog "  - Yeni bulunan: $global:newFoldersFound" -Level "INFO"
    Write-DebugLog "  - Stabil olan: $global:stableFolders" -Level "INFO"
    Write-DebugLog "  - Başarıyla kopyalanan: $global:copiedFolders" -Level "SUCCESS"
    Write-DebugLog "  - Kopyalama başarısız: $global:failedCopies" -Level $(if ($global:failedCopies -gt 0) { "ERROR" } else { "INFO" })
}

# Eski klasörleri temizle
function Clean-OldFolders {
    Write-DebugLog "Eski klasörler temizleniyor ($oldFolderHours saatten eski)..." -Level "INFO"
    
    if (-not (Test-Path $dcpOnlinePath)) {
        return
    }
    
    $cutoffTime = (Get-Date).AddHours(-$oldFolderHours)
    $oldFolders = Get-ChildItem -Path $dcpOnlinePath -Directory | Where-Object { $_.LastWriteTime -lt $cutoffTime }
    
    if ($oldFolders.Count -eq 0) {
        Write-DebugLog "Silinecek eski klasör bulunamadı." -Level "INFO"
        return
    }
    
    Write-DebugLog "$($oldFolders.Count) eski klasör bulundu. Siliniyor..." -Level "WARNING"
    
    foreach ($oldFolder in $oldFolders) {
        try {
            Write-DebugLog "$($oldFolder.Name) klasörü siliniyor (Son değişiklik: $($oldFolder.LastWriteTime))..." -Level "WARNING"
            
            # Veritabanından sil - Devre dışı bırakıldı (kayıtlar korunacak)
            # $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
            # $connection.Open()
            # $deleteQuery = "DELETE FROM DcpOnlineFolderTracking WHERE FolderName = @folderName"
            # $deleteCommand = $connection.CreateCommand()
            # $deleteCommand.CommandText = $deleteQuery
            # $deleteCommand.Parameters.AddWithValue("@folderName", $oldFolder.Name)
            # $deleteCommand.ExecuteNonQuery()
            # $connection.Close()
            Write-DebugLog "$($oldFolder.Name) fiziksel olarak siliniyor ancak DcpOnlineFolderTracking kaydı korunuyor" -Level "INFO"
            
            # Fiziksel olarak sil
            Remove-Item -Path $oldFolder.FullName -Recurse -Force
            
            # Silinen klasör sayacını artır
            $global:oldFoldersDeleted++
            
            Write-DebugLog "$($oldFolder.Name) başarıyla silindi." -Level "SUCCESS"
        }
        catch {
            Write-DebugLog "$($oldFolder.Name) silme hatası: $($_.Exception.Message)" -Level "ERROR"
        }
    }
    
    Write-DebugLog "Eski klasör temizliği tamamlandı. Silinen klasör sayısı: $global:oldFoldersDeleted" -Level "INFO"
}

# Ana işlem başlat
try {
    # Veritabanı bağlantısını test et
    if (-not (Test-DatabaseConnection)) {
        Write-DebugLog "Veritabanı bağlantısı kurulamadı!" -Level "ERROR"
        Start-GracefulShutdown -ExitCode 1 -Reason "Database connection failed"
    }
    
    # Gerekli dizinleri oluştur
    if (-not (Test-Path $watchFolderPath)) {
        New-Item -ItemType Directory -Path $watchFolderPath -Force | Out-Null
        Write-DebugLog "WatchFolder oluşturuldu: $watchFolderPath" -Level "INFO"
    }
    
    # Ana işlemleri çalıştır
    Process-DcpOnlineFolders
    Clean-OldFolders
    
    # Normal completion - tüm işlemler başarıyla tamamlandı
    Start-GracefulShutdown -ExitCode 0 -Reason "All operations completed successfully"
}
catch {
    Write-DebugLog "Kritik hata: $($_.Exception.Message)" -Level "ERROR"
    Start-GracefulShutdown -ExitCode 1 -Reason "Critical error: $($_.Exception.Message)"
} 