chcp 437 | Out-Null
function Write-DebugLog {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    if ($global:DebugMode) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Host "[$timestamp][$Level] $Message" -ForegroundColor $(switch ($Level) {
            "INFO" { "Cyan" }
            "WARNING" { "Yellow" }
            "ERROR" { "Red" }
            "SUCCESS" { "Green" }
            default { "White" }
        })
    }
}

# Güvenli path oluşturan fonksiyon
function Get-SafePath {
    param([string]$BasePath, [string]$SubPath)
    
    # Path traversal saldırılarını önle
    $sanitizedSubPath = $SubPath -replace '\.\.', '' -replace '[<>:"|?*]', '_'
    return Join-Path -Path $BasePath -ChildPath $sanitizedSubPath
}

# Güvenli database operation wrapper
function Invoke-SafeDatabaseOperation {
    param([scriptblock]$Operation)
    
    $connection = $null
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        return & $Operation $connection
    }
    catch [System.Data.SqlClient.SqlException] {
        Write-DebugLog "Database error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
    catch [System.InvalidOperationException] {
        Write-DebugLog "Database connection error: $($_.Exception.Message)" -Level "ERROR"
        throw
    }
    finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
            $connection.Dispose()
        }
    }
}

# Veritabanı bağlantısını test eden fonksiyon
function Test-DatabaseConnection {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($global:connectionString)
        $connection.Open()
        Write-DebugLog "Veritabani baglantisi basarili" -Level "SUCCESS"
        $connection.Close()
        return $true
    }
    catch {
        Write-DebugLog "Veritabani baglanti hatasi: $_" -Level "ERROR"
        Write-DebugLog "Baglanti dizesi: $global:connectionString" -Level "ERROR"
        return $false
    }
}

# Klasör boyutunu hesaplayan fonksiyon
function Get-FolderSize {
    param (
        [string]$folderPath
    )
    
    if ([string]::IsNullOrWhiteSpace($folderPath) -or -not (Test-Path $folderPath)) {
        Write-DebugLog "Invalid folder path: '$folderPath'" -Level "WARNING"
        return 0
    }
    
    try {
        # Büyük klasörler için stream işlemi
        $totalSize = 0
        Get-ChildItem -Path $folderPath -Recurse -File -ErrorAction SilentlyContinue | ForEach-Object {
            $totalSize += $_.Length
        }
        
        return $totalSize
    }
    catch [System.UnauthorizedAccessException] {
        Write-DebugLog "Access denied for folder: '$folderPath'" -Level "WARNING"
        return 0
    }
    catch {
        Write-DebugLog "Folder size calculation error for '$folderPath': $($_.Exception.Message)" -Level "ERROR"
        return 0
    }
}

# Güvenli boyut karşılaştırması yapan fonksiyon
function Compare-FolderSizes {
    param (
        [double]$previousSize,
        [double]$currentSize,
        [double]$tolerance = 1.0
    )
    
    $sizeDifference = [math]::Abs($previousSize - $currentSize)
    
    # Division by zero kontrolü
    $sizeDifferencePercentage = if ($previousSize -gt 0) {
        ($sizeDifference / $previousSize) * 100
    } else {
        # Önceki boyut 0 ise, sadece mutlak fark kontrol edilir
        if ($currentSize -le $tolerance) { 0 } else { 100 }
    }
    
    $isSizeSimilar = $sizeDifference -le $tolerance -or $sizeDifferencePercentage -le 0.1
    
    return @{
        SizeDifference = $sizeDifference
        SizeDifferencePercentage = $sizeDifferencePercentage
        IsSizeSimilar = $isSizeSimilar
    }
}

