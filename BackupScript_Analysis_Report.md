# BackupScript.ps1 Detaylı Analiz Raporu
## 🔍 Potansiyel Sorunlar ve Güvenlik Açıkları

---

## 🚨 KRİTİK SORUNLAR

### **1. FTP Kimlik Bilgileri Güvenlik Açığı**
```powershell
# SORUN: Şifreler açık metin olarak kodda yer alıyor
$ftpHost = "178.132.50.11"
$ftpUser = "marsreklamsys"  
$ftpPassword = "0VvObepFTxjBdZQ"  # ❌ GÜVENLİK AÇIĞI!
```
**RİSK LEVEL: CRİTİCAL**
- FTP şifresi açık metin olarak kodda
- Kod versiyonlanırsa şifre history'de kalır
- Log dosyalarında şifre görünebilir

### **2. Database Connection String Açığı**
```powershell
$connectionString = "Server=34CEVTMS\SQLEXPRESS;Database=master;Integrated Security=True;"
```
**RİSK LEVEL: MEDIUM**
- Server bilgileri kodda açık
- Database bilgileri versiyonlanıyor

### **3. Resource Disposal Sorunları**

#### **3.1. WinSCP Session Disposal**
```powershell
# SORUN: Ana script sonunda sadece $session.Dispose() var
# Ama exception durumlarında session açık kalabilir
```

#### **3.2. Database Connection Cleanup**
```powershell
function Clean-OldLogs {
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        # ... işlemler
        $connection.Close()  # ❌ Finally block yok!
    } catch {
        # Connection açık kalabilir
    }
}
```

---

## ⚠️ ORTA SEVİYE SORUNLAR

### **4. Transaction Rollback Sorunları**
```powershell
# SORUN: Transaction rollback catch içinde yapılıyor ama
# transaction null olma durumu kontrol edilmiyor
catch {
    $transaction.Rollback()  # ❌ Null reference exception riski
}
```

### **5. Memory Leak Potansiyeli**
```powershell
# SORUN: Büyük dosyalar için Get-FolderSize memory problemi yaratabilir
function Get-FolderSize {
    $size = (Get-ChildItem -Path $folderPath -Recurse -File | Measure-Object -Property Length -Sum).Sum
    # ❌ Çok büyük klasörler için memory sorunu
}
```

### **6. Concurrent Execution Sorunları**
```powershell
# SORUN: Aynı anda birden fazla script çalışırsa
# File locking ve database deadlock riski
```

### **7. Path Injection Riski**
```powershell
# SORUN: Folder name'ler doğrudan path'e ekleniyor
$localFolderPath = "$localBackupPath\$($folder.Name)\"
# ❌ Folder.Name içinde ".." veya "/" karakterleri varsa güvenlik riski
```

---

## 🐛 MANTIK HATALARI

### **8. Disk Space Calculation Hatası**
```powershell
function Get-DiskSpace {
    return @{
        FreeSpace = [math]::Round($drive.Free / 1GB, 2)
        TotalSpace = [math]::Round($drive.Used / 1GB, 2)  # ❌ YANLIŞ!
    }
}
# TotalSpace = Used + Free olmalı, sadece Used değil!
```

### **9. Division by Zero Riski**
```powershell
# SORUN: $sizeDifferencePercentage hesaplanmasında
$sizeDifferencePercentage = ($sizeDifference / $previousSize) * 100
# ❌ $previousSize = 0 ise division by zero!
```

### **10. File Size Comparison Problemi**
```powershell
# SORUN: Boyut kontrolünde tolerance sadece mutlak değer
if ($sizeDifference -le $tolerance -or $sizeDifferencePercentage -le 0.1) {
    # ❌ $previousSize = 0 olduğunda $sizeDifferencePercentage hesaplanamıyor
}
```

---

## 🔄 PERFORMANS SORUNLARI

### **11. N+1 Database Query Problemi**
```powershell
# SORUN: Her klasör için ayrı database connection açılıyor
foreach ($folder in $currentFolders) {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    # ❌ Her iterasyonda yeni connection
}
```

### **12. Büyük File Transfer Timeout**
```powershell
# SORUN: Timeout ayarları yok
$transferOptions = New-Object WinSCP.TransferOptions
# ❌ Çok büyük dosyalar için timeout sorunu
```

### **13. Inefficient Old Folder Cleanup**
```powershell
# SORUN: Her klasör için ayrı database işlemi
foreach ($oldFolder in $oldFolders) {
    # Database işlemi
    # File system işlemi
}
# ❌ Batch operation yapılmalı
```

---

## 🔒 EXCEPTION HANDLING SORUNLARI

### **14. Swallowed Exceptions**
```powershell
function Write-ToDatabase {
    try {
        # Database operations
    } catch {
        Write-Host "Veritabani yazma hatasi: $_" -ForegroundColor Red
        # ❌ Exception yutulur, üst seviyeye bildirilmez
    }
}
```

