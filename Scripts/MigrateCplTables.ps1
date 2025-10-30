# CPL ve ilgili tabloları MSSQL'e aktar
param(
    [string]$PgHost = "localhost",
    [int]$PgPort = 5432,
    [string]$PgUser = "postgres",
    [string]$PgPassword = "postgres",
    [string]$PgDatabase = "moviesbackup",
    [string]$MssqlServer = "(local)",
    [string]$MssqlDatabase = "MarsDcNocMVC",
    [string]$PgBinPath = "C:\Users\mustafa.ucarer\Downloads\postgresql-18.0-1-windows-x64-binaries\pgsql\bin"
)

$env:PGPASSWORD = $PgPassword
$psql = Join-Path $PgBinPath "psql.exe"

Write-Host "`n=== CPL Tablolarini MSSQL'e Aktar ===" -ForegroundColor Magenta

# CPL tablosunu CSV'ye aktar
Write-Host "`n1. CPL tablosu aktariliyor..." -ForegroundColor Cyan
$csvCpl = "$env:TEMP\cpl_export.csv"
& "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -c "COPY (SELECT * FROM cpl ORDER BY uuid) TO STDOUT WITH CSV HEADER;" > $csvCpl

if (Test-Path $csvCpl) {
    Write-Host "   CSV olusturuldu: $(([Math]::Round((Get-Item $csvCpl).Length / 1MB, 2))) MB" -ForegroundColor Green
    
    # BULK INSERT ile MSSQL'e aktar
    $bulkInsertSql = @"
USE [$MssqlDatabase];

-- Varsa onceki verileri temizle
TRUNCATE TABLE cpl;

-- BULK INSERT
BULK INSERT cpl
FROM '$csvCpl'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

SELECT COUNT(*) AS cpl_kayit_sayisi FROM cpl;
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $bulkInsertSql -W
}

# CPL_VALIDATION tablosunu aktar
Write-Host "`n2. CPL_VALIDATION tablosu aktariliyor..." -ForegroundColor Cyan
$csvValidation = "$env:TEMP\cpl_validation_export.csv"
& "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -c "COPY (SELECT * FROM cpl_validation ORDER BY uuid) TO STDOUT WITH CSV HEADER;" > $csvValidation

if (Test-Path $csvValidation) {
    Write-Host "   CSV olusturuldu: $(([Math]::Round((Get-Item $csvValidation).Length / 1MB, 2))) MB" -ForegroundColor Green
    
    $bulkInsertSql2 = @"
USE [$MssqlDatabase];

TRUNCATE TABLE cpl_validation;

BULK INSERT cpl_validation
FROM '$csvValidation'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

SELECT COUNT(*) AS validation_kayit_sayisi FROM cpl_validation;
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $bulkInsertSql2 -W
}

# DEVICE tablosunu aktar
Write-Host "`n3. DEVICE tablosu aktariliyor..." -ForegroundColor Cyan
$csvDevice = "$env:TEMP\device_export.csv"
& "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -c "COPY (SELECT * FROM device ORDER BY uuid) TO STDOUT WITH CSV HEADER;" > $csvDevice

if (Test-Path $csvDevice) {
    Write-Host "   CSV olusturuldu" -ForegroundColor Green
    
    $bulkInsertSql3 = @"
USE [$MssqlDatabase];

TRUNCATE TABLE device;

BULK INSERT device
FROM '$csvDevice'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

SELECT COUNT(*) AS device_kayit_sayisi FROM device;
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $bulkInsertSql3 -W
}

# SCREEN tablosunu aktar
Write-Host "`n4. SCREEN tablosu aktariliyor..." -ForegroundColor Cyan
$csvScreen = "$env:TEMP\screen_export.csv"
& "$psql" -h $PgHost -p $PgPort -U $PgUser -d $PgDatabase -c "COPY (SELECT * FROM screen ORDER BY uuid) TO STDOUT WITH CSV HEADER;" > $csvScreen

if (Test-Path $csvScreen) {
    Write-Host "   CSV olusturuldu" -ForegroundColor Green
    
    $bulkInsertSql4 = @"
USE [$MssqlDatabase];

TRUNCATE TABLE screen;

BULK INSERT screen
FROM '$csvScreen'
WITH (
    FIRSTROW = 2,
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '\n',
    TABLOCK
);

SELECT COUNT(*) AS screen_kayit_sayisi FROM screen;
"@
    
    sqlcmd -S $MssqlServer -d $MssqlDatabase -Q $bulkInsertSql4 -W
}

# Temizlik
Remove-Item $csvCpl, $csvValidation, $csvDevice, $csvScreen -ErrorAction SilentlyContinue

Write-Host "`n=== Aktarim Tamamlandi ===" -ForegroundColor Green

$env:PGPASSWORD = $null
