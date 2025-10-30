# Backup ve DcpOnlineFolders için örnek veri ekleme PowerShell Script'i

param(
    [string]$ConnectionString = "Server=(local);Database=master;Integrated Security=True;",
    [switch]$DryRun = $false
)

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-DatabaseConnection {
    param([string]$ConnectionString)
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        $connection.Close()
        return $true
    }
    catch {
        Write-ColorLog "Database connection failed: $_" -Color "Red"
        return $false
    }
}

function Execute-SqlScript {
    param(
        [string]$ConnectionString,
        [string]$SqlScript,
        [bool]$DryRun = $false
    )
    
    if ($DryRun) {
        Write-ColorLog "DRY RUN MODE - SQL Script would be executed:" -Color "Yellow"
        Write-Host $SqlScript -ForegroundColor "Gray"
        return $true
    }
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $command = $connection.CreateCommand()
        $command.CommandText = $SqlScript
        $command.CommandTimeout = 300  # 5 dakika timeout
        
        $result = $command.ExecuteNonQuery()
        $connection.Close()
        
        return $true
    }
    catch {
        Write-ColorLog "Error executing SQL script: $_" -Color "Red"
        return $false
    }
}

# Ana işlem
Write-ColorLog "Backup ve DCP Online Folders için örnek veri ekleme işlemi başlıyor..." -Color "Green"

# Database bağlantısını test et
Write-ColorLog "Database bağlantısı test ediliyor..." -Color "Yellow"
if (-not (Test-DatabaseConnection -ConnectionString $ConnectionString)) {
    Write-ColorLog "Database bağlantısı başarısız! İşlem durduruluyor." -Color "Red"
    exit 1
}
Write-ColorLog "Database bağlantısı başarılı!" -Color "Green"

# SQL script dosyasını oku
$scriptPath = Join-Path $PSScriptRoot "AddSampleBackupData.sql"
if (-not (Test-Path $scriptPath)) {
    Write-ColorLog "SQL script dosyası bulunamadı: $scriptPath" -Color "Red"
    exit 1
}

$sqlScript = Get-Content $scriptPath -Raw
Write-ColorLog "SQL script dosyası okundu: $scriptPath" -Color "Green"

# SQL script'ini çalıştır
Write-ColorLog "SQL script çalıştırılıyor..." -Color "Yellow"
if (Execute-SqlScript -ConnectionString $ConnectionString -SqlScript $sqlScript -DryRun $DryRun) {
    if ($DryRun) {
        Write-ColorLog "DRY RUN tamamlandı! Gerçek çalıştırma için -DryRun parametresini kaldırın." -Color "Yellow"
    } else {
        Write-ColorLog "Örnek veriler başarıyla eklendi!" -Color "Green"
        Write-ColorLog "Backup sayfası: http://localhost:5032/Backup" -Color "Cyan"
        Write-ColorLog "DCP Online Folders sayfası: http://localhost:5032/Backup/DcpOnlineFolders" -Color "Cyan"
    }
} else {
    Write-ColorLog "SQL script çalıştırılırken hata oluştu!" -Color "Red"
    exit 1
}

Write-ColorLog "İşlem tamamlandı!" -Color "Green"

# Kullanım örnekleri
Write-Host "`n" -NoNewline
Write-ColorLog "Kullanım örnekleri:" -Color "Magenta"
Write-Host "  Normal çalıştırma: .\RunAddSampleBackupData.ps1" -ForegroundColor "Gray"
Write-Host "  Test modu:         .\RunAddSampleBackupData.ps1 -DryRun" -ForegroundColor "Gray"
Write-Host "  Özel connection:   .\RunAddSampleBackupData.ps1 -ConnectionString 'Server=...'" -ForegroundColor "Gray"