### **15. Generic Exception Handling**
```powershell
catch {
    Write-DebugLog "DCP Online klasor takibi hatasi: $_" -Level "ERROR"
    # ❌ Farklı exception tiplerini farklı handle etmeli
}
```

---

## 📊 LOGGING VE MONİTORİNG SORUNLARI

### **16. Debug Log Security Issue**
```powershell
Write-DebugLog "FTP Connection info: Host=$ftpHost, User=$ftpUser" -Level "INFO"
# ❌ FTP bilgileri loglanıyor, güvenlik riski
```

### **17. Insufficient Error Context**
```powershell
Write-DebugLog "Klasor silme hatasi: $_" -Level "ERROR"
# ❌ Hangi klasör, hangi operation için hata olduğu belirsiz
```

---

## 🎯 ÖNERİLEN ÇÖZÜMLER

### **1. Güvenlik İyileştirmeleri**
```powershell
# Credential Manager kullan
$ftpCredential = Get-StoredCredential -Target "MarsBackupFTP"
$ftpUser = $ftpCredential.UserName
$ftpPassword = $ftpCredential.GetNetworkCredential().Password

# Veya Environment Variables
$ftpPassword = $env:MARS_FTP_PASSWORD
```

### **2. Resource Management İyileştirmesi**
```powershell
function Invoke-SafeDatabaseOperation {
    param([scriptblock]$Operation)
    
    $connection = $null
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
        $connection.Open()
        return & $Operation $connection
    }
    finally {
        if ($connection -and $connection.State -eq 'Open') {
            $connection.Close()
            $connection.Dispose()
        }
    }
}
```

### **3. Improved Exception Handling**
```powershell
try {
    # Operations
}
catch [System.Data.SqlClient.SqlException] {
    Write-DebugLog "Database error: $($_.Exception.Message)" -Level "ERROR"
    # Database specific handling
}
catch [System.IO.IOException] {
    Write-DebugLog "File system error: $($_.Exception.Message)" -Level "ERROR"
    # File system specific handling
}
catch {
    Write-DebugLog "Unexpected error: $($_.Exception.Message)" -Level "ERROR"
    throw  # Re-throw unknown exceptions
}
```

### **4. Path Sanitization**
```powershell
function Get-SafePath {
    param([string]$BasePath, [string]$SubPath)
    
    # Path traversal saldırılarını önle
    $sanitizedSubPath = $SubPath -replace '\.\.', '' -replace '[<>:"|?*]', '_'
    return Join-Path -Path $BasePath -ChildPath $sanitizedSubPath
}
```

### **5. Concurrent Execution Prevention**
```powershell
# Script başında mutex kullan
$mutexName = "Global\MarsDcNocBackup"
$mutex = New-Object System.Threading.Mutex($false, $mutexName)

if (-not $mutex.WaitOne(100)) {
    Write-Host "Başka bir backup işlemi çalışıyor. Çıkılıyor..." -ForegroundColor Yellow
    exit
}

try {
    # Ana script logic
}
finally {
    $mutex.ReleaseMutex()
    $mutex.Dispose()
}
```

---

## 🧪 TEST ÖNERİLERİ

### **1. Unit Tests**
- Database connection handling
- File size calculation
- Path sanitization
- Error scenarios

### **2. Integration Tests**
- FTP connection failures
- Database unavailability
- Disk space scenarios
- Large file transfers

### **3. Performance Tests**
- Memory usage with large folders
- Database connection pooling
- Concurrent execution
- Network interruption scenarios

### **4. Security Tests**
- Path traversal attempts
- SQL injection (parametreli sorgular varsa)
- Credential exposure in logs
- Unauthorized file access

---

## 📈 İZLEME METRİKLERİ

### **Eklenmesi Gereken Metrikler:**
1. **Script execution time**
2. **Memory usage peak**
3. **Database connection count**
4. **Failed transfer count**
5. **Disk space utilization**
6. **FTP connection latency**
7. **Exception frequency by type**

---

## 🎨 SONUÇ VE ÖNCELİKLER

### **Acil Düzeltilmesi Gerekenler (P0):**
1. ✅ FTP şifre güvenliği
2. ✅ Resource disposal sorunları
3. ✅ Division by zero hataları
4. ✅ Transaction null check

### **Kısa Vadede Düzeltilmesi Gerekenler (P1):**
1. ✅ Concurrent execution prevention
2. ✅ Path injection koruması  
3. ✅ Improved error handling
4. ✅ Disk space calculation fix

### **Orta Vadede İyileştirmeler (P2):**
1. ✅ Performance optimizations
2. ✅ Better logging
3. ✅ Monitoring metrics
4. ✅ Unit tests

Bu analiz sonucunda, script'in çalışır durumda olmasına rağmen üretim ortamında güvenlik ve kararlılık açısından ciddi riskleri bulunmaktadır. Öncelikle P0 seviyesindeki sorunların çözülmesi kritik önemdedir. 