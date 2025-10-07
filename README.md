# Mars DC NoC Backup System

Bu proje, Mars DC NoC ortamında FTP backup işlemleri ve DCP Online klasör takibi için modüler bir PowerShell sistemidir.

## Dosya Yapısı

```
├── CommonFunctions.psm1           # Ortak fonksiyonlar modülü
├── BackupScript.ps1              # FTP backup işlemleri
├── DcpOnlineFolderTracker.ps1    # DCP Online klasör takibi
├── RunBackupTasks.ps1            # Ana koordinatör script
└── README.md                     # Bu dosya
```

## Dosya Açıklamaları

### CommonFunctions.psm1
Tüm scriptler tarafından kullanılan ortak fonksiyonları içeren PowerShell modülü:
- Database operations (güvenli bağlantı, log yazma)
- Debug logging
- Klasör boyutu hesaplama
- Güvenli path oluşturma
- Hata yönetimi

### BackupScript.ps1
FTP sunucusundan dosya indirme işlemlerini gerçekleştirir:
- FTP bağlantısı ve dosya indirme
- İndirme ilerleme takibi
- Disk alanı kontrolü
- Veritabanı kayıt işlemleri

### DcpOnlineFolderTracker.ps1
DCP Online klasörlerini izler ve WatchFolder'a kopyalar:
- Klasör boyutu değişiklik takibi
- Duplicate kayıt temizliği
- Eski klasör temizliği (72 saat)
- WatchFolder'a otomatik kopyalama

### RunBackupTasks.ps1
Ana koordinatör script - diğer scriptleri yönetir:
- İşlemleri paralel veya sıralı çalıştırma
- Job monitoring ve hata yönetimi
- Esnek parametre yönetimi

## Kullanım

### 1. Temel Kullanım (Her iki işlemi paralel çalıştır)
```powershell
.\RunBackupTasks.ps1 -DebugMode
```

### 2. Sadece FTP Backup
```powershell
.\RunBackupTasks.ps1 -OnlyBackup -DebugMode
```

### 3. Sadece DCP Online Tracker
```powershell
.\RunBackupTasks.ps1 -OnlyTracker -DebugMode
```

### 4. Sıralı Çalıştırma
```powershell
.\RunBackupTasks.ps1 -RunSequential -DebugMode
```

### 5. Özel Dizinlerle Çalıştırma
```powershell
.\RunBackupTasks.ps1 -localBackupPath "E:\Backup\" -watchFolderPath "E:\Watch\" -DebugMode
```

### 6. Scriptleri Ayrı Ayrı Çalıştırma

#### FTP Backup:
```powershell
.\BackupScript.ps1 -localBackupPath "D:\DCP Online\" -destinationPath "D:\WatchFolder\" -DebugMode
```

#### DCP Online Tracker:
```powershell
.\DcpOnlineFolderTracker.ps1 -dcpOnlinePath "D:\DCP Online\" -watchFolderPath "D:\WatchFolder\" -DebugMode
```

## Parametreler

### RunBackupTasks.ps1 Parametreleri
| Parametre | Tip | Varsayılan | Açıklama |
|-----------|-----|------------|----------|
| `localBackupPath` | string | "D:\DCP Online\" | FTP'den indirilen dosyaların geçici dizini |
| `destinationPath` | string | "D:\WatchFolder\" | Final hedef dizin |
| `dcpOnlinePath` | string | "D:\DCP Online\" | DCP Online klasör yolu |
| `watchFolderPath` | string | "D:\WatchFolder\" | Watch folder yolu |
| `DebugMode` | switch | false | Debug modunu etkinleştirir |
| `OnlyBackup` | switch | false | Sadece FTP backup çalıştırır |
| `OnlyTracker` | switch | false | Sadece DCP tracker çalıştırır |
| `RunSequential` | switch | false | İşlemleri sıralı çalıştırır |

## Sistem Gereksinimleri

1. **PowerShell 5.1+**
2. **WinSCP** - C:\Program Files (x86)\WinSCP\WinSCPnet.dll
3. **SQL Server** - LocalDB veya Express
4. **İzinler**:
   - FTP sunucusuna erişim
   - Veritabanına yazma yetkisi
   - Dosya sistemi read/write yetkisi

## Veritabanı Tabloları

