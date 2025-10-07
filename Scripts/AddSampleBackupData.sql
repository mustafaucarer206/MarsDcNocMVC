-- Backup ve DcpOnlineFolders sayfaları için örnek veri ekleme script'i
-- Mevcut lokasyonlardan rastgele seçim yaparak gerçekçi veriler oluşturur

-- MarsDcNocMVC veritabanını kullan
USE [MarsDcNocMVC]
GO

-- BackupLogs tablosuna örnek veriler ekle
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Mars Ankara verileri
('ANKARA_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -2, GETDATE()), 1, '00:15:30', '2.5 GB', 'Mars Ankara', '15.2 MB/s', '18.5 MB/s', '2.5 GB'),
('ANKARA_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -1, GETDATE()), 1, '00:15:30', '2.5 GB', 'Mars Ankara', '15.2 MB/s', '18.5 MB/s', '2.5 GB'),
('ANKARA_RESTORE_001', 'Geri yükleme başladı', DATEADD(hour, -3, GETDATE()), 1, '00:12:45', '1.8 GB', 'Mars Ankara', '12.8 MB/s', '14.2 MB/s', '1.8 GB'),
('ANKARA_RESTORE_001', 'Geri yükleme tamamlandı', DATEADD(hour, -2, GETDATE()), 1, '00:12:45', '1.8 GB', 'Mars Ankara', '12.8 MB/s', '14.2 MB/s', '1.8 GB'),

-- Mars İstanbul verileri
('ISTANBUL_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -4, GETDATE()), 1, '00:25:15', '4.2 GB', 'Mars İstanbul', '18.5 MB/s', '22.1 MB/s', '4.2 GB'),
('ISTANBUL_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -3, GETDATE()), 1, '00:25:15', '4.2 GB', 'Mars İstanbul', '18.5 MB/s', '22.1 MB/s', '4.2 GB'),
('ISTANBUL_BACKUP_002', 'Yedekleme başladı', DATEADD(minute, -30, GETDATE()), 0, '00:08:22', '1.1 GB', 'Mars İstanbul', '8.2 MB/s', '9.5 MB/s', '1.1 GB'),

-- Mars İzmir verileri
('IZMIR_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 1, '00:18:45', '3.1 GB', 'Mars İzmir', '16.8 MB/s', '19.2 MB/s', '3.1 GB'),
('IZMIR_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -5, GETDATE()), 1, '00:18:45', '3.1 GB', 'Mars İzmir', '16.8 MB/s', '19.2 MB/s', '3.1 GB'),
('IZMIR_RESTORE_001', 'Geri yükleme başladı', DATEADD(hour, -1, GETDATE()), 1, '00:14:20', '2.3 GB', 'Mars İzmir', '14.5 MB/s', '16.8 MB/s', '2.3 GB'),

-- Mars Antalya verileri
('ANTALYA_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -8, GETDATE()), 1, '00:22:10', '3.8 GB', 'Mars Antalya', '17.2 MB/s', '20.1 MB/s', '3.8 GB'),
('ANTALYA_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -7, GETDATE()), 1, '00:22:10', '3.8 GB', 'Mars Antalya', '17.2 MB/s', '20.1 MB/s', '3.8 GB'),

-- Mars Bursa verileri
('BURSA_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -12, GETDATE()), 1, '00:20:35', '3.5 GB', 'Mars Bursa', '16.1 MB/s', '18.9 MB/s', '3.5 GB'),
('BURSA_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -11, GETDATE()), 1, '00:20:35', '3.5 GB', 'Mars Bursa', '16.1 MB/s', '18.9 MB/s', '3.5 GB'),
('BURSA_RESTORE_001', 'Geri yükleme başladı', DATEADD(minute, -45, GETDATE()), 1, '00:16:25', '2.7 GB', 'Mars Bursa', '13.8 MB/s', '15.5 MB/s', '2.7 GB'),

-- Mars Konya verileri
('KONYA_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -5, GETDATE()), 0, '00:05:12', '0.8 GB', 'Mars Konya', '5.2 MB/s', '6.1 MB/s', '0.8 GB'),
('KONYA_RESTORE_001', 'Geri yükleme başladı', DATEADD(hour, -2, GETDATE()), 1, '00:11:30', '1.9 GB', 'Mars Konya', '11.2 MB/s', '12.8 MB/s', '1.9 GB'),

-- Mars Adana verileri
('ADANA_BACKUP_001', 'Yedekleme başladı', DATEADD(hour, -10, GETDATE()), 1, '00:19:15', '3.2 GB', 'Mars Adana', '15.8 MB/s', '18.2 MB/s', '3.2 GB'),
('ADANA_BACKUP_001', 'Yedekleme tamamlandı', DATEADD(hour, -9, GETDATE()), 1, '00:19:15', '3.2 GB', 'Mars Adana', '15.8 MB/s', '18.2 MB/s', '3.2 GB');

-- DcpOnlineFolderTracking tablosuna örnek veriler ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
-- Mars Ankara klasörleri
('ANKARA_DCP_FOLDER_001', DATEADD(day, -5, GETDATE()), DATEADD(hour, -1, GETDATE()), DATEADD(hour, -1, GETDATE()), 3, 2147483648, 'MovedToWatchFolder', 1, 'Mars Ankara'),
('ANKARA_DCP_FOLDER_002', DATEADD(day, -3, GETDATE()), DATEADD(minute, -30, GETDATE()), NULL, 0, 1073741824, 'New', 0, 'Mars Ankara'),
('ANKARA_DCP_FOLDER_003', DATEADD(day, -2, GETDATE()), DATEADD(hour, -2, GETDATE()), DATEADD(hour, -2, GETDATE()), 1, 3221225472, 'MovedToWatchFolder', 1, 'Mars Ankara'),

-- Mars İstanbul klasörleri
('ISTANBUL_DCP_FOLDER_001', DATEADD(day, -7, GETDATE()), DATEADD(hour, -3, GETDATE()), DATEADD(hour, -3, GETDATE()), 5, 4294967296, 'MovedToWatchFolder', 1, 'Mars İstanbul'),
('ISTANBUL_DCP_FOLDER_002', DATEADD(day, -4, GETDATE()), DATEADD(minute, -15, GETDATE()), NULL, 0, 1610612736, 'New', 0, 'Mars İstanbul'),
('ISTANBUL_DCP_FOLDER_003', DATEADD(day, -1, GETDATE()), DATEADD(hour, -4, GETDATE()), DATEADD(hour, -4, GETDATE()), 2, 2684354560, 'MovedToWatchFolder', 1, 'Mars İstanbul'),
('ISTANBUL_DCP_FOLDER_004', DATEADD(day, -6, GETDATE()), DATEADD(minute, -45, GETDATE()), NULL, 0, 536870912, 'New', 0, 'Mars İstanbul'),

-- Mars İzmir klasörleri
('IZMIR_DCP_FOLDER_001', DATEADD(day, -8, GETDATE()), DATEADD(hour, -5, GETDATE()), DATEADD(hour, -5, GETDATE()), 4, 3758096384, 'MovedToWatchFolder', 1, 'Mars İzmir'),
('IZMIR_DCP_FOLDER_002', DATEADD(day, -2, GETDATE()), DATEADD(minute, -20, GETDATE()), NULL, 0, 1342177280, 'New', 0, 'Mars İzmir'),
('IZMIR_DCP_FOLDER_003', DATEADD(day, -3, GETDATE()), DATEADD(hour, -1, GETDATE()), DATEADD(hour, -1, GETDATE()), 1, 2147483648, 'MovedToWatchFolder', 1, 'Mars İzmir'),

-- Mars Antalya klasörleri
('ANTALYA_DCP_FOLDER_001', DATEADD(day, -6, GETDATE()), DATEADD(hour, -7, GETDATE()), DATEADD(hour, -7, GETDATE()), 3, 3221225472, 'MovedToWatchFolder', 1, 'Mars Antalya'),
('ANTALYA_DCP_FOLDER_002', DATEADD(day, -1, GETDATE()), DATEADD(minute, -10, GETDATE()), NULL, 0, 805306368, 'New', 0, 'Mars Antalya'),
('ANTALYA_DCP_FOLDER_003', DATEADD(day, -4, GETDATE()), DATEADD(hour, -6, GETDATE()), DATEADD(hour, -6, GETDATE()), 2, 2684354560, 'MovedToWatchFolder', 1, 'Mars Antalya'),

-- Mars Bursa klasörleri
('BURSA_DCP_FOLDER_001', DATEADD(day, -9, GETDATE()), DATEADD(hour, -11, GETDATE()), DATEADD(hour, -11, GETDATE()), 6, 4831838208, 'MovedToWatchFolder', 1, 'Mars Bursa'),
('BURSA_DCP_FOLDER_002', DATEADD(day, -3, GETDATE()), DATEADD(minute, -25, GETDATE()), NULL, 0, 1073741824, 'New', 0, 'Mars Bursa'),
('BURSA_DCP_FOLDER_003', DATEADD(day, -1, GETDATE()), DATEADD(hour, -8, GETDATE()), DATEADD(hour, -8, GETDATE()), 1, 1610612736, 'MovedToWatchFolder', 1, 'Mars Bursa'),

-- Mars Konya klasörleri
('KONYA_DCP_FOLDER_001', DATEADD(day, -5, GETDATE()), DATEADD(hour, -2, GETDATE()), DATEADD(hour, -2, GETDATE()), 2, 2147483648, 'MovedToWatchFolder', 1, 'Mars Konya'),
('KONYA_DCP_FOLDER_002', DATEADD(day, -2, GETDATE()), DATEADD(minute, -35, GETDATE()), NULL, 0, 671088640, 'New', 0, 'Mars Konya'),

-- Mars Adana klasörleri
('ADANA_DCP_FOLDER_001', DATEADD(day, -7, GETDATE()), DATEADD(hour, -9, GETDATE()), DATEADD(hour, -9, GETDATE()), 4, 3758096384, 'MovedToWatchFolder', 1, 'Mars Adana'),
('ADANA_DCP_FOLDER_002', DATEADD(day, -4, GETDATE()), DATEADD(minute, -40, GETDATE()), NULL, 0, 1342177280, 'New', 0, 'Mars Adana'),
('ADANA_DCP_FOLDER_003', DATEADD(day, -1, GETDATE()), DATEADD(hour, -3, GETDATE()), DATEADD(hour, -3, GETDATE()), 1, 2684354560, 'MovedToWatchFolder', 1, 'Mars Adana');

-- Özet bilgi
SELECT 
    'BackupLogs' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT LocationName) as UniqueLocations
FROM BackupLogs
WHERE LocationName LIKE 'Mars%'

UNION ALL

SELECT 
    'DcpOnlineFolderTracking' as TableName,
    COUNT(*) as RecordCount,
    COUNT(DISTINCT LocationName) as UniqueLocations
FROM DcpOnlineFolderTracking
WHERE LocationName LIKE 'Mars%';

PRINT 'Örnek backup ve DCP folder tracking verileri başarıyla eklendi!'
PRINT 'Backup sayfası: http://localhost:5032/Backup'
PRINT 'DCP Online Folders sayfası: http://localhost:5032/Backup/DcpOnlineFolders'
