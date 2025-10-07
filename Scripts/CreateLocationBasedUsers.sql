-- Her Lokasyon İçin Kullanıcı Oluşturma Script'i
-- Kullanıcı adı: Lokasyon adı, Şifre: Mars2025!

USE [master]
GO

-- Mevcut lokasyonları al ve her biri için kullanıcı oluştur
DECLARE @LocationName NVARCHAR(255)
DECLARE @Username NVARCHAR(255)
DECLARE @Password NVARCHAR(255) = 'Mars2025!'
DECLARE @Role NVARCHAR(50) = 'User'

-- Cursor ile lokasyonları gez
DECLARE location_cursor CURSOR FOR
SELECT Name FROM Locations WHERE Name != 'Merkez'  -- Admin zaten Merkez'de

OPEN location_cursor
FETCH NEXT FROM location_cursor INTO @LocationName

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @Username = @LocationName
    
    -- Kullanıcı zaten var mı kontrol et
    IF NOT EXISTS (SELECT 1 FROM Users WHERE Username = @Username)
    BEGIN
        -- Yeni kullanıcı oluştur
        INSERT INTO Users (Username, Password, Role, LocationName, PhoneNumber)
        VALUES (@Username, @Password, @Role, @LocationName, NULL)
        
        PRINT 'Kullanıcı oluşturuldu: ' + @Username + ' (Lokasyon: ' + @LocationName + ')'
    END
    ELSE
    BEGIN
        -- Mevcut kullanıcının şifresini güncelle
        UPDATE Users 
        SET Password = @Password, LocationName = @LocationName
        WHERE Username = @Username
        
        PRINT 'Kullanıcı güncellendi: ' + @Username + ' (Lokasyon: ' + @LocationName + ')'
    END
    
    FETCH NEXT FROM location_cursor INTO @LocationName
END

CLOSE location_cursor
DEALLOCATE location_cursor

-- Özet bilgi
SELECT 
    COUNT(*) as 'Toplam Kullanıcı Sayısı',
    COUNT(CASE WHEN Role = 'Admin' THEN 1 END) as 'Admin Sayısı',
    COUNT(CASE WHEN Role = 'User' THEN 1 END) as 'User Sayısı'
FROM Users

PRINT 'Lokasyon bazlı kullanıcı oluşturma işlemi tamamlandı!'
PRINT 'Tüm kullanıcıların şifresi: Mars2025!' 