### BackupLogs
```sql
CREATE TABLE BackupLogs (
    ID int IDENTITY(1,1) PRIMARY KEY,
    FolderName nvarchar(255),
    Action nvarchar(100),
    Timestamp datetime,
    Status int,
    LocationName nvarchar(100),
    Duration nvarchar(50),
    FileSize nvarchar(50),
    AverageSpeed nvarchar(50),
    TotalFileSize nvarchar(50)
)
```

### DcpOnlineFolderTracking
```sql
CREATE TABLE DcpOnlineFolderTracking (
    ID int IDENTITY(1,1) PRIMARY KEY,
    FolderName nvarchar(255),
    FirstSeenDate datetime,
    LastCheckDate datetime,
    FileSize float,
    Status nvarchar(50),
    IsProcessed bit,
    LocationName nvarchar(100)
)
```

## Güvenlik

1. **FTP Şifresi**: Environment variable `MARS_FTP_PASSWORD` kullanın
   ```powershell
   $env:MARS_FTP_PASSWORD = "your_secure_password"
   ```

2. **Veritabanı**: Integrated Security kullanılıyor

3. **Path Security**: Path traversal saldırılarına karşı korunmalıdır

## Monitoring ve Logging

- Tüm işlemler veritabanına kaydedilir
- Debug modu detaylı console çıktısı sağlar
- Log rotasyonu otomatik (30 gün)
- Mutex ile concurrent execution korunması

## Troubleshooting

### Yaygın Problemler

1. **WinSCP DLL Bulunamıyor**
   ```
   Çözüm: WinSCP'yi yükleyin veya DLL yolunu güncelleyin
   ```

2. **Veritabanı Bağlantı Hatası**
   ```
   Çözüm: Connection string'i kontrol edin
   ```

3. **İzin Hatası**
   ```
   Çözüm: PowerShell'i Administrator olarak çalıştırın
   ```

## Bakım

1. **Log Temizliği**: Otomatik 30 günlük rotasyon
2. **Eski Klasörler**: 72 saatlik otomatik temizlik
3. **Duplicate Temizliği**: Her çalıştırmada otomatik

## İletişim

Bu sistem hakkında sorularınız için lütfen sistem yöneticisine başvurun.

---

**Önemli**: Production ortamında çalıştırmadan önce test ortamında deneyiniz.

# MARS DC NOC - Modular Backup System

## Genel Bakış

Bu proje, Mars DC NOC'un FTP backup işlemlerini ve DCP Online klasör takibini modüler bir yapıda gerçekleştiren PowerShell script sistemidir. Monolitik backup script'i daha küçük, bağımsız ve sürdürülebilir modüllere ayrılmıştır.

## Dosya Yapısı

### 🔧 Ana Scriptler
- **`BackupScript.ps1`** - FTP'den dosya indirme ve backup işlemleri
- **`DcpOnlineFolderTracker.ps1`** - DCP Online klasörlerini takip eden script
- **`RunBackupTasks.ps1`** - İki scripti koordine eden ana script

### 📚 Destek Dosyaları
- **`CommonFunctions.psm1`** - Ortak fonksiyonlar modülü
- **`TestGracefulShutdown.ps1`** - Sağlıklı kapatma test scripti
- **`README.md`** - Bu dokümantasyon dosyası

### 🗃️ Database Scriptleri (Opsiyonel)
- **`DatabaseOptimizations.sql`** - Performans optimizasyonları

## 🚀 Sağlıklı Kapatma Özellikleri

Tüm scriptler artık sağlıklı kapatma (graceful shutdown) özelliklerine sahiptir:

### ✅ Otomatik Kaynak Temizleme
- **WinSCP Oturumları**: FTP bağlantıları güvenli şekilde kapatılır
- **Database Bağlantıları**: Açık SQL bağlantıları otomatik temizlenir
- **Mutex/Lock'lar**: Process mutex'leri serbest bırakılır
- **PowerShell Job'lar**: Arka plan job'ları temizlenir

### 📊 Kapsamlı İstatistikler
- **Çalışma Süresi**: Toplam script çalışma süresi
- **İşlem Sayıları**: İşlenen, başarılı ve başarısız klasör sayıları
- **Final Özet**: Database'e otomatik özet kaydı

### 🎯 Exit Code Yönetimi
- **0**: Başarılı tamamlanma
- **1**: Hata ile tamamlanma
- **2**: Başka bir instance çalışıyor
- **130**: Kullanıcı tarafından durduruldu (Ctrl+C)

