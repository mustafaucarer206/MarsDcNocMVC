# UTF-8 BOM ile encoding sorununu çöz
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

# Veritabanı bağlantı bilgileri
$connectionString = "Server=GMDCMUCARERNB;Database=MarsDCNocMVC;Integrated Security=True;"

# Log fonksiyonu
function Write-Log {
    param(
        [string]$Message,
        [string]$Severity = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] [$Severity] $Message"
}

# Ping Status çevirme fonksiyonu - ASCII karakterler kullan
function Get-PingStatusMessage {
    param(
        [string]$Status
    )
    
    switch ($Status) {
        'Success' { return 'Basarili' }
        'TimedOut' { return 'Zaman Asimi' }
        'DestinationHostUnreachable' { return 'Hedef Ulasilamaz' }
        'DestinationNetworkUnreachable' { return 'Ag Ulasilamaz' }
        'DestinationUnreachable' { return 'Hedef Ulasilamaz' }
        'HardwareError' { return 'Donanim Hatasi' }
        'PacketTooBig' { return 'Paket Cok Buyuk' }
        'TtlExpired' { return 'TTL Suresi Doldu' }
        'BadRoute' { return 'Kotu Rota' }
        'IcmpError' { return 'ICMP Hatasi' }
        'BadDestination' { return 'Gecersiz Hedef' }
        'BadHeader' { return 'Gecersiz Baslik' }
        'UnrecognizedNextHeader' { return 'Taninmayan Baslik' }
        'DestinationScopeMismatch' { return 'Hedef Kapsam Uyumsuzlugu' }
        default { return "Bilinmeyen Hata: $Status" }
    }
}

# Veritabanı bağlantısını test et
function Test-DatabaseConnection {
    try {
        Write-Host "Veritabanı bağlantısı test ediliyor..." -ForegroundColor Yellow
        Write-Host "Bağlantı dizesi: $connectionString" -ForegroundColor Yellow
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        Write-Host "Veritabanı bağlantısı başarılı!" -ForegroundColor Green
        $connection.Close()
        return $true
    }
    catch {
        Write-Host "Veritabanı bağlantı hatası: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "Lütfen SQL Server'ın çalıştığından ve bağlantı bilgilerinin doğru olduğundan emin olun." -ForegroundColor Red
        return $false
    }
}

