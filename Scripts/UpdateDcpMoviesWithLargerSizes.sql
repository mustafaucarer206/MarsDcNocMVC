-- DCP film dosya boyutlarını 100-250 GB arasında güncelle ve her lokasyon için en az 5 film ekle

USE [MarsDcNocMVC]
GO

-- Önce mevcut filmlerin dosya boyutlarını güncelle (100-250 GB arası, bytes cinsinden)
-- 100 GB = 107374182400 bytes, 250 GB = 268435456000 bytes

UPDATE DcpOnlineFolderTracking SET FileSize = 134217728000 WHERE FolderName = 'Inception_2010_4K_DCP'; -- 125 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 161061273600 WHERE FolderName = 'The_Dark_Knight_2008_2K_DCP'; -- 150 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 188743680000 WHERE FolderName = 'Interstellar_2014_4K_DCP'; -- 175 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 215526195200 WHERE FolderName = 'Avengers_Endgame_2019_4K_DCP'; -- 200 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 118111600640 WHERE FolderName = 'Joker_2019_2K_DCP'; -- 110 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 242308710400 WHERE FolderName = 'Dune_2021_4K_DCP'; -- 225 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 129127208960 WHERE FolderName = 'Spider_Man_No_Way_Home_2021_4K_DCP'; -- 120 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 172723712000 WHERE FolderName = 'Top_Gun_Maverick_2022_4K_DCP'; -- 160 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 258698037248 WHERE FolderName = 'Avatar_The_Way_of_Water_2022_4K_DCP'; -- 240 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 145525112832 WHERE FolderName = 'Black_Panther_2018_2K_DCP'; -- 135 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 199148953600 WHERE FolderName = 'The_Batman_2022_4K_DCP'; -- 185 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 112742891520 WHERE FolderName = 'Doctor_Strange_Multiverse_2022_4K_DCP'; -- 105 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 167503724544 WHERE FolderName = 'Thor_Love_and_Thunder_2022_2K_DCP'; -- 155 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 236223201280 WHERE FolderName = 'Fast_X_2023_4K_DCP'; -- 220 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 123145314304 WHERE FolderName = 'John_Wick_Chapter_4_2023_4K_DCP'; -- 115 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 151473725440 WHERE FolderName = 'Guardians_of_Galaxy_Vol3_2023_2K_DCP'; -- 140 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 268435456000 WHERE FolderName = 'Oppenheimer_2023_4K_DCP'; -- 250 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 107374182400 WHERE FolderName = 'Barbie_2023_2K_DCP'; -- 100 GB

UPDATE DcpOnlineFolderTracking SET FileSize = 204010946560 WHERE FolderName = 'Mission_Impossible_Dead_Reckoning_2023_4K_DCP'; -- 190 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 140737488355 WHERE FolderName = 'Indiana_Jones_Dial_of_Destiny_2023_4K_DCP'; -- 131 GB
UPDATE DcpOnlineFolderTracking SET FileSize = 177917001728 WHERE FolderName = 'Transformers_Rise_of_Beasts_2023_2K_DCP'; -- 165 GB

-- Her lokasyon için eksik filmleri ekle (en az 5 film olacak şekilde)

-- Mars Ankara için 2 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('The_Matrix_1999_4K_DCP', DATEADD(day, -6, GETDATE()), DATEADD(hour, -3, GETDATE()), DATEADD(hour, -3, GETDATE()), 2, 156237394944, 'MovedToWatchFolder', 1, 'Mars Ankara'), -- 145 GB
('Pulp_Fiction_1994_2K_DCP', DATEADD(day, -4, GETDATE()), DATEADD(minute, -45, GETDATE()), NULL, 0, 183439900672, 'New', 0, 'Mars Ankara'); -- 170 GB

-- Mars İstanbul için 1 film daha ekle (4 -> 5)
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('The_Godfather_1972_4K_DCP', DATEADD(day, -8, GETDATE()), DATEADD(hour, -6, GETDATE()), DATEADD(hour, -6, GETDATE()), 3, 209715200000, 'MovedToWatchFolder', 1, 'Mars İstanbul'); -- 195 GB

-- Mars İzmir için 2 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('Titanic_1997_4K_DCP', DATEADD(day, -9, GETDATE()), DATEADD(hour, -8, GETDATE()), DATEADD(hour, -8, GETDATE()), 4, 247463133184, 'MovedToWatchFolder', 1, 'Mars İzmir'), -- 230 GB
('Star_Wars_A_New_Hope_1977_4K_DCP', DATEADD(day, -3, GETDATE()), DATEADD(minute, -20, GETDATE()), NULL, 0, 126100111360, 'New', 0, 'Mars İzmir'); -- 117 GB