### 📝 Detaylı Loglama
- Shutdown nedeni ve süresi
- Kaynak temizleme durumu
- Final durum mesajları
- Database'e özet log kaydı

### 🛡️ Interrupt Handling
- Ctrl+C sinyali yakalanır
- Graceful shutdown işlemi başlatılır
- Child process'ler güvenli şekilde durdurulur

## Kullanım

### Temel Kullanım

```powershell
# Sadece backup işlemi
.\RunBackupTasks.ps1 -OnlyBackup

# Sadece tracker işlemi
.\RunBackupTasks.ps1 -OnlyTracker

# Her ikisini birlikte (paralel)
.\RunBackupTasks.ps1

# Her ikisini sırayla
.\RunBackupTasks.ps1 -RunSequential

# Debug modu ile
.\RunBackupTasks.ps1 -DebugMode
```

### Scriptleri Ayrı Çalıştırma

```powershell
# Backup script'i direkt çalıştır
.\BackupScript.ps1 -DebugMode

# Tracker script'i direkt çalıştır
.\DcpOnlineFolderTracker.ps1 -DebugMode -stableWaitMinutes 10
```

### Sağlıklı Kapatma Testi

```powershell
# Tüm scriptleri test et
.\TestGracefulShutdown.ps1 -TestAll

# Sadece backup script'i test et
.\TestGracefulShutdown.ps1 -TestBackup

# Interrupt testleri dahil
.\TestGracefulShutdown.ps1 -TestAll -TestInterruption

# Sadece tracker test et
.\TestGracefulShutdown.ps1 -TestTracker
```

## Parametreler

