# Lokasyon Bazlı Kullanıcı Oluşturma - Deployment Kılavuzu

## Özellik Özeti
Her lokasyon için otomatik kullanıcı oluşturma sistemi:
- **Kullanıcı Adı:** Lokasyon adı ile aynı
- **Şifre:** `Mars2025!` (tüm kullanıcılar için sabit)
- **Rol:** `User` (Normal kullanıcı)
- **Lokasyon:** İlgili lokasyon

## 🚀 Deployment Adımları

### 1. SQL Script ile Oluşturma (Hızlı)

```sql
-- SQL Server Management Studio'da çalıştırın
sqlcmd -S (local) -d master -i Scripts/CreateLocationBasedUsers.sql
```

### 2. PowerShell Script ile Oluşturma (Esnek)

```powershell
# Test modu (DryRun)
.\Scripts\CreateLocationBasedUsers.ps1 -DryRun

# Gerçek oluşturma
.\Scripts\CreateLocationBasedUsers.ps1

# Özel connection string ile
.\Scripts\CreateLocationBasedUsers.ps1 -ConnectionString "Server=myserver;Database=mydb;..."
```

### 3. C# Console Application (Gelişmiş)

```bash
# Console app olarak çalıştırma
dotnet run Scripts/CreateLocationBasedUsers.cs

# Test modu
dotnet run Scripts/CreateLocationBasedUsers.cs -- --dry-run
```

### 4. Web Interface (En Kolay)

1. Admin olarak giriş yapın
2. **"Lokasyon Kullanıcıları"** menüsüne gidin
3. İstediğiniz işlemi seçin:
   - **"Eksik Kullanıcıları Oluştur"** - Sadece eksikleri ekler
   - **"Tümünü Oluştur/Güncelle"** - Hepsini günceller
   - **"Şifreleri Sıfırla"** - Sadece şifreleri değiştirir

## 📋 Kontrol Listeleri

### Deployment Öncesi Kontroller
- [ ] Database backup'ı alındı
- [ ] Test ortamında denenmiş
- [ ] Mevcut kullanıcıların listesi yedeklendi
- [ ] Lokasyon listesi güncel

### Deployment Sonrası Kontroller
- [ ] Tüm lokasyonların kullanıcısı oluşturuldu
- [ ] Şifreler doğru: `Mars2025!`
- [ ] Roller doğru: `User`
- [ ] Lokasyon atamaları doğru
- [ ] Web arayüzünden giriş testi yapıldı

## 🔧 Sorun Giderme

### Yaygın Hatalar

**1. Database Bağlantı Hatası**
```
Çözüm: Connection string'i kontrol edin
Server=(local);Database=master;Integrated Security=True;
```

**2. Duplicate Key Hatası**
```
Çözüm: Kullanıcı zaten mevcut, güncelleme modunu kullanın
```

**3. Lokasyon Bulunamadı**
```
Çözüm: Önce lokasyonları oluşturun
```

### Debug Komutları

```sql
-- Kullanıcı sayısını kontrol et
SELECT Role, COUNT(*) as Count FROM Users GROUP BY Role

-- Lokasyon kullanıcılarını listele
SELECT u.Username, u.LocationName, u.Role 
FROM Users u 
INNER JOIN Locations l ON u.Username = l.Name

-- Kullanıcısı olmayan lokasyonları bul
SELECT l.Name 
FROM Locations l 
LEFT JOIN Users u ON l.Name = u.Username 
WHERE u.Username IS NULL AND l.Name != 'Merkez'
```

## 🔒 Güvenlik Notları

### Önemli Uyarılar
- **Şifre:** Tüm kullanıcıların şifresi `Mars2025!` - Bu geçici bir şifredir
- **İlk Giriş:** Kullanıcılar ilk girişte şifrelerini değiştirmelidir
- **Production:** Production ortamında daha güçlü şifreler kullanın
- **Backup:** Her deployment öncesi backup alın

### Şifre Güvenliği
```csharp
// Gelecekte implement edilebilir
var hashedPassword = BCrypt.Net.BCrypt.HashPassword("Mars2025!");
```

## 📊 Raporlama

### Oluşturulan Kullanıcıları Listele
```sql
SELECT 
    u.Username,
    u.LocationName,
    u.Role,
    'Mars2025!' as DefaultPassword
FROM Users u
INNER JOIN Locations l ON u.Username = l.Name
WHERE l.Name != 'Merkez'
ORDER BY u.LocationName
```

### İstatistikler
```sql
SELECT 
    'Toplam Kullanıcı' as Tip, COUNT(*) as Sayı FROM Users
UNION ALL
SELECT 
    'Admin Kullanıcı', COUNT(*) FROM Users WHERE Role = 'Admin'
UNION ALL
SELECT 
    'Normal Kullanıcı', COUNT(*) FROM Users WHERE Role = 'User'
UNION ALL
SELECT 
    'Lokasyon Kullanıcısı', COUNT(*) 
FROM Users u INNER JOIN Locations l ON u.Username = l.Name
```

## 🚦 Rollback Planı

Eğer bir sorun olursa:

```sql
-- Sadece lokasyon kullanıcılarını sil (DIKKAT!)
DELETE FROM Users 
WHERE Username IN (
    SELECT Name FROM Locations WHERE Name != 'Merkez'
)

-- Veya belirli bir tarihe kadar olanları sil
DELETE FROM Users 
WHERE Username IN (SELECT Name FROM Locations WHERE Name != 'Merkez')
AND Id > [son_id_before_deployment]
```

## 📞 Destek

Sorun yaşarsanız:
1. Log dosyalarını kontrol edin
2. Database bağlantısını test edin
3. Console output'ları inceleyin
4. Bu dokümandaki kontrol listelerini takip edin

## 📈 Gelecek Geliştirmeler

- [ ] Şifre hash'leme
- [ ] Bulk email notifications
- [ ] Active Directory entegrasyonu
- [ ] Role-based permission system
- [ ] Audit logging 