-- Mars Antalya için 2 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('Gladiator_2000_4K_DCP', DATEADD(day, -7, GETDATE()), DATEADD(hour, -4, GETDATE()), DATEADD(hour, -4, GETDATE()), 2, 193273528320, 'MovedToWatchFolder', 1, 'Mars Antalya'), -- 180 GB
('Blade_Runner_2049_2017_4K_DCP', DATEADD(day, -2, GETDATE()), DATEADD(minute, -15, GETDATE()), NULL, 0, 134217728000, 'New', 0, 'Mars Antalya'); -- 125 GB

-- Mars Bursa için 2 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('The_Lord_of_Rings_Fellowship_2001_4K_DCP', DATEADD(day, -10, GETDATE()), DATEADD(hour, -12, GETDATE()), DATEADD(hour, -12, GETDATE()), 5, 262144000000, 'MovedToWatchFolder', 1, 'Mars Bursa'), -- 244 GB
('Mad_Max_Fury_Road_2015_4K_DCP', DATEADD(day, -1, GETDATE()), DATEADD(minute, -30, GETDATE()), NULL, 0, 115292150374, 'New', 0, 'Mars Bursa'); -- 107 GB

-- Mars Konya için 3 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('Casino_Royale_2006_4K_DCP', DATEADD(day, -6, GETDATE()), DATEADD(hour, -5, GETDATE()), DATEADD(hour, -5, GETDATE()), 3, 171798691840, 'MovedToWatchFolder', 1, 'Mars Konya'), -- 160 GB
('The_Shawshank_Redemption_1994_4K_DCP', DATEADD(day, -4, GETDATE()), DATEADD(minute, -50, GETDATE()), NULL, 0, 198863872000, 'New', 0, 'Mars Konya'), -- 185 GB
('Forrest_Gump_1994_2K_DCP', DATEADD(day, -8, GETDATE()), DATEADD(hour, -7, GETDATE()), DATEADD(hour, -7, GETDATE()), 1, 139586437120, 'MovedToWatchFolder', 1, 'Mars Konya'); -- 130 GB

-- Mars Adana için 2 film daha ekle
INSERT INTO DcpOnlineFolderTracking (FolderName, FirstSeenDate, LastCheckDate, LastProcessedDate, ProcessCount, FileSize, Status, IsProcessed, LocationName)
VALUES 
('Aliens_1986_4K_DCP', DATEADD(day, -5, GETDATE()), DATEADD(hour, -2, GETDATE()), DATEADD(hour, -2, GETDATE()), 2, 225485783040, 'MovedToWatchFolder', 1, 'Mars Adana'), -- 210 GB
('Terminator_2_1991_4K_DCP', DATEADD(day, -3, GETDATE()), DATEADD(minute, -25, GETDATE()), NULL, 0, 148618067968, 'New', 0, 'Mars Adana'); -- 138 GB

-- Güncellenmiş verileri kontrol et
SELECT 
    LocationName,
    FolderName,
    Status,
    CAST(FileSize/1073741824.0 AS DECIMAL(10,1)) as FileSizeGB,
    LastCheckDate
FROM DcpOnlineFolderTracking 
WHERE LocationName LIKE 'Mars%'
ORDER BY LocationName, LastCheckDate DESC;

-- Her lokasyon için özet
SELECT 
    LocationName,
    COUNT(*) as TotalMovies,
    COUNT(CASE WHEN Status = 'New' THEN 1 END) as NewMovies,
    COUNT(CASE WHEN Status = 'MovedToWatchFolder' THEN 1 END) as ProcessedMovies,
    CAST(AVG(FileSize/1073741824.0) AS DECIMAL(10,1)) as AvgFileSizeGB,
    CAST(MIN(FileSize/1073741824.0) AS DECIMAL(10,1)) as MinFileSizeGB,
    CAST(MAX(FileSize/1073741824.0) AS DECIMAL(10,1)) as MaxFileSizeGB
FROM DcpOnlineFolderTracking 
WHERE LocationName LIKE 'Mars%'
GROUP BY LocationName
ORDER BY LocationName;

PRINT 'DCP film dosya boyutları 100-250 GB arasında güncellendi!'
PRINT 'Her lokasyon için en az 5 film eklendi!'
PRINT 'DCP Online Folders sayfası: http://localhost:5032/Backup/DcpOnlineFolders'


