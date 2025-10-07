# Disk Capacity Check - İş Akışı Diyagramı

```mermaid
flowchart TD
    Start([🚀 Disk Kapasitesi Kontrolü Başlatıldı]) --> InitVars["🔧 Başlangıç<br/>- Database bağlantı<br/>- Lokasyon listesi<br/>- Eşik değerleri"]
    
    InitVars --> CreateDirs["📂 Klasörleri oluştur<br/>Log klasörleri"]
    
    CreateDirs --> LoadLocations["🌍 Lokasyonları yükle<br/>Locations.txt'den"]
    LoadLocations --> LoadSuccess{📋 Yükleme başarılı mı?}
    
    LoadSuccess -->|Hayır| ExitNoLocations["❌ Çıkış: Lokasyon listesi okunamadı"]
    LoadSuccess -->|Evet| LoopLocations{🌍 Lokasyon döngüsü}
    
    LoopLocations -->|Tüm lokasyonlar kontrol edildi| FinalReport["📊 Final rapor hazırla<br/>Özet istatistikler"]
    LoopLocations -->|Sonraki lokasyon| ParseLocation["📍 Lokasyonu parse et<br/>Name, Path, Percentage"]
    
    ParseLocation --> ValidateFormat{✅ Format geçerli mi?<br/>Name|Path|Percentage}
    ValidateFormat -->|Hayır| LogFormatError["❌ Format hatası logu<br/>Geçersiz satır"] --> NextLocation
    ValidateFormat -->|Evet| TestConnection["🔗 Network bağlantısı test<br/>Ping & Path erişimi"]
    
    TestConnection --> ConnectionOK{🔗 Bağlantı var mı?}
    ConnectionOK -->|Hayır| LogConnectionError["❌ Bağlantı hatası logu<br/>Status: Offline"] --> UpdateDatabase
    ConnectionOK -->|Evet| GetDiskInfo["💾 Disk bilgilerini al<br/>Total & Free Space"]
    
    GetDiskInfo --> DiskInfoOK{💾 Disk bilgisi alındı mı?}
    DiskInfoOK -->|Hayır| LogDiskError["❌ Disk bilgisi hatası<br/>WMI/CIM hatası"] --> UpdateDatabase
    DiskInfoOK -->|Evet| CalculateUsage["📊 Kullanım yüzdesini hesapla<br/>Used = (Total - Free) / Total * 100"]
    
    CalculateUsage --> CheckThreshold{⚠️ Eşik değeri kontrolü}
    CheckThreshold -->|>= %90| StatusCritical["🔴 Critical<br/>Kritik seviye alarm"] --> LogCritical["🚨 Critical log<br/>Email bildirim hazırla"]
    CheckThreshold -->|>= %80| StatusWarning["🟡 Warning<br/>Uyarı seviyesi"] --> LogWarning["⚠️ Warning log<br/>İzleme gerekli"]
    CheckThreshold -->|< %80| StatusNormal["🟢 Normal<br/>Sağlıklı seviye"] --> LogNormal["✅ Normal log<br/>Durum OK"]
    
    LogCritical --> PrepareEmail["📧 Email bildirim hazırla<br/>IT ekibi için"]
    LogWarning --> UpdateDatabase
    LogNormal --> UpdateDatabase
    
    PrepareEmail --> UpdateDatabase["🗃️ Database güncelle<br/>DiskCapacityLogs tablosu"]
    
    UpdateDatabase --> DatabaseOK{🗃️ Database güncellemesi başarılı mı?}
    DatabaseOK -->|Hayır| LogDatabaseError["❌ Database hatası logu"]
    DatabaseOK -->|Evet| LogSuccess["✅ Başarılı güncelleme logu"]
    
    LogDatabaseError --> NextLocation["➡️ Sonraki lokasyon"]
    LogSuccess --> NextLocation
    UpdateDatabase --> NextLocation
    
    NextLocation --> LoopLocations
    
    FinalReport --> SendEmails["📧 Critical email'leri gönder<br/>Topluca bildirim"]
    SendEmails --> EmailResult{📧 Email gönderimi başarılı mı?}
    
    EmailResult -->|Hayır| LogEmailError["❌ Email gönderim hatası"]
    EmailResult -->|Evet| LogEmailSuccess["✅ Email gönderim başarılı"]
    
    LogEmailError --> CleanupLogs["🧹 Eski logları temizle<br/>30+ gün"]
    LogEmailSuccess --> CleanupLogs
    
    CleanupLogs --> GenerateStats["📈 İstatistik raporu<br/>- Normal: X<br/>- Warning: Y<br/>- Critical: Z"]
    
    GenerateStats --> End([🏁 Script Tamamlandı])
    
    %% Hata çıkışları
    ExitNoLocations --> EndError([❌ Hatalı bitiş])
    
    %% Stil tanımlamaları
    style StatusNormal fill:#e8f5e8,stroke:#2e7d32
    style StatusWarning fill:#fff8e1,stroke:#f57c00
    style StatusCritical fill:#ffebee,stroke:#d32f2f
    style LogCritical fill:#ffcdd2,stroke:#c62828
    style LogWarning fill:#ffe0b2,stroke:#ef6c00
    style LogNormal fill:#c8e6c9,stroke:#388e3c
    style PrepareEmail fill:#e1f5fe,stroke:#0277bd
    style SendEmails fill:#e8eaf6,stroke:#3f51b5
</code_block_to_apply_changes_from> 