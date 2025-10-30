-- DcpOnlineFolderTracking tablosundaki klasör adlarını film isimleri ile güncelleme script'i

USE [MarsDcNocMVC]
GO

-- Mevcut klasör adlarını film isimleri ile güncelle
UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Inception_2010_4K_DCP'
WHERE FolderName = 'ANKARA_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'The_Dark_Knight_2008_2K_DCP'
WHERE FolderName = 'ANKARA_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Interstellar_2014_4K_DCP'
WHERE FolderName = 'ANKARA_DCP_FOLDER_003';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Avengers_Endgame_2019_4K_DCP'
WHERE FolderName = 'ISTANBUL_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Joker_2019_2K_DCP'
WHERE FolderName = 'ISTANBUL_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Dune_2021_4K_DCP'
WHERE FolderName = 'ISTANBUL_DCP_FOLDER_003';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Spider_Man_No_Way_Home_2021_4K_DCP'
WHERE FolderName = 'ISTANBUL_DCP_FOLDER_004';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Top_Gun_Maverick_2022_4K_DCP'
WHERE FolderName = 'IZMIR_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Avatar_The_Way_of_Water_2022_4K_DCP'
WHERE FolderName = 'IZMIR_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Black_Panther_2018_2K_DCP'
WHERE FolderName = 'IZMIR_DCP_FOLDER_003';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'The_Batman_2022_4K_DCP'
WHERE FolderName = 'ANTALYA_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Doctor_Strange_Multiverse_2022_4K_DCP'
WHERE FolderName = 'ANTALYA_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Thor_Love_and_Thunder_2022_2K_DCP'
WHERE FolderName = 'ANTALYA_DCP_FOLDER_003';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Fast_X_2023_4K_DCP'
WHERE FolderName = 'BURSA_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'John_Wick_Chapter_4_2023_4K_DCP'
WHERE FolderName = 'BURSA_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Guardians_of_Galaxy_Vol3_2023_2K_DCP'
WHERE FolderName = 'BURSA_DCP_FOLDER_003';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Oppenheimer_2023_4K_DCP'
WHERE FolderName = 'KONYA_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Barbie_2023_2K_DCP'
WHERE FolderName = 'KONYA_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Mission_Impossible_Dead_Reckoning_2023_4K_DCP'
WHERE FolderName = 'ADANA_DCP_FOLDER_001';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Indiana_Jones_Dial_of_Destiny_2023_4K_DCP'
WHERE FolderName = 'ADANA_DCP_FOLDER_002';

UPDATE DcpOnlineFolderTracking 
SET FolderName = 'Transformers_Rise_of_Beasts_2023_2K_DCP'
WHERE FolderName = 'ADANA_DCP_FOLDER_003';

-- Güncellenmiş verileri kontrol et
SELECT 
    FolderName,
    Status,
    LocationName,
    LastCheckDate,
    CASE 
        WHEN FileSize > 4000000000 THEN CAST(FileSize/1073741824.0 AS DECIMAL(10,2))
        ELSE CAST(FileSize/1073741824.0 AS DECIMAL(10,2))
    END as FileSizeGB
FROM DcpOnlineFolderTracking 
ORDER BY LocationName, LastCheckDate DESC;

-- Özet bilgi
SELECT 
    LocationName,
    COUNT(*) as MovieCount,
    COUNT(CASE WHEN Status = 'New' THEN 1 END) as NewMovies,
    COUNT(CASE WHEN Status = 'MovedToWatchFolder' THEN 1 END) as ProcessedMovies
FROM DcpOnlineFolderTracking 
GROUP BY LocationName
ORDER BY LocationName;

PRINT 'DCP klasör adları film isimleri ile başarıyla güncellendi!'
PRINT 'DCP Online Folders sayfası: http://localhost:5032/Backup/DcpOnlineFolders'


