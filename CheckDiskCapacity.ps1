# Disk kapasitesi kontrol script'i
# Bu script D: sürücüsünün kapasitesini kontrol eder ve veritabanına kaydeder

# Veritabanı Bağlantı Bilgileri
$connectionString = "Server=GMDCMUCARERNB;Database=MarsDcNocMVC;Trusted_Connection=True;TrustServerCertificate=True;"

# Debug log fonksiyonu
function Write-DebugLog {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp][$Level] $Message" -ForegroundColor $(switch ($Level) {
        "INFO" { "Cyan" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
}

# Disk kapasitesini alan fonksiyon
function Get-DiskCapacity {
    param (
        [string]$driveLetter
    )
    try {
        $drive = Get-PSDrive $driveLetter
        $totalSpace = [math]::Round($drive.Used / 1GB, 2)
        $freeSpace = [math]::Round($drive.Free / 1GB, 2)
        $usedSpace = [math]::Round(($drive.Used - $drive.Free) / 1GB, 2)
        
        return @{
            TotalSpace = $totalSpace
            FreeSpace = $freeSpace
            UsedSpace = $usedSpace
        }
    }
    catch {
        Write-DebugLog "Disk kapasitesi alınamadı: $_" -Level "ERROR"
        return $null
    }
}

# Veritabanına kayıt ekleyen/güncelleyen fonksiyon
function Write-ToDatabase {
    param (
        [double]$totalSpace,
        [double]$freeSpace,
        [double]$usedSpace
    )
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        
        $locationName = "Cevahir"
        $currentDate = Get-Date -Format "yyyy-MM-dd"
        
        # Önce bugün için kayıt var mı kontrol et
        $checkQuery = @"
            SELECT COUNT(*) FROM LocationLmsDiscCapacity 
            WHERE LocationName = @locationName 
            AND CAST(CheckDate AS DATE) = @currentDate
"@
        
        $checkCommand = $connection.CreateCommand()
        $checkCommand.CommandText = $checkQuery
        $checkCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@locationName", $locationName)))
        $checkCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@currentDate", $currentDate)))
        
        $recordCount = [int]$checkCommand.ExecuteScalar()
        
        if ($recordCount -gt 0) {
            # Kayıt varsa UPDATE yap
            Write-DebugLog "Bugün için '$locationName' lokasyonunda kayıt bulundu, güncelleniyor..." -Level "INFO"
            
            $updateQuery = @"
                UPDATE LocationLmsDiscCapacity 
                SET TotalSpace = @totalSpace, 
                    FreeSpace = @freeSpace, 
                    UsedSpace = @usedSpace, 
                    CheckDate = @checkDate
                WHERE LocationName = @locationName 
                AND CAST(CheckDate AS DATE) = @currentDate
"@
            
            $updateCommand = $connection.CreateCommand()
            $updateCommand.CommandText = $updateQuery
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@locationName", $locationName)))
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@totalSpace", $totalSpace)))
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@freeSpace", $freeSpace)))
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@usedSpace", $usedSpace)))
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@checkDate", (Get-Date))))
            $updateCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@currentDate", $currentDate)))
            
            $updateCommand.ExecuteNonQuery()
            Write-DebugLog "Disk kapasitesi veritabanında güncellendi" -Level "SUCCESS"
        }
        else {
            # Kayıt yoksa INSERT yap
            Write-DebugLog "Bugün için '$locationName' lokasyonunda kayıt bulunamadı, yeni kayıt oluşturuluyor..." -Level "INFO"
            
            $insertQuery = @"
                INSERT INTO LocationLmsDiscCapacity 
                (LocationName, TotalSpace, FreeSpace, UsedSpace, CheckDate) 
                VALUES 
                (@locationName, @totalSpace, @freeSpace, @usedSpace, @checkDate)
"@

            $insertCommand = $connection.CreateCommand()
            $insertCommand.CommandText = $insertQuery
            $insertCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@locationName", $locationName)))
            $insertCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@totalSpace", $totalSpace)))
            $insertCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@freeSpace", $freeSpace)))
            $insertCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@usedSpace", $usedSpace)))
            $insertCommand.Parameters.Add((New-Object Data.SqlClient.SqlParameter("@checkDate", (Get-Date))))
            
            $insertCommand.ExecuteNonQuery()
            Write-DebugLog "Disk kapasitesi veritabanına kaydedildi" -Level "SUCCESS"
        }
        
        $connection.Close()
        return $true
    }
    catch {
        Write-DebugLog "Veritabanı işlemi hatası: $_" -Level "ERROR"
        if ($connection.State -eq "Open") {
            $connection.Close()
        }
        return $false
    }
}

# Hata yakalama mekanizması
try {
    # Ana işlem akışı
    Write-DebugLog "Disk kapasitesi kontrolü başlıyor..." -Level "INFO"
    Write-DebugLog "Connection String: $connectionString" -Level "INFO"
    Write-DebugLog "Current User: $env:USERNAME" -Level "INFO"
    Write-DebugLog "Current Time: $(Get-Date)" -Level "INFO"

    # Database connection test
    Write-DebugLog "Veritabanı bağlantısı test ediliyor..." -Level "INFO"
    try {
        $testConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $testConnection.Open()
        Write-DebugLog "Veritabanı bağlantısı başarılı!" -Level "SUCCESS"
        $testConnection.Close()
    }
    catch {
        Write-DebugLog "Veritabanı bağlantı hatası: $($_.Exception.Message)" -Level "ERROR"
        Write-DebugLog "Connection String: $connectionString" -Level "ERROR"
        throw "Database connection failed"
    }

    # D: sürücüsünün kapasitesini al
    $diskInfo = Get-DiskCapacity -driveLetter "D"

    if ($diskInfo) {
        Write-DebugLog "D: sürücüsü kapasitesi:" -Level "INFO"
        Write-DebugLog "Toplam Alan: $($diskInfo.TotalSpace) GB" -Level "INFO"
        Write-DebugLog "Boş Alan: $($diskInfo.FreeSpace) GB" -Level "INFO"
        Write-DebugLog "Kullanılan Alan: $($diskInfo.UsedSpace) GB" -Level "INFO"
        
        # Veritabanına kaydet
        if (Write-ToDatabase -totalSpace $diskInfo.TotalSpace -freeSpace $diskInfo.FreeSpace -usedSpace $diskInfo.UsedSpace) {
            Write-DebugLog "İşlem başarıyla tamamlandı" -Level "SUCCESS"
        }
        else {
            Write-DebugLog "Veritabanına kayıt sırasında hata oluştu" -Level "ERROR"
            exit 1
        }
    }
    else {
        Write-DebugLog "Disk kapasitesi alınamadığı için işlem tamamlanamadı" -Level "ERROR"
        exit 1
    }

    Write-DebugLog "Script tamamlandı" -Level "INFO"
}
catch {
    Write-DebugLog "Kritik hata oluştu: $($_.Exception.Message)" -Level "ERROR"
    Write-DebugLog "Hata detayı: $($_.Exception.ToString())" -Level "ERROR"
    exit 1
}

# Normal completion
exit 0 