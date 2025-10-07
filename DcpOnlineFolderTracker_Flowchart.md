# DCP Online Folder Tracker - İş Akışı Diyagramı

```mermaid
flowchart TD
    Start([🚀 Script Başlatıldı]) --> InitVars["🔧 Değişkenleri Başlat<br/>- Global sayaçlar<br/>- Database bağlantısı<br/>- Klasör yolları"]
    
    InitVars --> CheckDirs{📁 Klasörler mevcut mu?<br/>DCP Online & WatchFolder}
    CheckDirs -->|Hayır| CreateDirs["📂 Klasörleri Oluştur"]
    CheckDirs -->|Evet| GetBackupLogs["📋 BackupLogs'dan<br/>İşlenmiş klasörleri al"]
    CreateDirs --> GetBackupLogs
    
    GetBackupLogs --> ScanFolders["🔍 DCP Online klasörünü tara<br/>Tüm alt klasörleri listele"]
    
    ScanFolders --> LoopStart{📂 Sonraki klasör var mı?}
    LoopStart -->|Hayır| CleanupOld["🧹 Eski klasörleri temizle<br/>(72+ saat)"]
    LoopStart -->|Evet| CheckBackup{🔍 BackupLogs'da var mı?}
    
    CheckBackup -->|Evet| SkipFolder["⏭️ Atla<br/>Zaten işlenmiş"] --> NextFolder["➡️ Sonraki klasör"]
    CheckBackup -->|Hayır| CalcSize["📏 Klasör boyutunu hesapla"]
    
    CalcSize --> CheckTracker{🗃️ DcpOnlineTracking'de var mı?}
    
    CheckTracker -->|Hayır| NewRecord["🆕 YENİ KAYIT<br/>Status: New<br/>IsProcessed: false"]
    CheckTracker -->|Evet| GetStatus{📊 Mevcut Status?}
    
    GetStatus -->|New| CheckStable{⏱️ Stabil mi?<br/>5+ dakika değişmemiş?}
    GetStatus -->|Stable| CopyToWatch["📁 WatchFolder'a kopyala"]
    GetStatus -->|MovedToWatchFolder| AlreadyProcessed["✅ Zaten işlenmiş"] --> NextFolder
    
    CheckStable -->|Hayır - Boyut değişmiş| ResetToNew["🔄 Status: New<br/>Boyut güncellenmiş"]
    CheckStable -->|Evet| UpdateStable["⏰ Status: Stable<br/>Kopyalamaya hazır"]
    
    CopyToWatch --> CopyCheck{📋 WatchFolder'da var mı?}
    CopyCheck -->|Evet| SkipCopy["⏭️ Zaten mevcut"] --> UpdateMoved
    CopyCheck -->|Hayır| DoCopy["📦 Kopyalama işlemi"]
    
    DoCopy --> CopyResult{✅ Başarılı mı?}
    CopyResult -->|Evet| UpdateMoved["✅ Status: MovedToWatchFolder<br/>IsProcessed: true"]
    CopyResult -->|Hayır| UpdateError["❌ Status: CopyError<br/>Hata kaydedildi"]
    
    NewRecord --> NextFolder
    ResetToNew --> NextFolder
    UpdateStable --> NextFolder
    UpdateMoved --> NextFolder
    UpdateError --> NextFolder
    AlreadyProcessed --> NextFolder
    SkipCopy --> NextFolder
    
    NextFolder --> LoopStart
    
    CleanupOld --> FinalStats["📊 İstatistikleri hazırla<br/>- Toplam kontrol edilen<br/>- Yeni bulunan<br/>- Kopyalanan<br/>- Başarısız"]
    
    FinalStats --> Shutdown["🔚 Graceful Shutdown<br/>- Oturumları kapat<br/>- Kaynakları temizle<br/>- Final rapor"]
    
    Shutdown --> End([🏁 Script Tamamlandı])
    
    %% Stil tanımlamaları
    style NewRecord fill:#e1f5fe,stroke:#01579b
    style UpdateStable fill:#f3e5f5,stroke:#4a148c
    style UpdateMoved fill:#e8f5e8,stroke:#1b5e20
    style UpdateError fill:#ffebee,stroke:#b71c1c
    style ResetToNew fill:#fff3e0,stroke:#e65100
    style SkipFolder fill:#f5f5f5,stroke:#616161
    style AlreadyProcessed fill:#e8f5e8,stroke:#388e3c
</code_block_to_apply_changes_from> 