### BackupScript.ps1
- `localBackupPath`: Geçici indirme dizini (default: "D:\DCP Online\")
- `destinationPath`: Hedef dizin (default: "D:\WatchFolder\")
- `DebugMode`: Debug modu (switch)

### DcpOnlineFolderTracker.ps1
- `dcpOnlinePath`: DCP Online dizini (default: "D:\DCP Online\")
- `watchFolderPath`: Watch klasörü (default: "D:\WatchFolder\")
- `stableWaitMinutes`: Stabilite bekleme süresi (default: 5 dakika)
- `oldFolderHours`: Eski klasör temizlik süresi (default: 72 saat)
- `DebugMode`: Debug modu (switch)

### RunBackupTasks.ps1
- `OnlyBackup`: Sadece backup çalıştır (switch)
- `OnlyTracker`: Sadece tracker çalıştır (switch)
- `RunSequential`: Sıralı çalıştırma (switch)
- `DebugMode`: Debug modu (switch)

### TestGracefulShutdown.ps1
- `TestBackup`: Backup script'i test et (switch)
- `TestTracker`: Tracker script'i test et (switch)
- `TestCoordinator`: Coordinator script'i test et (switch)
- `TestAll`: Tüm scriptleri test et (switch)
- `TestInterruption`: Interrupt testleri yap (switch)

## Sistem Gereksinimleri

### Yazılım
- **PowerShell 5.1+**
- **WinSCP** (C:\Program Files (x86)\WinSCP\WinSCPnet.dll)
- **SQL Server Express** (34CEVTMS\SQLEXPRESS)

### Donanım
- **Minimum 50 GB** boş disk alanı (D: sürücüsü)
- **Ağ bağlantısı** FTP sunucusuna erişim için
- **Yeterli RAM** (minimum 4 GB önerilir)

## Database Şeması

### BackupLogs Tablosu
```sql
CREATE TABLE BackupLogs (
    ID int IDENTITY(1,1) PRIMARY KEY,
    FolderName nvarchar(255),
    Action nvarchar(100),
    Status int,
    Timestamp datetime DEFAULT GETDATE(),
    Duration nvarchar(50),
    FileSize nvarchar(100),
    TotalFileSize nvarchar(100),
    AverageSpeed nvarchar(50),
    LocationName nvarchar(100)
);
```

### DcpOnlineFolderTracking Tablosu
```sql
CREATE TABLE DcpOnlineFolderTracking (
    ID int IDENTITY(1,1) PRIMARY KEY,
    FolderName nvarchar(255),
    FirstSeenDate datetime,
    LastCheckDate datetime,
    FileSize float,
    Status nvarchar(50),
    IsProcessed bit DEFAULT 0,
    LocationName nvarchar(100)
);
```

## İzleme ve Loglama

### Log Dosyaları
- **Debug Loglar**: `MarsBackup_Debug_YYYYMMDD.log`
- **Error Loglar**: `MarsBackup_Error_YYYYMMDD.log`
- **Otomatik Temizlik**: 30 günden eski loglar silinir

### Database Logları
- Tüm işlemler database'e kaydedilir
- System summary logları otomatik eklenir
- Error detayları tracking için saklanır

### Shutdown Logları
Her script kapanışında şu bilgiler kaydedilir:
- Toplam çalışma süresi
- İşlenen klasör sayıları
- Başarı/hata oranları
- Kaynak temizleme durumu
- Shutdown nedeni

## Sorun Giderme

### Sık Karşılaşılan Problemler

1. **WinSCP DLL Hatası**
   ```
   WinSCP DLL dosyası bulunamadı
   ```
   **Çözüm**: WinSCP'yi doğru dizine kurun veya DLL yolunu kontrol edin

2. **Database Bağlantı Hatası**
   ```
   Veritabanı bağlantısı kurulamadı
   ```
   **Çözüm**: SQL Server servisini kontrol edin ve connection string'i doğrulayın

3. **Mutex Hatası**
   ```
   Başka bir backup işlemi çalışıyor
   ```
   **Çözüm**: Çalışan instance'ları kontrol edin veya mutex'i manuel temizleyin

4. **Disk Alanı Yetersiz**
   ```
   Yeterli disk alanı yok
   ```
   **Çözüm**: D: sürücüsünde en az 50 GB boş alan sağlayın

### Debug Modu
```powershell
# Detaylı loglama için debug modu kullanın
.\RunBackupTasks.ps1 -DebugMode
```

### Test Modu
```powershell
# Scriptlerin sağlıklı kapatma özelliklerini test edin
.\TestGracefulShutdown.ps1 -TestAll -TestInterruption
```

### Log Kontrol
```powershell
# Son debug loglarını görüntüle
Get-Content "MarsBackup_Debug_$(Get-Date -Format 'yyyyMMdd').log" -Tail 50

# Error loglarını kontrol et
Get-Content "MarsBackup_Error_$(Get-Date -Format 'yyyyMMdd').log" -Tail 20
```

## Silme Zaman Çizelgeleri

### DCP Online Klasörleri
- **72 saat (3 gün)** sonra otomatik silinir
- `oldFolderHours` parametresi ile özelleştirilebilir

### Database Logları
- **30 gün** sonra otomatik temizlenir
- `Clean-OldLogs` fonksiyonu ile yönetilir

### Log Dosyaları
- **30 gün** sonra otomatik silinir
- `logRetentionDays` parametresi ile özelleştirilebilir

## Güvenlik

### FTP Şifre Yönetimi
```powershell
# Environment variable kullanın (önerilen)
$env:MARS_FTP_PASSWORD = "YourSecurePassword"

# Veya script içinde hardcoded (test ortamı için)
```

### Database Güvenliği
- **Integrated Security** kullanılır
- Windows Authentication ile güvenli erişim

## Performans Optimizasyonları

### Database İndeksleri
```sql
-- Performans için önerilen indeksler
CREATE INDEX IX_BackupLogs_FolderName ON BackupLogs(FolderName);
CREATE INDEX IX_BackupLogs_Timestamp ON BackupLogs(Timestamp);
CREATE INDEX IX_DcpTracking_FolderName ON DcpOnlineFolderTracking(FolderName);
```

### Paralel İşleme
- **Varsayılan**: Backup ve Tracker paralel çalışır
- **Sıralı mod**: `-RunSequential` parametresi ile

## Versiyon Geçmişi

### v2.1 (Mevcut)
- ✅ Sağlıklı kapatma özellikleri eklendi
- ✅ Kapsamlı istatistik takibi
- ✅ Exit code yönetimi
- ✅ Interrupt handling (Ctrl+C)
- ✅ Kaynak temizleme otomasyonu
- ✅ Test suite eklendi

### v2.0
- ✅ Modüler yapıya geçiş
- ✅ CommonFunctions modülü
- ✅ Basitleştirilmiş DCP tracker
- ✅ Paralel/sıralı çalıştırma seçenekleri

### v1.0
- ✅ Monolitik backup script (BackupScript.ps1)

## Destek

Herhangi bir sorun veya öneriniz için lütfen sistem yöneticisi ile iletişime geçin.

---
*Mars DC NOC Backup System - Modular PowerShell Solution* 