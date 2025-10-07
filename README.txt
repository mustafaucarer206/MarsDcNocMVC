================================================================================
                    MARS DC NOC BACKUP SISTEMI - KULLANIM KILAVUZU
================================================================================

📁 DOSYA LISTESI:
----------------
• BackupScript.ps1                      → FTP'den dosya indirme scripti
• DcpOnlineFolderTracker.ps1           → Klasör takip ve kopyalama scripti  
• CheckServerStatus.ps1                → Sunucu durumu kontrol scripti
• CheckDiskCapacity.ps1                → Disk kapasitesi kontrol scripti
• CommonFunctions.psm1                 → Ortak fonksiyonlar modülü
• CheckDiskCapacity_System_Documentation.md → Disk kapasitesi sistemi dökümantasyonu

🎯 DEBUG MODUNDA ÇALIŞTIRMA (Detaylı Loglar):
--------------------------------------------
• RunBackupScript.bat                  → BackupScript'i debug modunda çalıştırır
• RunDcpOnlineFolderTracker.bat       → DcpOnlineFolderTracker'ı debug modunda çalıştırır
• RunCheckServerStatus.bat            → CheckServerStatus'u debug modunda çalıştırır
• RunCheckDiskCapacity.bat            → CheckDiskCapacity'yi debug modunda çalıştırır

🚀 PRODUCTION MODUNDA ÇALIŞTIRMA (Sessiz Çalışma):
-------------------------------------------------
• RunBackupScript_Production.bat      → BackupScript'i production modunda çalıştırır
• RunDcpOnlineFolderTracker_Production.bat → DcpOnlineFolderTracker'ı production modunda çalıştırır

📋 ÇALIŞMA SIRASI:
-----------------
1. ÖNCE: RunBackupScript.bat veya RunBackupScript_Production.bat
   → FTP'den dosyaları D:\DCP Online\ klasörüne indirir

2. SONRA: RunDcpOnlineFolderTracker.bat veya RunDcpOnlineFolderTracker_Production.bat  
   → D:\DCP Online\'daki stabil klasörleri D:\WatchFolder\'a kopyalar

3. İHTİYAÇ DURUMUNDA:
   → RunCheckServerStatus.bat - Sunucu durumu kontrolü
   → RunCheckDiskCapacity.bat - Disk kapasitesi kontrolü

⚙️ GEREKSINIMLER:
----------------
• WinSCP kurulu olmalı (BackupScript için)
• SQL Server veritabanı erişimi
• D:\DCP Online\ ve D:\WatchFolder\ klasörleri (otomatik oluşturulur)

📊 VERITABANI TABLOLARI:
-----------------------
• BackupLogs                    → Backup işlem geçmişi
• DcpOnlineFolderTracking      → Klasör takip bilgileri

🔧 PARAMETRELER:
---------------
• stableWaitMinutes = 5 dakika  → Klasörlerin stabil olma süresi
• oldFolderHours = 72 saat     → Eski klasörlerin temizlenme süresi

📞 DESTEK:
---------
Hata durumunda veritabanı loglarını kontrol edin.
Debug modunda çalıştırarak detaylı bilgi alabilirsiniz.

Versiyon: 1.0
Tarih: Haziran 2025
================================================================================ 