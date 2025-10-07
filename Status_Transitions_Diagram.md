# Status Transitions - Durum Geçiş Diyagramı

```mermaid
stateDiagram-v2
    [*] --> New : 🆕 İlk keşif<br/>DCP Online'da bulundu<br/>BackupLogs'da yok
    
    New --> New : 🔄 Boyut değişikliği<br/>Dosya güncelleniyor<br/>Timer sıfırla
    
    New --> Stable : ⏰ Zaman koşulu<br/>5+ dakika boyut değişmedi<br/>Dosya kararlı hale geldi
    
    Stable --> New : 🔄 Boyut değişikliği<br/>Tekrar güncelleme var<br/>Timer sıfırla
    
    Stable --> MovedToWatchFolder : ✅ Kopyalama başarılı<br/>WatchFolder'a taşındı<br/>İşlem tamamlandı
    
    MovedToWatchFolder --> [*] : 🏁 Final durum<br/>İşlem tamamlandı<br/>Backup'a hazır
    
    New --> CopyError : ❌ Kopyalama hatası<br/>Stable'dan geçerken<br/>Teknik sorun
    
    Stable --> CopyError : ❌ Kopyalama hatası<br/>WatchFolder erişim sorunu<br/>Disk alanı yetersiz
    
    CopyError --> New : 🔄 Yeniden deneme<br/>Manuel müdahale sonrası<br/>Durum düzeltildi
    
    CopyError --> Stable : 🔄 Durum düzeltme<br/>Dosya kararlı hale geldi<br/>Tekrar kopyalama hazır
    
    note right of New
        🔍 Özellikleri:
        • IsProcessed = false
        • İlk boyut kaydı
        • LastModified kaydedilir
        • Timer başlatılır
    end note
    
    note right of Stable
        ⏰ Özellikleri:
        • IsProcessed = false
        • 5+ dakika boyut sabit
        • Kopyalamaya hazır
        • WatchFolder kontrolü
    end note
    
    note right of MovedToWatchFolder
        ✅ Özellikleri:
        • IsProcessed = true
        • WatchFolder'da mevcut
        • Backup'a hazır durum
        • Final status
    end note
    
    note right of CopyError
        ❌ Özellikleri:
        • IsProcessed = false
        • Hata detayları logged
        • Manual intervention gerekli
        • Retry durumu
    end note
</code_block_to_apply_changes_from> 