-- BackupLogs tablosundaki bozuk Türkçe karakterleri düzelt

USE [MarsDcNocMVC]
GO

-- Action sütunundaki bozuk karakterleri düzelt
UPDATE BackupLogs 
SET Action = 'Yedekleme başladı'
WHERE Action LIKE '%ba_Ylad%' OR Action LIKE '%başlad%' OR Action LIKE '%basladi%';

UPDATE BackupLogs 
SET Action = 'Yedekleme tamamlandı'
WHERE Action LIKE '%tamamland%' AND Action LIKE '%Yedek%';

UPDATE BackupLogs 
SET Action = 'Geri yükleme başladı'
WHERE Action LIKE '%yǬkleme%' AND Action LIKE '%ba_Ylad%';

UPDATE BackupLogs 
SET Action = 'Geri yükleme tamamlandı'
WHERE Action LIKE '%yǬkleme%' AND Action LIKE '%tamamland%';

-- LocationName sütunundaki bozuk karakterleri düzelt
UPDATE BackupLogs 
SET LocationName = 'Mars İstanbul'
WHERE LocationName LIKE '%��stanbul%';

UPDATE BackupLogs 
SET LocationName = 'Mars İzmir'
WHERE LocationName LIKE '%��zmir%';

-- Düzeltilmiş verileri kontrol et
SELECT DISTINCT Action FROM BackupLogs WHERE LocationName LIKE 'Mars%';
SELECT DISTINCT LocationName FROM BackupLogs WHERE LocationName LIKE 'Mars%';

-- Son 5 kaydı kontrol et
SELECT TOP 5 
    FolderName,
    Action,
    LocationName,
    Timestamp
FROM BackupLogs 
WHERE LocationName LIKE 'Mars%'
ORDER BY Timestamp DESC;

PRINT 'Türkçe karakterler başarıyla düzeltildi!'

