# Disk Kapasitesi İzleme Sistemi - Sistem Dokümantasyonu

## 📋 İçindekiler
1. [Sistem Genel Bakış](#sistem-genel-bakış)
2. [Sistem Mimarisi](#sistem-mimarisi)
3. [Teknoloji Stack](#teknoloji-stack)
4. [Veritabanı Yapısı](#veritabanı-yapısı)
5. [PowerShell Script Detayları](#powershell-script-detayları)
6. [Kurulum ve Konfigürasyon](#kurulum-ve-konfigürasyon)
7. [Çalıştırma Rehberi](#çalıştırma-rehberi)
8. [İzleme ve Log](#izleme-ve-log)
9. [Hata Yönetimi](#hata-yönetimi)
10. [Bakım ve Güncellemeler](#bakım-ve-güncellemeler)

---

## 🔍 Sistem Genel Bakış

**Disk Kapasitesi İzleme Sistemi**, belirli lokasyonlardaki sunucuların disk kapasitelerini otomatik olarak izleyen ve veritabanında saklayan bir monitoring çözümüdür.

### 🎯 Sistem Amacı
- Sunucu disk kapasitelerinin günlük izlenmesi
- Disk kullanım verilerinin merkezi veritabanında saklanması
- Geçmiş verilerin analiz edilebilmesi
- Proaktif disk doluluk uyarıları için veri sağlama

### 🏢 Hedef Kullanıcılar
- **Sistem Yöneticileri**: Disk kapasitesi izleme
- **NOC (Network Operations Center) Ekibi**: Monitoring ve alerting
- **İT Yöneticileri**: Raporlama ve kapasite planlama

---

## 🏗️ Sistem Mimarisi

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Local Server  │    │   PowerShell    │    │  SQL Server DB  │
│   (Cevahir)     │───▶│     Script      │───▶│  (MarsDcNocMvc) │
│   D: Drive      │    │ CheckDiskCap.ps1│    │ LocationLmsDisk │
└─────────────────┘    └─────────────────┘    └─────────────────┘
        │                        │                        │
        ▼                        ▼                        ▼
   Disk Usage               Processing &               Data Storage
   Monitoring               Error Handling             & Reporting
```

### 🧩 Sistem Bileşenleri

#### 1. **Frontend (Web Interface) - [Gelecek Geliştirme]**
- **Teknoloji**: ASP.NET Core MVC
- **Özellikler**: 
  - Dashboard görünümü
  - Geçmiş disk kullanım grafikleri
  - Alert yönetimi
  - Raporlama

#### 2. **Backend (PowerShell Script)**
- **Dosya**: `CheckDiskCapacity.ps1`
- **Görev**: Disk kapasitesi okuma ve veritabanı işlemleri
- **Çalışma Modu**: Scheduled task veya manuel

#### 3. **Database (SQL Server)**
- **Server**: GMDCMUCARERNB
- **Database**: MarsDcNocMvc
- **Tablo**: LocationLmsDiscCapacity

#### 4. **Scheduling System**
- **Windows Task Scheduler**: Otomatik çalıştırma
- **Sıklık**: Günlük (önerilen)

---

## 💻 Teknoloji Stack

### **Backend Technologies**
- **PowerShell 5.1+**: Ana script dili
- **SQL Server**: Veri depolama
- **Windows Server**: Host platform

### **Database Technology**
- **SQL Server**: Veritabanı yönetim sistemi
- **T-SQL**: Sorgu dili
- **Integrated Security**: Kimlik doğrulama

### **Infrastructure**
- **Windows Task Scheduler**: Job scheduling
- **Windows PowerShell**: Script execution
- **SQL Server Management Studio**: DB yönetimi

---

## 🗄️ Veritabanı Yapısı

### **LocationLmsDiscCapacity Tablosu**

```sql
CREATE TABLE LocationLmsDiscCapacity (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    LocationName NVARCHAR(100) NOT NULL,
    TotalSpace DECIMAL(10,2) NOT NULL,    -- GB cinsinden
    FreeSpace DECIMAL(10,2) NOT NULL,     -- GB cinsinden  
    UsedSpace DECIMAL(10,2) NOT NULL,     -- GB cinsinden
    CheckDate DATETIME NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    UpdatedDate DATETIME DEFAULT GETDATE()
);

-- Index'ler
CREATE INDEX IX_LocationLmsDiscCapacity_LocationName 
ON LocationLmsDiscCapacity(LocationName);

CREATE INDEX IX_LocationLmsDiscCapacity_CheckDate 
ON LocationLmsDiscCapacity(CheckDate);
```

### **Örnek Veri**
```sql
INSERT INTO LocationLmsDiscCapacity 
VALUES ('Cevahir', 500.00, 150.75, 349.25, '2024-01-15 10:30:00');
```

---

## 🔧 PowerShell Script Detayları

### **Script Yapısı**

#### **1. Konfigürasyon**
```powershell
$connectionString = "Server=GMDCMUCARERNB;Database=MarsDcNocMvc;Integrated Security=True;"
```

#### **2. Ana Fonksiyonlar**

##### **Write-DebugLog**
- **Amaç**: Renkli log çıktısı
- **Parametreler**: Message, Level (INFO/WARNING/ERROR/SUCCESS)
- **Özellik**: Timestamp ile log kayıtları

##### **Get-DiskCapacity**
- **Amaç**: Disk kapasitesi bilgilerini alma
- **Parametre**: driveLetter (örn: "D")
- **Dönüş**: TotalSpace, FreeSpace, UsedSpace (GB)

##### **Write-ToDatabase**
- **Amaç**: Veritabanı UPSERT işlemi
- **Logic**: 
  - Bugün için kayıt var mı kontrol et
  - Varsa UPDATE yap
  - Yoksa INSERT yap

#### **3. İş Akışı**
```
1. Script başlangıç log
2. D: sürücüsü kapasitesi oku
3. Veri kontrolü
4. Veritabanı kayıt kontrol
5. INSERT/UPDATE işlemi
6. Başarı/hata log
7. Script bitiş
```

---

## ⚙️ Kurulum ve Konfigürasyon

### **Ön Gereksinimler**

#### **1. Sistem Gereksinimleri**
- Windows Server 2016+ veya Windows 10+
- PowerShell 5.1+
- SQL Server erişimi
- .NET Framework 4.7.2+

#### **2. Veritabanı Hazırlığı**
```sql
-- Veritabanı oluşturma
CREATE DATABASE MarsDcNocMvc;

-- Tablo oluşturma
USE MarsDcNocMvc;
-- (Yukarıdaki tablo script'ini çalıştır)

-- Kullanıcı yetkilendirme
GRANT INSERT, UPDATE, SELECT ON LocationLmsDiscCapacity TO [DOMAIN\Username];
```

#### **3. PowerShell Execution Policy**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

### **Kurulum Adımları**

#### **1. Script Yerleştirme**
```
C:\Scripts\
├── CheckDiskCapacity.ps1
├── Logs\
└── Config\
```

#### **2. Konfigürasyon Düzenleme**
```powershell
# Connection string güncelleme
$connectionString = "Server=YOUR_SERVER;Database=YOUR_DB;Integrated Security=True;"

# Lokasyon adı güncelleme (isteğe bağlı)
$locationName = "YOUR_LOCATION_NAME"
```

#### **3. Test Çalıştırma**
```powershell
# Manual test
.\CheckDiskCapacity.ps1

# Detaylı test
.\CheckDiskCapacity.ps1 -Verbose
```

---

## 🚀 Çalıştırma Rehberi

### **Manuel Çalıştırma**

#### **PowerShell Console**
```powershell
# Script klasörüne git
cd C:\Scripts

# Script'i çalıştır
.\CheckDiskCapacity.ps1
```

#### **PowerShell ISE**
- Script'i açın
- F5 ile çalıştırın

### **Otomatik Çalıştırma (Task Scheduler)**

#### **Task Oluşturma**
```xml
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2">
  <Triggers>
    <CalendarTrigger>
      <StartBoundary>2024-01-01T08:00:00</StartBoundary>
      <ExecutionTimeLimit>PT1H</ExecutionTimeLimit>
      <Enabled>true</Enabled>
      <ScheduleByDay>
        <DaysInterval>1</DaysInterval>
      </ScheduleByDay>
    </CalendarTrigger>
  </Triggers>
  <Principals>
    <Principal>
      <UserId>SYSTEM</UserId>
      <LogonType>ServiceAccount</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions>
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-ExecutionPolicy Bypass -File "C:\Scripts\CheckDiskCapacity.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
```

#### **Task Scheduler Komut Satırı**
```cmd
schtasks /create /tn "Disk Capacity Check" /tr "powershell.exe -ExecutionPolicy Bypass -File C:\Scripts\CheckDiskCapacity.ps1" /sc daily /st 08:00 /ru SYSTEM
```

---

## 📊 İzleme ve Log

### **Log Seviyeleri**
- **INFO**: Bilgilendirme mesajları (Mavi)
- **WARNING**: Uyarı mesajları (Sarı)
- **ERROR**: Hata mesajları (Kırmızı)
- **SUCCESS**: Başarı mesajları (Yeşil)

### **Örnek Log Çıktısı**
```
[2024-01-15 08:30:01][INFO] Disk kapasitesi kontrolü başlıyor...
[2024-01-15 08:30:02][INFO] D: sürücüsü kapasitesi:
[2024-01-15 08:30:02][INFO] Toplam Alan: 500.00 GB
[2024-01-15 08:30:02][INFO] Boş Alan: 150.75 GB
[2024-01-15 08:30:02][INFO] Kullanılan Alan: 349.25 GB
[2024-01-15 08:30:03][INFO] Bugün için 'Cevahir' lokasyonunda kayıt bulundu, güncelleniyor...
[2024-01-15 08:30:03][SUCCESS] Disk kapasitesi veritabanında güncellendi
[2024-01-15 08:30:03][SUCCESS] İşlem başarıyla tamamlandı
[2024-01-15 08:30:03][INFO] Script tamamlandı
```

### **Log Dosyası Oluşturma (İsteğe Bağlı)**
```powershell
# Log dosyası için script'e ekleme
$logFile = "C:\Scripts\Logs\DiskCapacity_$(Get-Date -Format 'yyyyMMdd').log"
function Write-DebugLog {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp][$Level] $Message"
    Write-Host $logMessage -ForegroundColor $(switch ($Level) {
        "INFO" { "Cyan" }
        "WARNING" { "Yellow" }
        "ERROR" { "Red" }
        "SUCCESS" { "Green" }
        default { "White" }
    })
    Add-Content -Path $logFile -Value $logMessage
}
```

---

## ⚠️ Hata Yönetimi

### **Olası Hatalar ve Çözümleri**

#### **1. Veritabanı Bağlantı Hatası**
```
Hata: "A network-related or instance-specific error occurred"
Çözüm: 
- SQL Server servisinin çalıştığını kontrol edin
- Connection string'i doğrulayın
- Network connectivity test edin
- Firewall ayarlarını kontrol edin
```

#### **2. Disk Erişim Hatası**
```
Hata: "Cannot find drive. A drive with the name 'D' does not exist"
Çözüm:
- D: sürücüsünün bağlı olduğunu kontrol edin
- Script'te doğru drive letter'ı belirttiğinizden emin olun
- Disk mount durumunu kontrol edin
```

#### **3. Yetki Hatası**
```
Hata: "The user does not have permission to perform this action"
Çözüm:
- SQL Server'da kullanıcı yetkilerini kontrol edin
- PowerShell execution policy'yi kontrol edin
- Script'i administrator olarak çalıştırın
```

#### **4. PowerShell Execution Policy Hatası**
```
Hata: "Execution of scripts is disabled on this system"
Çözüm:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### **Hata Ayıklama Adımları**

#### **1. Veritabanı Bağlantısı Test**
```powershell
# Test script
$connectionString = "Server=GMDCMUCARERNB;Database=MarsDcNocMvc;Integrated Security=True;"
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    Write-Host "Veritabanı bağlantısı başarılı!" -ForegroundColor Green
    $connection.Close()
} catch {
    Write-Host "Veritabanı bağlantı hatası: $($_.Exception.Message)" -ForegroundColor Red
}
```

#### **2. Disk Erişimi Test**
```powershell
# Disk test
try {
    $drive = Get-PSDrive "D" -ErrorAction Stop
    Write-Host "D: sürücüsü erişilebilir" -ForegroundColor Green
    Write-Host "Toplam: $([math]::Round($drive.Used / 1GB, 2)) GB" -ForegroundColor Cyan
} catch {
    Write-Host "D: sürücüsü erişim hatası: $($_.Exception.Message)" -ForegroundColor Red
}
```

---

## 🔧 Bakım ve Güncellemeler

### **Periyodik Bakım Görevleri**

#### **Haftalık**
- [ ] Log dosyalarını kontrol et
- [ ] Script çalışma durumunu kontrol et
- [ ] Veritabanı bağlantısını test et

#### **Aylık**
- [ ] Veritabanı boyutunu kontrol et
- [ ] Eski kayıtları arşivle/sil
- [ ] Performance metrikleri incele

#### **Yıllık**
- [ ] Script güncellemelerini kontrol et
- [ ] Veritabanı maintenance planlama
- [ ] Sistem gereksinimlerini gözden geçir

### **Veri Temizleme Script'i**
```sql
-- 6 aydan eski kayıtları silme
DELETE FROM LocationLmsDiscCapacity 
WHERE CheckDate < DATEADD(MONTH, -6, GETDATE());

-- İstatistikler güncelleme
UPDATE STATISTICS LocationLmsDiscCapacity;
```

### **Monitoring Queries**
```sql
-- Son 7 günün verileri
SELECT LocationName, CheckDate, TotalSpace, FreeSpace, UsedSpace
FROM LocationLmsDiscCapacity 
WHERE CheckDate >= DATEADD(DAY, -7, GETDATE())
ORDER BY CheckDate DESC;

-- Disk kullanım trendi
SELECT 
    CAST(CheckDate AS DATE) as Date,
    AVG(UsedSpace) as AvgUsed,
    MAX(UsedSpace) as MaxUsed,
    MIN(FreeSpace) as MinFree
FROM LocationLmsDiscCapacity 
WHERE CheckDate >= DATEADD(DAY, -30, GETDATE())
GROUP BY CAST(CheckDate AS DATE)
ORDER BY Date;
```

---

## 📈 Gelecek Geliştirmeler

### **Fase 1: Web Dashboard**
- ASP.NET Core MVC Dashboard
- Real-time disk capacity görüntüleme
- Grafik ve chartlar
- Alert sistemi

### **Fase 2: Multi-Location Support**
- Birden fazla lokasyon desteği
- Merkezi konfigürasyon
- Lokasyon bazlı raporlama

### **Fase 3: Advanced Monitoring**
- Threshold bazlı alerting
- Email/SMS bildirimler
- Trend analizi ve prediction
- REST API geliştirme

### **Fase 4: Enterprise Features**
- LDAP/AD entegrasyonu
- Role-based access control
- Audit logging
- High availability

---

## 📞 Destek ve İletişim

### **Teknik Destek**
- **Sistem Yöneticisi**: [İletişim Bilgileri]
- **Geliştirici**: [İletişim Bilgileri]
- **NOC Ekibi**: [İletişim Bilgileri]

### **Dokümantasyon Versiyonu**
- **Versiyon**: 1.0
- **Son Güncelleme**: 2024-01-15
- **Yazar**: [İsim]
- **Durum**: Aktif

---

## 📋 Ek Notlar

### **Güvenlik Konuları**
- Connection string'de şifre kullanmaktan kaçının
- Integrated Security kullanın
- PowerShell script'lerini güvenli konumda saklayın
- Log dosyalarında hassas bilgi bulundurmayın

### **Performance Optimizasyonu**
- Veritabanı index'lerini optimize edin
- Eski kayıtları düzenli olarak arşivleyin
- Script execution time'ını izleyin
- Resource kullanımını monitörlük

### **Compliance**
- Veri saklama politikalarına uyum
- GDPR/KVKK gereklilikleri
- Audit trail gereksinimler
- Backup ve recovery planları

---

**Bu dokümantasyon, Disk Kapasitesi İzleme Sistemi'nin tüm teknik detaylarını içermektedir. Sistem geliştirme, bakım ve kullanım süreçlerinde referans olarak kullanılabilir.** 