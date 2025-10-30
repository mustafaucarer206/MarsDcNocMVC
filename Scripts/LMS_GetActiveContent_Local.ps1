# LMS Local Content Scanner
# Bu script her LMS sunucusunda LOKAL olarak calistirilmalidir
# Kendi content dizinini tarar

param(
    [string]$OutputJson = "active_content_$env:COMPUTERNAME.json"
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
    
    # CPL XML dosyalarini bul
    Write-Log "CPL dosyalari aranıyor..." "INFO"
    $cplFiles = Get-ChildItem -Path $ContentPath -Recurse -Filter "*CPL*.xml" -ErrorAction SilentlyContinue
    
    Write-Log "Bulunan CPL dosyasi sayisi: $($cplFiles.Count)" "SUCCESS"
    
    $processed = 0
    foreach ($cplFile in $cplFiles) {
        try {
            $processed++
            if ($processed % 10 -eq 0) {
                Write-Host "`rIslenen: $processed / $($cplFiles.Count)" -NoNewline
            }
            
            [xml]$cplXml = Get-Content $cplFile.FullName -ErrorAction Stop
            
            # Film adini cikar (namespace olmadan)
            $contentTitle = $cplXml.SelectSingleNode("//*[local-name()='ContentTitleText']")
            $contentKind = $cplXml.SelectSingleNode("//*[local-name()='ContentKind']")
            $duration = $cplXml.SelectSingleNode("//*[local-name()='Duration']")
            $editRate = $cplXml.SelectSingleNode("//*[local-name()='EditRate']")
            
            # Sure hesapla
            $durationMinutes = 0
            if ($duration -and $editRate) {
                $durationValue = [int]$duration.InnerText
                $editRateValue = [int]($editRate.InnerText -split ' ')[0]
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
            # Sessizce devam et - bozuk CPL dosyalarini atla
        }
    }
    
    Write-Host "`r"
    return $contents
}

# Ana islem
Write-Log "`n=== LMS LOKAL ICERIK TARAMASI ===" "INFO"
Write-Log "Bilgisayar: $env:COMPUTERNAME" "INFO"
Write-Log "Tarih: $(Get-Date -Format 'dd.MM.yyyy HH:mm:ss')`n" "INFO"

# Olasilikla content dizinlerini tara
$possiblePaths = @(
    "C:\Doremi\DCP2000\Content",
    "C:\Doremi\ShowVault\Content",
    "C:\Program Files\Dolby\Content",
    "D:\Content",
    "E:\Content",
    "C:\Content",
    "C:\DCP\Content",
    "C:\Cinema\Content"
)

$foundPath = $null
foreach ($path in $possiblePaths) {
    if (Test-Path $path) {
        $foundPath = $path
        Write-Log "Content dizini bulundu: $path" "SUCCESS"
        break
    }
}

if (-not $foundPath) {
    Write-Log "HATA: Content dizini bulunamadi!" "ERROR"
    Write-Log "Denenen yollar:" "INFO"
    foreach ($path in $possiblePaths) {
        Write-Log "  - $path" "WARNING"
    }
    Write-Log "`nCOZUM: Script'i manuel olarak content path ile calistirin:" "WARNING"
    Write-Log '  powershell -File LMS_GetActiveContent_Local.ps1 -ContentPath "C:\YourPath"' "INFO"
    exit 1
}

# Icerikleri tara
$allContents = Get-ContentFromPath -ContentPath $foundPath

# Sonuclari filtrele
$featureContents = $allContents | Where-Object { $_.ContentKind -eq 'feature' }
$trailerContents = $allContents | Where-Object { $_.ContentKind -eq 'trailer' }
$adContents = $allContents | Where-Object { $_.ContentKind -eq 'advertisement' }

Write-Log "`n=== SONUCLAR ===" "SUCCESS"
Write-Log "Toplam icerik: $($allContents.Count)" "INFO"
Write-Log "Feature filmler: $($featureContents.Count)" "INFO"
Write-Log "Trailerlar: $($trailerContents.Count)" "INFO"
Write-Log "Reklamlar: $($adContents.Count)" "INFO"

# JSON olarak kaydet
$output = @{
    ComputerName = $env:COMPUTERNAME
    Server = "LMS"
    ScanDate = Get-Date -Format "o"
    ScanPath = $foundPath
    TotalContent = $allContents.Count
    FeatureCount = $featureContents.Count
    TrailerCount = $trailerContents.Count
    AdvertisementCount = $adContents.Count
    Content = $allContents
}

$output | ConvertTo-Json -Depth 10 | Out-File $OutputJson -Encoding UTF8

Write-Log "`nJSON dosyasi olusturuldu: $OutputJson" "SUCCESS"

# Ozet tablo goster
Write-Log "`nILK 10 FEATURE FILM:" "INFO"
$featureContents | Select-Object -First 10 ContentTitle, DurationMinutes, SizeGB, LastModified | 
    Format-Table -AutoSize

Write-Log "`n=== TAMAMLANDI ===" "SUCCESS"
Write-Log "Dosya boyutu: $([math]::Round((Get-Item $OutputJson).Length / 1KB, 2)) KB" "INFO"
Write-Log "`nBu dosyayi NOC sunucusuna kopyalayin!" "WARNING"

