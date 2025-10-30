# LMS JSON'dan MSSQL'e Film Aktarımı
param(
    [string]$JsonFile = "active_content.json",
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

Write-Log "`n=== LMS JSON'DAN MSSQL'E AKTARIM ===" "INFO"

# JSON dosyasını oku
if (-not (Test-Path $JsonFile)) {
    Write-Log "HATA: JSON dosyasi bulunamadi: $JsonFile" "ERROR"
    exit 1
}

Write-Log "JSON dosyasi okunuyor: $JsonFile" "INFO"
$jsonData = Get-Content $JsonFile -Raw | ConvertFrom-Json

Write-Log "Scan Tarihi: $($jsonData.ScanDate)" "INFO"
Write-Log "Scan Path: $($jsonData.ScanPath)" "INFO"
Write-Log "Toplam Icerik: $($jsonData.TotalContent)" "INFO"
Write-Log "Feature Filmler: $($jsonData.FeatureCount)`n" "INFO"

# Movies tablosunu temizle
Write-Log "Mevcut Movies tablosu temizleniyor..." "WARNING"
$confirmClear = Read-Host "Movies tablosunu temizlemek istiyor musunuz? (E/H)"
if ($confirmClear -eq 'E' -or $confirmClear -eq 'e') {
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b
    Write-Log "OK: Movies tablosu temizlendi.`n" "SUCCESS"
} else {
    Write-Log "Iptal edildi. Mevcut veriler korunacak." "WARNING"
    exit 0
}

# Feature filmleri filtrele
$featureMovies = $jsonData.Content | Where-Object { $_.ContentKind -eq 'feature' }

Write-Log "Feature filmler aktariliyor..." "INFO"

$batchSize = 50
$batch = @()
$insertCount = 0

foreach ($movie in $featureMovies) {
    try {
        $filmAdi = ($movie.ContentTitle -replace "'", "''")
        $sure = if ($movie.DurationMinutes) { $movie.DurationMinutes } else { 0 }
        $boyut = if ($movie.SizeGB) { $movie.SizeGB } else { 0 }
        
        if ($filmAdi) {
            $values = "(N'$filmAdi', $sure, $boyut, N'Cevahir', N'LMS', N'feature')"
            $batch += $values
        }
        
        if ($batch.Count -ge $batchSize) {
            $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
            sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) { 
                $insertCount += $batch.Count 
                Write-Host "`r$insertCount / $($featureMovies.Count) film eklendi..." -NoNewline -ForegroundColor Green
            }
            $batch = @()
        }
    } catch {
        Write-Log "UYARI: Film eklenemedi: $($movie.ContentTitle) - $_" "WARNING"
    }
}

# Son batch
if ($batch.Count -gt 0) {
    $insertSql = "USE [$MssqlDatabase]; INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru) VALUES $($batch -join ',');"
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
}

Write-Host "`r"
Write-Log "=== CEVAHIR LMS'e AKTARIM TAMAMLANDI ===" "SUCCESS"
Write-Log "  Basarili: $insertCount film (Cevahir LMS)`n" "SUCCESS"

# Diğer lokasyonlara kopyala
Write-Log "Diger lokasyonlara kopyalaniyor..." "INFO"
$copySql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, SalonAdi, IcerikTuru, EklenmeTarihi)
SELECT 
    m.FilmAdi,
    m.Sure_Dakika,
    m.Boyut_GB,
    l.Name AS Lokasyon,
    m.SalonAdi,
    m.IcerikTuru,
    GETDATE() AS EklenmeTarihi
FROM 
    Movies m
    CROSS JOIN (SELECT DISTINCT Name FROM Locations WHERE Name != 'Cevahir') l
WHERE 
    m.Lokasyon = 'Cevahir';
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $copySql -b 2>&1 | Out-Null
Write-Log "OK: Tum lokasyonlara kopyalandi.`n" "SUCCESS"

# Özet
$summarySql = @"
USE [$MssqlDatabase];
SELECT 
    COUNT(*) AS ToplamFilm, 
    COUNT(DISTINCT FilmAdi) AS BenzersizFilm,
    COUNT(DISTINCT Lokasyon) AS LokasyonSayisi
FROM Movies;
"@

Write-Log "=== OZET ===" "INFO"
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

Write-Log "`n=== TAMAMLANDI ===" "SUCCESS"
Write-Log "Gercek LMS iceriklerini iceren veri aktarildi!" "INFO"
Write-Log "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" "INFO"

