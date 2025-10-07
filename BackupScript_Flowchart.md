# Backup Script - İş Akışı Diyagramı

```mermaid
flowchart TD
    Start([🚀 Backup Script Başlatıldı]) --> CheckMutex{🔒 Mutex kontrolü<br/>Başka instance çalışıyor mu?}
    
    CheckMutex -->|Evet| ExitMutex["❌ Çıkış: Instance zaten çalışıyor"]
    CheckMutex -->|Hayır| InitVars["🔧 Başlangıç<br/>- FTP bilgileri<br/>- Global değişkenler<br/>- Klasör yolları"]
    
    InitVars --> LoadWinSCP["📦 WinSCP DLL yükle"]
    LoadWinSCP --> LoadSuccess{✅ Başarılı mı?}
    LoadSuccess -->|Hayır| ExitDLL["❌ Çıkış: DLL yüklenemedi"]
    LoadSuccess -->|Evet| CreateDirs["📂 Klasörleri oluştur<br/>Local & Destination"]
    
    CreateDirs --> CheckDisk["💾 Disk alanı kontrolü<br/>Min: 50GB gerekli"]
    CheckDisk --> DiskOK{💾 Yeterli alan var mı?}
    DiskOK -->|Hayır| ExitDisk["❌ Çıkış: Yetersiz disk alanı"]
    DiskOK -->|Evet| ConnectFTP["🌐 FTP bağlantısı oluştur"]
    
    ConnectFTP --> FTPSuccess{🌐 Bağlantı başarılı mı?}
    FTPSuccess -->|Hayır| ExitFTP["❌ Çıkış: FTP bağlantı hatası"]
    FTPSuccess -->|Evet| GetDownloaded["📋 İndirilmiş klasörleri al<br/>BackupLogs'dan"]
    
    GetDownloaded --> LoopSource{📁 Kaynak dizin döngüsü<br/>REKLAM_DATA & FRAGMAN_DATA}
    LoopSource -->|Dizin bitir| CloseConnection["🔌 FTP bağlantısını kapat"]
    LoopSource -->|Sonraki dizin| ListRemote["📂 Uzak klasörleri listele<br/>FTP'den"]
    
    ListRemote --> LoopFolder{📂 Klasör döngüsü}
    LoopFolder -->|Tüm klasörler bitti| LoopSource
    LoopFolder -->|Sonraki klasör| CheckDownloaded{📋 Daha önce indirilmiş mi?}
    
    CheckDownloaded -->|Evet| SkipDownloaded["⏭️ Atla: Zaten indirilmiş"] --> NextFolder
    CheckDownloaded -->|Hayır| CheckExists{📁 Local'de var mı?}
    
    CheckExists -->|Evet| SkipExists["⏭️ Atla: Local'de mevcut"] --> NextFolder
    CheckExists -->|Hayır| LogStart["📝 İndirme başlangıcı log"]
    
    LogStart --> StartDownload["⬇️ İndirme başlat<br/>FTP'den Local'e"]
    StartDownload --> DownloadSuccess{⬇️ İndirme başarılı mı?}
    
    DownloadSuccess -->|Hayır| LogError["❌ Hata logu<br/>Status: 0"] --> NextFolder
    DownloadSuccess -->|Evet| LogDownloadOK["✅ İndirme tamamlandı logu<br/>Status: 1"]
    
    LogDownloadOK --> MoveToDestination["📦 Hedef klasöre taşı<br/>Local'den Destination'a"]
    MoveToDestination --> MoveSuccess{📦 Taşıma başarılı mı?}
    
    MoveSuccess -->|Hayır| LogMoveError["❌ Taşıma hatası logu"] --> NextFolder
    MoveSuccess -->|Evet| LogMoveOK["✅ Taşıma tamamlandı logu<br/>Transfer complete"]
    
    LogMoveOK --> CleanLocal["🧹 Local klasörü temizle"]
    CleanLocal --> NextFolder["➡️ Sonraki klasör"]
    NextFolder --> LoopFolder
    
    CloseConnection --> LogSummary["📊 Özet log<br/>SYSTEM_SUMMARY"]
    LogSummary --> CleanupJobs["🧹 Background job'ları temizle"]
    CleanupJobs --> ReleaseMutex["🔓 Mutex'i serbest bırak"]
    ReleaseMutex --> FinalStats["📈 Final istatistikler<br/>İşlenen/Başarılı/Başarısız"]
    
    FinalStats --> End([🏁 Script Tamamlandı])
    
    %% Hata çıkışları
    ExitMutex --> EndError([❌ Hatalı bitiş])
    ExitDLL --> EndError
    ExitDisk --> EndError
    ExitFTP --> EndError
    
    %% Stil tanımlamaları
    style StartDownload fill:#e3f2fd,stroke:#0277bd
    style LogDownloadOK fill:#e8f5e8,stroke:#2e7d32
    style LogError fill:#ffebee,stroke:#c62828
    style MoveToDestination fill:#f3e5f5,stroke:#7b1fa2
    style LogMoveOK fill:#e8f5e8,stroke:#388e3c
    style SkipDownloaded fill:#f5f5f5,stroke:#757575
    style SkipExists fill:#f5f5f5,stroke:#757575
</code_block_to_apply_changes_from> 