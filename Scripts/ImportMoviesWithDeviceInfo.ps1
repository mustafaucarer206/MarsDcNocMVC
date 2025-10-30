# PostgreSQL'den film verilerini cihaz ve salon bilgileriyle beraber cek
param(
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$PgUser = "postgres",
    [string]$PgPassword = "postgres",
    [string]$PgDatabase = "moviesbackup",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC",
    [string]$PgBinPath = "C:\Users\mustafa.ucarer\Downloads\postgresql-18.0-1-windows-x64-binaries\pgsql\bin",
    [int]$MaxFilms = 200
)

$env:PGPASSWORD = $PgPassword
$psql = Join-Path $PgBinPath "psql.exe"

Write-Host "`n=== FILMLER CIHAZ VE SALON BILGILERIYLE AKTARILIYOR ===" -ForegroundColor Magenta
Write-Host "Lokasyon: Cevahir`n" -ForegroundColor Cyan

# Once mevcut tabloyu temizle
Write-Host "Mevcut Movies tablosu temizleniyor..." -ForegroundColor Gray
sqlcmd -S $MssqlServer -d $MssqlDatabase -Q "TRUNCATE TABLE Movies;" -b 2>&1 | Out-Null

# PostgreSQL'den film, cihaz ve salon bilgilerini al
$query = @"
SELECT 
    c.content_title,
    ROUND((c.duration_in_seconds / 60.0)::numeric, 2) as sure_dakika,
    ROUND((c.duration_in_seconds * 0.5 / 1024.0 / 1024.0 / 1024.0)::numeric, 2) as boyut_gb,
    COALESCE(c.content_kind, 'feature') as icerik_turu,
    d.name as cihaz_adi,
    s.title as salon_adi
FROM 
    cpl c
    LEFT JOIN cpl_validation cv ON c.uuid = cv.cpl_uuid AND cv.validated = true
    LEFT JOIN device d ON cv.device_uuid = d.uuid
    LEFT JOIN screen s ON d.screen_uuid = s.uuid
WHERE 
    c.content_title IS NOT NULL 
    AND c.content_title != ''
    AND c.content_kind = 'feature'
ORDER BY 
    c.content_title
LIMIT $MaxFilms;
"@

Write-Host "PostgreSQL'den veri cekiliyor..." -ForegroundColor Gray
$filmData = & "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -t -A -F '|' -c $query 2>&1

$insertCount = 0
$batchSize = 20
$batch = @()

foreach ($row in $filmData) {
    if ($row -is [string] -and $row -match '\|') {
        try {
            $fields = $row -split '\|'
            
            $filmAdi = ($fields[0] -replace "'", "''").Trim()
            $sure = if($fields[1] -and $fields[1] -ne ''){[decimal]$fields[1]}else{0}
            $boyut = if($fields[2] -and $fields[2] -ne ''){[decimal]$fields[2]}else{0}
            $tur = if($fields[3]){($fields[3] -replace "'", "''")}else{'feature'}
            $cihaz = if($fields[4] -and $fields[4] -ne ''){($fields[4] -replace "'", "''")}else{'Belirtilmemiş'}
            $salon = if($fields[5] -and $fields[5] -ne ''){($fields[5] -replace "'", "''")}else{'Belirtilmemiş'}
            
            if ($filmAdi) {
                $values = "(N'$filmAdi', $sure, $boyut, N'Cevahir', N'$cihaz', N'$salon', N'$tur')"
                $batch += $values
            }
            
            if ($batch.Count -ge $batchSize) {
                $insertSql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, CihazAdi, SalonAdi, IcerikTuru)
VALUES $($batch -join ',');
"@
                sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
                if ($LASTEXITCODE -eq 0) { 
                    $insertCount += $batch.Count 
                } else {
                    Write-Host "Hata olustu, devam ediliyor..." -ForegroundColor Yellow
                }
                $batch = @()
                Write-Host "`r$insertCount film eklendi..." -NoNewline -ForegroundColor Green
            }
        } catch {
            Write-Host "Satir hatasi: $_" -ForegroundColor Yellow
        }
    }
}

# Son batch'i ekle
if ($batch.Count -gt 0) {
    $insertSql = @"
USE [$MssqlDatabase];
INSERT INTO Movies (FilmAdi, Sure_Dakika, Boyut_GB, Lokasyon, CihazAdi, SalonAdi, IcerikTuru)
VALUES $($batch -join ',');
"@
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $insertSql -b 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) { $insertCount += $batch.Count }
}

Write-Host "`r`n"
Write-Host "=== AKTARIM TAMAMLANDI ===" -ForegroundColor Green
Write-Host "  Toplam: $insertCount film eklendi`n" -ForegroundColor Green

# Ozet istatistikler
$summarySql = @"
USE [$MssqlDatabase];

PRINT '=== MOVIES TABLOSU OZET ===';
PRINT '';

SELECT 
    COUNT(*) AS ToplamFilm,
    COUNT(DISTINCT CihazAdi) AS FarkliCihaz,
    COUNT(DISTINCT SalonAdi) AS FarkliSalon,
    SUM(CASE WHEN CihazAdi = 'Belirtilmemiş' THEN 1 ELSE 0 END) AS BosCihaz,
    SUM(CASE WHEN SalonAdi = 'Belirtilmemiş' THEN 1 ELSE 0 END) AS BosSalon,
    AVG(Sure_Dakika) AS OrtSure,
    SUM(Boyut_GB) AS TopBoyut
FROM Movies;

PRINT '';
PRINT 'Cihazlara Gore Dagilim:';
SELECT TOP 10 
    CihazAdi, 
    COUNT(*) AS FilmSayisi 
FROM Movies 
GROUP BY CihazAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'Salonlara Gore Dagilim:';
SELECT TOP 10 
    SalonAdi, 
    COUNT(*) AS FilmSayisi 
FROM Movies 
GROUP BY SalonAdi 
ORDER BY FilmSayisi DESC;

PRINT '';
PRINT 'Ilk 10 Film:';
SELECT TOP 10 
    FilmAdi, 
    Sure_Dakika, 
    CAST(Boyut_GB AS DECIMAL(10,2)) AS Boyut,
    CihazAdi,
    SalonAdi,
    IcerikTuru
FROM Movies 
ORDER BY FilmAdi;
"@

sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $summarySql -W

$env:PGPASSWORD = $null

Write-Host "`n=== TAMAMLANDI ===" -ForegroundColor Green
Write-Host "http://localhost:5032/Movies adresinden kontrol edebilirsiniz!" -ForegroundColor Cyan
