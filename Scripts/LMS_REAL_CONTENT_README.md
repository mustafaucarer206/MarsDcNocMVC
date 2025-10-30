# LMS Gerçek İçerik Tarama ve Aktarma Kılavuzu

## 🎯 Amaç
PostgreSQL veritabanı yerine **gerçek LMS sunucusundaki fiziksel dosyaları** tarayarak sadece **gerçekten var olan** içerikleri göstermek.

## 📋 Gereksinimler

### 1. LMS Sunucu Erişimi
- **Network Share**: `\\192.172.197.71\content` (önerilen)
- **veya Lokal Path**: `C:\Doremi\DCP2000\Content`
- **veya SSH**: `admin@192.172.197.71`

### 2. Gerekli İzinler
- LMS content dizinine okuma erişimi
- MSSQL'e yazma erişimi

## 🚀 Kullanım Adımları

### Adım 1: LMS İçeriklerini Tara

#### Yöntem A: Network Share ile (Önerilen)
```powershell
# Önce network drive map edin
net use Z: \\192.172.197.71\content /user:admin password

# Script'i çalıştırın
cd C:\Users\mustafa.ucarer\Desktop\MarsDcNocMVC
powershell -ExecutionPolicy Bypass -File "Scripts\LMS_GetActiveContent_Windows.ps1" -LmsServerPath "Z:\"
```

#### Yöntem B: Lokal Path ile
```powershell
# Eğer LMS sunucusundaysanız veya content dizini local'de mount'luysa
powershell -ExecutionPolicy Bypass -File "Scripts\LMS_GetActiveContent_Windows.ps1" -LocalLmsPath "C:\Doremi\DCP2000\Content"
```

#### Yöntem C: Özel Path ile
```powershell
# Kendi path'inizi belirtin
powershell -ExecutionPolicy Bypass -File "Scripts\LMS_GetActiveContent_Windows.ps1" -LmsServerPath "\\YOUR_LMS_IP\content"
```

**Çıktı:** `active_content.json` dosyası oluşturulur

### Adım 2: JSON'u MSSQL'e Aktar

```powershell
# JSON dosyasını import edin
powershell -ExecutionPolicy Bypass -File "Scripts\ImportFromLMSJson.ps1" -JsonFile "active_content.json"

# Onay sorusu gelecek: Movies tablosunu temizlemek istiyor musunuz? (E/H)
# E yazın ve Enter'a basın
```

### Adım 3: Kontrol Et

```
http://localhost:5032/Movies
```

## 📊 Beklenen Sonuçlar

### Önceki Durum (PostgreSQL):
- ❌ 758 film (eski/silinmiş içerikler dahil)
- ❌ Fiziksel olarak LMS'de olmayan içerikler

### Yeni Durum (Gerçek LMS Taraması):
- ✅ Sadece gerçekten LMS'de olan filmler
- ✅ Güncel boyut bilgileri (GB)
- ✅ Doğru süre bilgileri
- ✅ Son değiştirilme tarihleri

## 🔧 Sorun Giderme

### Hata 1: "LMS content dizini bulunamadi"
**Çözüm:**
```powershell
# Network bağlantısını test edin
Test-Path \\192.172.197.71\content

# Ping atın
ping 192.172.197.71

# Credentials ile deneyin
net use \\192.172.197.71\content /user:DOMAIN\admin password
```

### Hata 2: "CPL parse hatasi"
**Neden:** Bazı CPL dosyaları bozuk olabilir
**Çözüm:** Normal - script diğer dosyaları okumaya devam eder

### Hata 3: "Access Denied"
**Çözüm:**
```powershell
# Admin hakları ile çalıştırın
# PowerShell'i "Run as Administrator" ile açın
```

## 📁 LMS İçerik Dizin Yapısı

Tipik LMS dizin yapısı:
```
\\LMS_SERVER\content\
├── MovieTitle1_FTR_F_EN-XX_51_2K_20240101_SMPTE_OV\
│   ├── CPL_xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.xml  ← Bu okunur
│   ├── ASSETMAP.xml
│   ├── PKL_*.xml
│   └── [MXF files]
├── MovieTitle2_FTR_F_TR-XX_51_2K_20240102_SMPTE_OV\
│   └── ...
```

## 🎬 Örnek Çıktı

### active_content.json
```json
{
  "Server": "LMS",
  "ScanDate": "2025-10-08T12:30:45+03:00",
  "ScanPath": "Z:\\",
  "TotalContent": 150,
  "FeatureCount": 120,
  "Content": [
    {
      "ContentTitle": "Sinners_FTR_S-276_EN-TR_TR_51_4K_WR_20250325_DLX_SMPTE_VF",
      "ContentKind": "feature",
      "DurationMinutes": 137.39,
      "SizeGB": 187.5,
      "CplFile": "Z:\\Sinners_FTR\\CPL_abc123.xml",
      "LastModified": "2025-10-07T14:29:03+03:00",
      "ContentPath": "Z:\\Sinners_FTR"
    }
  ]
}
```

## ⚙️ Özelleştirme

### Farklı İçerik Türlerini Dahil Etme
`ImportFromLMSJson.ps1` dosyasında:
```powershell
# Sadece feature yerine trailer'ları da ekle
$featureMovies = $jsonData.Content | Where-Object { 
    $_.ContentKind -eq 'feature' -or $_.ContentKind -eq 'trailer' 
}
```

### Farklı Lokasyon İsmi
```powershell
# Cevahir yerine başka lokasyon
$values = "(N'$filmAdi', $sure, $boyut, N'YourLocation', N'LMS', N'feature')"
```

## 🔄 Otomatik Güncelleme

Haftada bir çalıştırmak için Task Scheduler:
```powershell
# Task oluştur
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File 'C:\Path\To\LMS_GetActiveContent_Windows.ps1'"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 3AM

Register-ScheduledTask -TaskName "LMS Content Scan" -Action $action -Trigger $trigger
```

## ✅ Avantajlar

1. **%100 Doğruluk**: Sadece gerçek içerikler
2. **Güncel Boyutlar**: GB bazında gerçek dosya boyutları
3. **Bağımsız**: PostgreSQL'e ihtiyaç yok
4. **Hızlı**: Direkt dosya sistemi taraması
5. **Esnek**: Her zaman güncellenebilir

## 📞 Destek

Sorun yaşarsanız:
1. `active_content.json` dosyasını kontrol edin
2. Log mesajlarını okuyun
3. LMS sunucusuna erişimi test edin

