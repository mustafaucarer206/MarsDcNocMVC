# LMS Active Content Checker (Windows)
# Bu script LMS sunucusunda (veya LMS'ye erişimi olan bir Windows bilgisayarda) çalıştırılmalı
# Gerçek fiziksel olarak bulunan içerikleri listeler

param(
    [string]$LmsServerPath = "\\192.172.197.71\content",  # LMS content share yolu
    [string]$LocalLmsPath = "C:\Doremi\DCP2000\Content",  # Veya lokal LMS content yolu
    [string]$OutputJson = "active_content.json",
    [switch]$UseSsh = $false,
    [string]$SshUser = "admin",
    [string]$SshHost = "192.172.197.71"
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

function Get-ContentFromPath {
    param([string]$ContentPath)
    
    $contents = @()
    
    Write-Log "Content dizini taraniyor: $ContentPath" "INFO"
    
    if (-not (Test-Path $ContentPath)) {
        Write-Log "UYARI: Content dizini bulunamadi: $ContentPath" "WARNING"
        return $contents
    }
    
    # CPL XML dosyalarını bul
    $cplFiles = Get-ChildItem -Path $ContentPath -Recurse -Filter "*CPL*.xml" -ErrorAction SilentlyContinue
    
    Write-Log "Bulunan CPL dosyasi sayisi: $($cplFiles.Count)" "INFO"
    
    $processed = 0
    foreach ($cplFile in $cplFiles) {
        try {
            $processed++
            if ($processed % 10 -eq 0) {
                Write-Host "`rIslenen: $processed / $($cplFiles.Count)" -NoNewline
            }
            
            [xml]$cplXml = Get-Content $cplFile.FullName -ErrorAction Stop
            
            # CompositionPlaylist namespace'i bul
            $ns = @{cpl = "http://www.smpte-ra.org/schemas/2067-3/2016"}
            
            # Film adını çıkar
            $contentTitle = $cplXml.SelectSingleNode("//cpl:ContentTitleText", $ns)
            if (-not $contentTitle) {
                $contentTitle = $cplXml.SelectSingleNode("//*[local-name()='ContentTitleText']")
            }
            
            # İçerik türünü çıkar
            $contentKind = $cplXml.SelectSingleNode("//cpl:ContentKind", $ns)
            if (-not $contentKind) {
                $contentKind = $cplXml.SelectSingleNode("//*[local-name()='ContentKind']")
            }
            
            # Süreyi hesapla
            $duration = $cplXml.SelectSingleNode("//cpl:Duration", $ns)
            if (-not $duration) {
                $duration = $cplXml.SelectSingleNode("//*[local-name()='Duration']")
            }
            
            $editRate = $cplXml.SelectSingleNode("//cpl:EditRate", $ns)
            if (-not $editRate) {
                $editRate = $cplXml.SelectSingleNode("//*[local-name()='EditRate']")
            }
            
            $durationMinutes = 0
            if ($duration -and $editRate) {
                $durationValue = [int]$duration.InnerText
                $editRateValue = [int]$editRate.InnerText.Split()[0]
                if ($editRateValue -gt 0) {
                    $durationMinutes = [math]::Round($durationValue / $editRateValue / 60, 2)
                }
            }
            
            # Dizin boyutunu hesapla
            $contentDir = $cplFile.Directory.FullName
            $dirSize = (Get-ChildItem -Path $contentDir -Recurse -ErrorAction SilentlyContinue | 
                        Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            $dirSizeGB = [math]::Round($dirSize / 1GB, 2)
            
            $contentObj = [PSCustomObject]@{
                ContentTitle = $contentTitle.InnerText
                ContentKind = $contentKind.InnerText
                DurationMinutes = $durationMinutes
                SizeGB = $dirSizeGB
                CplFile = $cplFile.FullName
                LastModified = $cplFile.LastWriteTime
                ContentPath = $contentDir
            }
            
            $contents += $contentObj
            
        } catch {
            Write-Log "UYARI: CPL parse hatasi: $($cplFile.Name) - $_" "WARNING"
        }
    }
    
    Write-Host "`r"
    return $contents
}

# Ana işlem
Write-Log "`n=== LMS AKTIF ICERIK TARAMASI (WINDOWS) ===" "INFO"
Write-Log "Tarih: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n" "INFO"

$allContents = @()

# Önce network path'i dene
if (Test-Path $LmsServerPath) {
    Write-Log "Network path kullaniliyor: $LmsServerPath" "SUCCESS"
    $allContents = Get-ContentFromPath -ContentPath $LmsServerPath
}
# Sonra local path'i dene
elseif (Test-Path $LocalLmsPath) {
    Write-Log "Local path kullaniliyor: $LocalLmsPath" "SUCCESS"
    $allContents = Get-ContentFromPath -ContentPath $LocalLmsPath
}
else {
    Write-Log "HATA: LMS content dizini bulunamadi!" "ERROR"
    Write-Log "Denenen yollar:" "INFO"
    Write-Log "  1. $LmsServerPath" "INFO"
    Write-Log "  2. $LocalLmsPath" "INFO"
    Write-Log "`nCozum onerileri:" "WARNING"
    Write-Log "  - Network share'i map edin: net use Z: $LmsServerPath /user:admin password" "INFO"
    Write-Log "  - Veya parametreyle dogru path'i belirtin: -LmsServerPath 'C:\YourPath'" "INFO"
    exit 1
}

# Sonuçları filtrele (sadece feature)
$featureContents = $allContents | Where-Object { $_.ContentKind -eq 'feature' }

Write-Log "`n=== SONUCLAR ===" "SUCCESS"
Write-Log "Toplam icerik: $($allContents.Count)" "INFO"
Write-Log "Feature filmler: $($featureContents.Count)" "INFO"
Write-Log "Trailerlar: $(($allContents | Where-Object { $_.ContentKind -eq 'trailer' }).Count)" "INFO"
Write-Log "Reklamlar: $(($allContents | Where-Object { $_.ContentKind -eq 'advertisement' }).Count)" "INFO"

# JSON olarak kaydet
$output = @{
    Server = "LMS"
    ScanDate = Get-Date -Format "o"
    ScanPath = if (Test-Path $LmsServerPath) { $LmsServerPath } else { $LocalLmsPath }
    TotalContent = $allContents.Count
    FeatureCount = $featureContents.Count
    Content = $allContents
}

$output | ConvertTo-Json -Depth 10 | Out-File $OutputJson -Encoding UTF8

Write-Log "`nJSON dosyasi olusturuldu: $OutputJson" "SUCCESS"

# Özet tablo göster
Write-Log "`nILK 10 FEATURE FILM:" "INFO"
$featureContents | Select-Object -First 10 ContentTitle, DurationMinutes, SizeGB, LastModified | 
    Format-Table -AutoSize

Write-Log "`n=== TAMAMLANDI ===" "SUCCESS"
Write-Log "Simdi bu veriyi MSSQL'e aktarabilirsiniz:" "INFO"
Write-Log "  .\Scripts\ImportFromLMSJson.ps1 -JsonFile '$OutputJson'" "INFO"

