# Tum LMS JSON Dosyalarini MSSQL'e Aktar
# NOC sunucusunda calistirilir

param(
    [string]$JsonFolder = ".\LMSScans",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC"
)

function Write-Log {
    param([string]$Message, [string]$Type = "INFO")
    $color = switch ($Type) {
        "SUCCESS" { "Green" }
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        default { "Cyan" }
    }
    Write-Host $Message -ForegroundColor $color
}

Write-Log "`n=== TUM LMS JSON DOSYALARINI AKTARMA ===" "INFO"

# JSON klasorunu kontrol et
if (-not (Test-Path $JsonFolder)) {
    Write-Log "JSON klasoru bulunamadi, olusturuluyor: $JsonFolder" "WARNING"
    New-Item -ItemType Directory -Path $JsonFolder -Force | Out-Null
}

# JSON dosyalarini bul
$jsonFiles = Get-ChildItem -Path $JsonFolder -Filter "active_content_*.json" -ErrorAction SilentlyContinue

if ($jsonFiles.Count -eq 0) {
    Write-Log "HATA: JSON dosyasi bulunamadi!" "ERROR"
    Write-Log "Klasor: $JsonFolder" "INFO"
    Write-Log "`nLMS sunucularindan JSON dosyalarini buraya kopyalayin:" "WARNING"
    Write-Log "  $JsonFolder\" "INFO"
    exit 1
}

Write-Log "Bulunan JSON dosyasi sayisi: $($jsonFiles.Count)" "SUCCESS"
foreach ($file in $jsonFiles) {
    Write-Log "  - $($file.Name)" "INFO"
}

# Movies tablosunu temizle
Write-Log "`nMevcut Movies tablosu temizleniyor..." "WARNING"
$confirmClear = Read-Host "Devam etmek istiyor musunuz? (E/H)"
if ($confirmClear -ne 'E' -and $confirmClear -ne 'e') {
    Write-Log "Iptal edildi." "WARNING"
    exit 0
}

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b
Write-Log "OK: Movies tablosu temizlendi.`n" "SUCCESS"

# Her JSON dosyasini isle
$totalMovies = 0
$locationMapping = @{}

foreach ($jsonFile in $jsonFiles) {
    try {
        Write-Log "Isleniyor: $($jsonFile.Name)" "INFO"
        
        $jsonData = Get-Content $jsonFile.FullName -Raw | ConvertFrom-Json
        
        # Location name'i computer name'den çıkar veya manuel map et
        $computerName = $jsonData.ComputerName
        $locationName = $computerName -replace '-LMS', '' -replace 'LMS-', ''
        
        # Feature filmleri filtrele
        $featureMovies = $jsonData.Content | Where-Object { $_.ContentKind -eq 'feature' }
        
        Write-Log "  Location: $locationName" "INFO"
        Write-Log "  Feature filmler: $($featureMovies.Count)" "INFO"
        
        $batchSize = 50
        $batch = @()
        $insertCount = 0
        
        foreach ($movie in $featureMovies) {
            try {
                $filmAdi = ($movie.ContentTitle -replace "'", "''")
                $sure = if ($movie.DurationMinutes) { $movie.DurationMinutes } else { 0 }
                $boyut = if ($movie.SizeGB) { $movie.SizeGB } else { 0 }
                
                if ($filmAdi) {
                    $values = "(N'$filmAdi', $sure, $boyut, N'$locationName', N'LMS', N'feature')"
                    $batch += $values
                }
                
                if ($batch.Count -ge $batchSize) {
                    $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
                    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
                    if ($LASTEXITCODE -eq 0) { 
                        $insertCount += $batch.Count 
                    }
                    $batch = @()
                }
            } catch {
                Write-Log "    UYARI: Film eklenemedi: $($movie.ContentTitle)" "WARNING"
            }
        }
        
        # Son batch
        if ($batch.Count -gt 0) {
            $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
            sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
        }
        
        Write-Log "  OK: $insertCount film eklendi`n" "SUCCESS"
        $totalMovies += $insertCount
        $locationMapping[$locationName] = $insertCount
        
    } catch {
        Write-Log "  HATA: JSON parse hatasi: $_" "ERROR"
    }
}

Write-Log "=== TUM LMS'LER AKTARILDI ===" "SUCCESS"
Write-Log "Toplam film sayisi: $totalMovies" "INFO"
Write-Log "`nLokasyon bazinda:" "INFO"
foreach ($loc in $locationMapping.Keys | Sort-Object) {
    Write-Log "  $loc : $($locationMapping[$loc]) film" "INFO"
}

# Duplicate temizle
Write-Log "`nDuplicate'ler temizleniyor..." "INFO"
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "USE [$MssqlDatabase]; WITH DuplicateMovies AS (SELECT Id, ROW_NUMBER() OVER (PARTITION BY FilmAdi, Lokasyon ORDER BY Id) as rn FROM Movies) DELETE FROM Movies WHERE Id IN (SELECT Id FROM DuplicateMovies WHERE rn > 1);" -b 2>&1 | Out-Null
Write-Log "OK: Duplicate'ler temizlendi.`n" "SUCCESS"

# Ozet
$summarySql = @"
USE [$MssqlDatabase];
SELECT 
    Lokasyon,
    COUNT(*) AS FilmSayisi,
    SUM(Boyut_GB) AS ToplamBoyutGB
FROM Movies
GROUP BY Lokasyon
ORDER BY Lokasyon;
"@

Write-Log "=== FINAL OZET ===" "INFO"
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

Write-Log "`n=== TAMAMLANDI ===" "SUCCESS"
Write-Log "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" "INFO"

