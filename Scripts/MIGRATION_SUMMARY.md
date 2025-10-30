# PostgreSQL → MSSQL Migration Özet Raporu

**Tarih:** 7 Ekim 2025  
**Süre:** 10.7 dakika  
**Durum:** Kısmen Başarılı

---

## ✅ Başarıyla Aktarılan Tablolar (80/96)

**Toplam Aktarılan Kayıt:** 22,803

### Önemli Başarılı Tablolar:
- ✅ `cpl_validation` - 8,286 kayıt (Film doğrulama bilgileri)
- ✅ `quick_cue_map` - 158 kayıt
- ✅ `bookend_setting` - 154 kayıt
- ✅ `cpl_sync_transfer_date` - 5,084 kayıt
- ✅ `cpl_custom_parameters` - 4,506 kayıt
- ✅ `user_type` - 7 kayıt

---

## ❌ Aktarılamayan Kritik Tablolar

### 1. **cpl** (Filmler) - 0/8,093 kayıt
**PostgreSQL'de:** 8,093 film  
**MSSQL'de:** 0 kayıt  
**Sorun:** Dosya adı/uzantısı çok uzun hatası  
**Çözüm:** Manuel CSV export/import veya örnekleme

### 2. **device** (Cihazlar) - 0/30 kayıt
**PostgreSQL'de:** 30 cihaz  
**MSSQL'de:** 0 kayıt  
**Çözüm:** Manuel aktarım gerekli

### 3. **screen** (Salonlar) - 0/11 kayıt
**PostgreSQL'de:** 11 salon  
**MSSQL'de:** 0 kayıt  
**Çözüm:** Manuel aktarım gerekli

### 4. **device_cpl_map** (Cihaz-Film Eşleştirmesi)
**PostgreSQL'de:** 0 kayıt (zaten boş)  
**MSSQL'de:** 0 kayıt  
**Not:** Bu tablo PostgreSQL'de de boş olduğu için sorun yok

---

## 📊 Mevcut Durum

### MSSQL'deki Veri:
```sql
cpl              : 0 kayıt
cpl_validation   : 8,286 kayıt ✅
device           : 0 kayıt
screen           : 0 kayıt
device_cpl_map   : 0 kayıt
```

### PostgreSQL'deki Veri:
```sql
cpl              : 8,093 kayıt (Filmler)
device           : 30 kayıt (Cihazlar - 11 Projektör)
screen           : 11 kayıt (Salonlar)
cpl_validation   : 8,286 kayıt
```

---

## 🎯 İhtiyaç Duyulan Bilgiler

### Film Detayları (cpl tablosundan):
- Film adı (`content_title`)
- Süre (`duration_in_seconds`)
- Çözünürlük (`resolution`)
- En-boy oranı (`aspect_ratio`)
- Sınıflandırma (`rating`)
- Şifrelenme durumu (`encrypted`)
- Ses dili (`audio_language`)
- Altyazı dili (`subtitle_language`)

### Cihaz Bilgileri (device tablosundan):
- Cihaz adı (`name`)
- Kategori (`category` - projector, content, lms, sms, pos, external)
- Tip (`type` - christie, gdc, ftp, local, vb.)
- Model (`model`)
- IP adresi (`ip`)
- Salon (`screen_uuid`)

### Validation Bilgileri (cpl_validation tablosundan) ✅:
- Film UUID (`cpl_uuid`)
- Cihaz UUID (`device_uuid`)
- Doğrulama durumu (`validated`)
- Doğrulama tipi (`validation_type`)
- Doğrulama tarihi (`validation_date`)

---

## 💡 Öneriler

### 1. Hızlı Çözüm (Örnekleme):
- İlk 500 filmi manuel aktar
- 30 cihazı manuel aktar
- 11 salonu manuel aktar
- Mevcut `cpl_validation` ile birleştir

### 2. Tam Çözüm:
- PostgreSQL'den CSV export al
- MSSQL BULK INSERT kullan
- Tüm 8,093 filmi aktar

### 3. Alternatif:
- Sadece doğrulanmış filmleri al (cpl_validation'dan)
- Device ve screen bilgilerini ekle
- VIEW ile birleştir

---

## 📝 Sonraki Adımlar

1. ✅ Migration scripti tamamlandı
2. ⏳ Kritik tabloları manuel aktar (cpl, device, screen)
3. ⏳ Film-Cihaz-Salon VIEW'i oluştur
4. ⏳ Web arayüzü ekle (MVC Controller/View)

---

## 🔍 Bulgular - Lamba Bilgisi

### Projektör Cihazları:
- **11 adet** Christie projektör
- **Modeller:** Solaria-One, CP2230U, CP2210, CP2230, CP2220

### Lamba İlgili Tablolar:
- `ieb_process` - `lamp_wait` sütunu mevcut
- `probe_measurement` - Işık ölçümleri (şu an boş)
- `probe_calibration` - Kalibrasyon kayıtları (şu an boş)

### Not:
Lamba saati (lamp hours) bilgisi bu veritabanında bulunmuyor.  
Muhtemelen harici bir sistemde veya cihaz loglarında tutuluyor.

---

**Hazırlayan:** AI Migration Tool  
**Versiyon:** 1.0