# Ping kontrolü ve veritabanı işlemleri fonksiyonu
function Test-And-Save-ServerStatus {
    param(
        [string]$LocationName,
        [string]$ServerName,
        [string]$IPAddress
    )
    
    try {
        # Ping kontrolü
        $ping = New-Object System.Net.NetworkInformation.Ping
        $reply = $ping.Send($IPAddress, 5000)  # Timeout'u 5 saniyeye çıkar
        
        $isOnline = $reply.Status -eq 'Success'
        $responseTime = if ($isOnline) { $reply.RoundtripTime } else { $null }
        
        # ASCII karakterlerle hata mesajı
        $errorMessage = if (-not $isOnline) { 
            "Ping basarisiz: $(Get-PingStatusMessage -Status $reply.Status)" 
        } else { 
            $null 
        }
        
        $currentTime = Get-Date
        
        # Veritabanına kaydetme (UPSERT)
        $query = @"
        IF EXISTS (
            SELECT 1 FROM ServerPingStatus 
            WHERE LocationName = @LocationName 
            AND ServerName = @ServerName 
            AND IPAddress = @IPAddress
        )
        BEGIN
            -- Mevcut kaydı güncelle
            UPDATE ServerPingStatus 
            SET 
                IsOnline = @IsOnline,
                LastPingTime = @LastPingTime,
                ResponseTime = @ResponseTime,
                ErrorMessage = @ErrorMessage
            WHERE 
                LocationName = @LocationName 
                AND ServerName = @ServerName 
                AND IPAddress = @IPAddress
        END
        ELSE
        BEGIN
            -- Yeni kayıt ekle
            INSERT INTO ServerPingStatus (
                LocationName, ServerName, IPAddress, IsOnline, 
                LastPingTime, ResponseTime, ErrorMessage
            ) VALUES (
                @LocationName, @ServerName, @IPAddress, @IsOnline,
                @LastPingTime, @ResponseTime, @ErrorMessage
            )
        END
"@
        
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $command = New-Object System.Data.SqlClient.SqlCommand($query, $connection)
        
        $command.Parameters.AddWithValue("@LocationName", $LocationName)
        $command.Parameters.AddWithValue("@ServerName", $ServerName)
        $command.Parameters.AddWithValue("@IPAddress", $IPAddress)
        $command.Parameters.AddWithValue("@IsOnline", $isOnline)
        $command.Parameters.AddWithValue("@LastPingTime", $currentTime)
        $command.Parameters.AddWithValue("@ResponseTime", [DBNull]::Value)
        if ($responseTime) {
            $command.Parameters["@ResponseTime"].Value = $responseTime
        }
        $command.Parameters.AddWithValue("@ErrorMessage", [DBNull]::Value)
        if ($errorMessage) {
            $command.Parameters["@ErrorMessage"].Value = $errorMessage
        }
        
        $connection.Open()
        $command.ExecuteNonQuery()
        $connection.Close()
        
        # Sonuçları ekranda göster
        $status = if ($isOnline) { "Çevrimiçi" } else { "Çevrimdışı" }
        $color = if ($isOnline) { "Green" } else { "Red" }
        
        Write-Host "`nSunucu: $ServerName" -ForegroundColor Yellow
        Write-Host "Lokasyon: $LocationName"
        Write-Host "IP: $IPAddress"
        Write-Host "Durum: $status" -ForegroundColor $color
        if ($isOnline) {
            Write-Host "Yanıt Süresi: $responseTime ms"
        } else {
            Write-Host "Hata: $errorMessage" -ForegroundColor Red
        }
        Write-Host "Kontrol Zamanı: $($currentTime.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "Veritabanına kaydedildi: Evet" -ForegroundColor Green
        Write-Host "----------------------------------------"
        
        return $true
    }
    catch {
        Write-Host "Hata: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# JSON dosyasından sunucu listesini okuma fonksiyonu
function Get-ServerList {
    param(
        [string]$JsonPath = ".\servers.json"
    )
    
    try {
        if (-not (Test-Path $JsonPath)) {
            throw "Sunucu listesi dosyası bulunamadı: $JsonPath"
        }
        
        $jsonContent = Get-Content $JsonPath -Raw -Encoding UTF8
        $serverList = ConvertFrom-Json $jsonContent
        
        if (-not $serverList.servers) {
            throw "JSON dosyası geçerli bir sunucu listesi içermiyor"
        }
        
        return $serverList.servers
    }
    catch {
        Write-Host "Sunucu listesi okuma hatası: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

# Ana işlem
try {
    Write-Host "`n=== Sunucu Ping Kontrolü Başlatılıyor ===`n" -ForegroundColor Cyan
    
    # Veritabanı bağlantısını test et
    if (-not (Test-DatabaseConnection)) {
        Write-Host "Veritabanı bağlantısı başarısız olduğu için işlem iptal ediliyor." -ForegroundColor Red
        exit
    }
    
    # Sunucu listesini JSON dosyasından oku
    $servers = Get-ServerList
    $successCount = 0
    $failCount = 0
    
    foreach ($server in $servers) {
        $result = Test-And-Save-ServerStatus `
            -LocationName $server.locationName `
            -ServerName $server.serverName `
            -IPAddress $server.ipAddress
            
        if ($result) { $successCount++ } else { $failCount++ }
    }
    
    Write-Host "`n=== Kontrol Tamamlandı ===" -ForegroundColor Cyan
    Write-Host "Başarılı: $successCount" -ForegroundColor Green
    Write-Host "Başarısız: $failCount" -ForegroundColor Red
    Write-Host "Toplam: $($servers.Count)`n"
}
catch {
    Write-Host "Genel hata: $($_.Exception.Message)" -ForegroundColor Red
} 