# Veritabanına log kaydı ekleyen fonksiyon
function Write-ToDatabase {
    param (
        [string]$folderName,
        [string]$action,
        [int]$status,
        [string]$duration = $null,
        [string]$fileSize = $null,
        [string]$averageSpeed = $null,
        [string]$totalFileSize = $null
    )
    
    if ([string]::IsNullOrWhiteSpace($folderName)) {
        Write-DebugLog "Warning: FolderName is empty for action '$action'" -Level "WARNING"
        return $false
    }
    
    try {
        return Invoke-SafeDatabaseOperation {
            param($connection)
            
            $timestamp = Get-Date

            # İlerleme durumu için UPDATE, diğer durumlar için INSERT
            if ($action -eq "Indirme Ilerlemesi") {
                $query = "UPDATE BackupLogs 
                         SET Timestamp = @timestamp,
                             TotalFileSize = @totalFileSize
                         WHERE ID = (
                             SELECT TOP 1 ID 
                             FROM BackupLogs 
                             WHERE FolderName = @folderName 
                             ORDER BY Timestamp DESC
                         )"
            } else {
                $query = "INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, LocationName, Duration, FileSize, AverageSpeed, TotalFileSize) 
                         VALUES (@folderName, @action, @timestamp, @status, @locationName, @duration, @fileSize, @averageSpeed, @totalFileSize)"
            }

            $command = $connection.CreateCommand()
            $command.CommandText = $query
            
            # Temel parametreler
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@folderName", $folderName)))
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@action", $action)))
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@timestamp", $timestamp)))
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@status", $status)))
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@locationName", $global:locationName)))
            
            # Opsiyonel parametreler
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@duration", [DBNull]::Value)))
            if ($duration) {
                $command.Parameters["@duration"].Value = $duration
            }
            
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@fileSize", [DBNull]::Value)))
            if ($fileSize) {
                $command.Parameters["@fileSize"].Value = $fileSize
            }
            
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@averageSpeed", [DBNull]::Value)))
            if ($averageSpeed) {
                $command.Parameters["@averageSpeed"].Value = $averageSpeed
            }
            
            [void]$command.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@totalFileSize", [DBNull]::Value)))
            if ($totalFileSize) {
                $command.Parameters["@totalFileSize"].Value = $totalFileSize
            }
            
            $rowsAffected = $command.ExecuteNonQuery()
            Write-DebugLog "Database write successful for folder '$folderName', action '$action' - Rows affected: $rowsAffected" -Level "SUCCESS"
            return $true
        }
    } 
    catch {
        Write-DebugLog "Database write error for folder '$folderName', action '$action': $($_.Exception.Message)" -Level "ERROR"
        Write-DebugLog "SQL Query: $($command.CommandText)" -Level "ERROR"
        return $false
    }
}

# Hata detaylarını loglayan fonksiyon
function Write-ErrorLog {
    param (
        [string]$FolderName,
        [string]$ErrorMessage,
        [string]$ErrorType,
        [string]$FilePath,
        [string]$Duration
    )
    $errorDetails = @{
        ErrorMessage = $ErrorMessage
        ErrorType = $ErrorType
        ErrorTime = Get-Date
        FolderName = $FolderName
        FilePath = $FilePath
    }
    
    Write-DebugLog "Error details for folder '$FolderName': $($errorDetails | ConvertTo-Json)" -Level "ERROR"
    
    Write-ToDatabase -folderName $FolderName `
                    -action "Process Error: $ErrorMessage" `
                    -status 0 `
                    -duration $Duration
}

# Eski logları temizleyen fonksiyon
function Clean-OldLogs {
    param (
        [int]$logRetentionDays = 30
    )
    try {
        Invoke-SafeDatabaseOperation {
            param($connection)
            
            $query = "DELETE FROM BackupLogs WHERE Timestamp < DATEADD(day, -$logRetentionDays, GETDATE())"
            $command = $connection.CreateCommand()
            $command.CommandText = $query
            $deletedCount = $command.ExecuteNonQuery()
            
            Write-Host "$deletedCount old log records cleaned." -ForegroundColor Yellow
            return $deletedCount
        }
    } 
    catch {
        Write-Host "Log cleaning error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Export functions
Export-ModuleMember -Function Write-DebugLog, Get-SafePath, Invoke-SafeDatabaseOperation, Test-DatabaseConnection, Get-FolderSize, Compare-FolderSizes, Write-ToDatabase, Write-ErrorLog, Clean-OldLogs 