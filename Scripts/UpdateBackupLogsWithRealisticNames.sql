-- BackupLogs tablosunu gerçekçi DCP klasör isimleri ile güncelle ve her lokasyon için en az 5 örnek ekle

USE [MarsDcNocMVC]
GO

-- Önce mevcut BackupLogs verilerini temizle (sadece Mars lokasyonları için)
DELETE FROM BackupLogs WHERE LocationName LIKE 'Mars%';

-- Her lokasyon için gerçekçi DCP backup logları ekle
-- Format: [ID]-[TITLE]-[VERSION]_[FORMAT]_[LANGUAGE]_[RESOLUTION]_[DATE]_[DISTRIBUTOR]_[TYPE]

-- Mars Ankara için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Inception
('488-15954-DS-INCEPTION_ADV-1-2D_F_EN-TR_51_4K_20240315_MARS_OV', 'Yedekleme başladı', DATEADD(hour, -8, GETDATE()), 1, '02:45:30', '145.2 GB', 'Mars Ankara', '18.5 MB/s', '22.1 MB/s', '145.2 GB'),
('488-15954-DS-INCEPTION_ADV-1-2D_F_EN-TR_51_4K_20240315_MARS_OV', 'Yedekleme tamamlandı', DATEADD(hour, -6, GETDATE()), 1, '02:45:30', '145.2 GB', 'Mars Ankara', '18.5 MB/s', '22.1 MB/s', '145.2 GB'),

-- Film 2: The Dark Knight
('512-16789-DS-DARK_KNIGHT_TLR-2-3D_F_EN-TR_71_2K_20240420_WARNER_OV', 'Yedekleme başladı', DATEADD(hour, -12, GETDATE()), 1, '01:58:45', '98.7 GB', 'Mars Ankara', '16.2 MB/s', '19.8 MB/s', '98.7 GB'),
('512-16789-DS-DARK_KNIGHT_TLR-2-3D_F_EN-TR_71_2K_20240420_WARNER_OV', 'Yedekleme tamamlandı', DATEADD(hour, -10, GETDATE()), 1, '01:58:45', '98.7 GB', 'Mars Ankara', '16.2 MB/s', '19.8 MB/s', '98.7 GB'),

-- Film 3: Interstellar
('623-17234-DS-INTERSTELLAR_FTR-1-2D_F_EN-TR_51_4K_20240510_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -16, GETDATE()), 0, '00:45:12', '67.3 GB', 'Mars Ankara', '12.1 MB/s', '14.5 MB/s', '178.9 GB'),

-- Film 4: Matrix
('734-18567-DS-MATRIX_RELOADED_ADV-3-2D_F_EN-TR_51_4K_20240605_WARNER_OV', 'Yedekleme başladı', DATEADD(hour, -4, GETDATE()), 1, '02:12:18', '132.4 GB', 'Mars Ankara', '17.8 MB/s', '21.3 MB/s', '132.4 GB'),
('734-18567-DS-MATRIX_RELOADED_ADV-3-2D_F_EN-TR_51_4K_20240605_WARNER_OV', 'Yedekleme tamamlandı', DATEADD(hour, -2, GETDATE()), 1, '02:12:18', '132.4 GB', 'Mars Ankara', '17.8 MB/s', '21.3 MB/s', '132.4 GB'),

-- Film 5: Pulp Fiction
('845-19890-DS-PULP_FICTION_FTR-1-2D_F_EN-TR_51_2K_20240715_MIRAMAX_OV', 'Geri yükleme başladı', DATEADD(hour, -1, GETDATE()), 1, '01:45:33', '89.6 GB', 'Mars Ankara', '15.4 MB/s', '18.7 MB/s', '89.6 GB');

-- Mars İstanbul için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Avengers Endgame
('956-20123-DS-AVENGERS_ENDGAME_FTR-4-3D_F_EN-TR_71_4K_20240801_DISNEY_OV', 'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 1, '03:15:45', '198.7 GB', 'Mars İstanbul', '19.2 MB/s', '23.4 MB/s', '198.7 GB'),
('956-20123-DS-AVENGERS_ENDGAME_FTR-4-3D_F_EN-TR_71_4K_20240801_DISNEY_OV', 'Yedekleme tamamlandı', DATEADD(hour, -3, GETDATE()), 1, '03:15:45', '198.7 GB', 'Mars İstanbul', '19.2 MB/s', '23.4 MB/s', '198.7 GB'),

-- Film 2: Joker
('167-21456-DS-JOKER_FOLIE_DEUX_TLR-1-2D_F_EN-TR_51_2K_20240915_WARNER_OV', 'Yedekleme başladı', DATEADD(hour, -10, GETDATE()), 1, '02:28:12', '112.3 GB', 'Mars İstanbul', '16.8 MB/s', '20.1 MB/s', '112.3 GB'),
('167-21456-DS-JOKER_FOLIE_DEUX_TLR-1-2D_F_EN-TR_51_2K_20240915_WARNER_OV', 'Yedekleme tamamlandı', DATEADD(hour, -8, GETDATE()), 1, '02:28:12', '112.3 GB', 'Mars İstanbul', '16.8 MB/s', '20.1 MB/s', '112.3 GB'),

-- Film 3: Dune
('278-22789-DS-DUNE_PART_TWO_ADV-2-IMAX_F_EN-TR_71_4K_20241001_LEGENDARY_OV', 'Yedekleme başladı', DATEADD(hour, -14, GETDATE()), 1, '02:55:38', '167.9 GB', 'Mars İstanbul', '18.1 MB/s', '21.8 MB/s', '167.9 GB'),
('278-22789-DS-DUNE_PART_TWO_ADV-2-IMAX_F_EN-TR_71_4K_20241001_LEGENDARY_OV', 'Yedekleme tamamlandı', DATEADD(hour, -11, GETDATE()), 1, '02:55:38', '167.9 GB', 'Mars İstanbul', '18.1 MB/s', '21.8 MB/s', '167.9 GB'),

-- Film 4: Spider-Man
('389-23012-DS-SPIDER_MAN_NO_WAY_HOME_FTR-3-3D_F_EN-TR_71_4K_20241015_SONY_OV', 'Geri yükleme başladı', DATEADD(hour, -5, GETDATE()), 0, '01:12:45', '45.2 GB', 'Mars İstanbul', '11.3 MB/s', '13.7 MB/s', '134.8 GB'),

-- Film 5: Godfather
('490-24345-DS-GODFATHER_TRILOGY_FTR-1-2D_F_EN-TR_51_4K_20241020_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -2, GETDATE()), 1, '03:45:22', '223.1 GB', 'Mars İstanbul', '20.5 MB/s', '24.8 MB/s', '223.1 GB');

-- Mars İzmir için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Top Gun Maverick
('501-25678-DS-TOP_GUN_MAVERICK_ADV-1-IMAX_F_EN-TR_71_4K_20241105_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -9, GETDATE()), 1, '02:18:55', '142.6 GB', 'Mars İzmir', '17.9 MB/s', '21.5 MB/s', '142.6 GB'),
('501-25678-DS-TOP_GUN_MAVERICK_ADV-1-IMAX_F_EN-TR_71_4K_20241105_PARAMOUNT_OV', 'Yedekleme tamamlandı', DATEADD(hour, -7, GETDATE()), 1, '02:18:55', '142.6 GB', 'Mars İzmir', '17.9 MB/s', '21.5 MB/s', '142.6 GB'),

-- Film 2: Avatar
('612-26901-DS-AVATAR_WAY_OF_WATER_FTR-2-3D_F_EN-TR_71_4K_20241110_FOX_OV', 'Yedekleme başladı', DATEADD(hour, -13, GETDATE()), 1, '03:28:42', '201.4 GB', 'Mars İzmir', '19.8 MB/s', '23.9 MB/s', '201.4 GB'),
('612-26901-DS-AVATAR_WAY_OF_WATER_FTR-2-3D_F_EN-TR_71_4K_20241110_FOX_OV', 'Yedekleme tamamlandı', DATEADD(hour, -10, GETDATE()), 1, '03:28:42', '201.4 GB', 'Mars İzmir', '19.8 MB/s', '23.9 MB/s', '201.4 GB'),

-- Film 3: Black Panther
('723-27234-DS-BLACK_PANTHER_WAKANDA_TLR-1-2D_F_EN-TR_51_2K_20241115_DISNEY_OV', 'Geri yükleme başladı', DATEADD(hour, -17, GETDATE()), 1, '02:05:18', '95.7 GB', 'Mars İzmir', '15.8 MB/s', '19.1 MB/s', '95.7 GB'),
('723-27234-DS-BLACK_PANTHER_WAKANDA_TLR-1-2D_F_EN-TR_51_2K_20241115_DISNEY_OV', 'Geri yükleme tamamlandı', DATEADD(hour, -15, GETDATE()), 1, '02:05:18', '95.7 GB', 'Mars İzmir', '15.8 MB/s', '19.1 MB/s', '95.7 GB'),

-- Film 4: Titanic
('834-28567-DS-TITANIC_REMASTERED_FTR-1-3D_F_EN-TR_71_4K_20241120_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -3, GETDATE()), 0, '01:35:22', '78.9 GB', 'Mars İzmir', '13.2 MB/s', '15.9 MB/s', '189.3 GB'),

-- Film 5: Star Wars
('945-29890-DS-STAR_WARS_NEW_HOPE_ADV-4-2D_F_EN-TR_51_4K_20241125_DISNEY_OV', 'Yedekleme başladı', DATEADD(hour, -1, GETDATE()), 1, '02:42:15', '156.8 GB', 'Mars İzmir', '18.3 MB/s', '22.0 MB/s', '156.8 GB');

-- Mars Antalya için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: The Batman
('156-30123-DS-THE_BATMAN_RIDDLER_TLR-2-IMAX_F_EN-TR_71_4K_20241201_WARNER_OV', 'Yedekleme başladı', DATEADD(hour, -7, GETDATE()), 1, '02:58:33', '178.2 GB', 'Mars Antalya', '18.7 MB/s', '22.5 MB/s', '178.2 GB'),
('156-30123-DS-THE_BATMAN_RIDDLER_TLR-2-IMAX_F_EN-TR_71_4K_20241201_WARNER_OV', 'Yedekleme tamamlandı', DATEADD(hour, -4, GETDATE()), 1, '02:58:33', '178.2 GB', 'Mars Antalya', '18.7 MB/s', '22.5 MB/s', '178.2 GB'),

-- Film 2: Doctor Strange
('267-31456-DS-DOCTOR_STRANGE_MULTIVERSE_ADV-3-3D_F_EN-TR_71_4K_20241205_DISNEY_OV', 'Geri yükleme başladı', DATEADD(hour, -11, GETDATE()), 1, '02:26:48', '134.5 GB', 'Mars Antalya', '17.1 MB/s', '20.6 MB/s', '134.5 GB'),
('267-31456-DS-DOCTOR_STRANGE_MULTIVERSE_ADV-3-3D_F_EN-TR_71_4K_20241205_DISNEY_OV', 'Geri yükleme tamamlandı', DATEADD(hour, -9, GETDATE()), 1, '02:26:48', '134.5 GB', 'Mars Antalya', '17.1 MB/s', '20.6 MB/s', '134.5 GB'),

-- Film 3: Thor
('378-32789-DS-THOR_LOVE_THUNDER_FTR-4-2D_F_EN-TR_51_2K_20241210_DISNEY_OV', 'Yedekleme başladı', DATEADD(hour, -15, GETDATE()), 1, '02:15:12', '108.9 GB', 'Mars Antalya', '16.4 MB/s', '19.7 MB/s', '108.9 GB'),
('378-32789-DS-THOR_LOVE_THUNDER_FTR-4-2D_F_EN-TR_51_2K_20241210_DISNEY_OV', 'Yedekleme tamamlandı', DATEADD(hour, -13, GETDATE()), 1, '02:15:12', '108.9 GB', 'Mars Antalya', '16.4 MB/s', '19.7 MB/s', '108.9 GB'),

-- Film 4: Gladiator
('489-33012-DS-GLADIATOR_DIRECTORS_CUT_FTR-1-2D_F_EN-TR_51_4K_20241215_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 0, '01:28:35', '67.8 GB', 'Mars Antalya', '12.8 MB/s', '15.4 MB/s', '165.4 GB'),

-- Film 5: Blade Runner
('590-34345-DS-BLADE_RUNNER_2049_ADV-2-IMAX_F_EN-TR_71_4K_20241220_SONY_OV', 'Geri yükleme başladı', DATEADD(hour, -2, GETDATE()), 1, '02:44:28', '159.7 GB', 'Mars Antalya', '18.0 MB/s', '21.6 MB/s', '159.7 GB');

-- Mars Bursa için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Fast X
('601-35678-DS-FAST_X_FINAL_CHAPTER_TLR-5-3D_F_EN-TR_71_4K_20250101_UNIVERSAL_OV', 'Yedekleme başladı', DATEADD(hour, -8, GETDATE()), 1, '02:35:45', '147.3 GB', 'Mars Bursa', '17.6 MB/s', '21.1 MB/s', '147.3 GB'),
('601-35678-DS-FAST_X_FINAL_CHAPTER_TLR-5-3D_F_EN-TR_71_4K_20250101_UNIVERSAL_OV', 'Yedekleme tamamlandı', DATEADD(hour, -5, GETDATE()), 1, '02:35:45', '147.3 GB', 'Mars Bursa', '17.6 MB/s', '21.1 MB/s', '147.3 GB'),

-- Film 2: John Wick
('712-36901-DS-JOHN_WICK_CHAPTER_4_ADV-4-2D_F_EN-TR_51_4K_20250105_LIONSGATE_OV', 'Yedekleme başladı', DATEADD(hour, -12, GETDATE()), 1, '02:49:18', '162.8 GB', 'Mars Bursa', '18.2 MB/s', '21.9 MB/s', '162.8 GB'),
('712-36901-DS-JOHN_WICK_CHAPTER_4_ADV-4-2D_F_EN-TR_51_4K_20250105_LIONSGATE_OV', 'Yedekleme tamamlandı', DATEADD(hour, -9, GETDATE()), 1, '02:49:18', '162.8 GB', 'Mars Bursa', '18.2 MB/s', '21.9 MB/s', '162.8 GB'),

-- Film 3: Guardians
('823-37234-DS-GUARDIANS_GALAXY_VOL3_FTR-3-IMAX_F_EN-TR_71_4K_20250110_DISNEY_OV', 'Geri yükleme başladı', DATEADD(hour, -16, GETDATE()), 0, '01:45:33', '89.2 GB', 'Mars Bursa', '14.1 MB/s', '17.0 MB/s', '185.6 GB'),

-- Film 4: Lord of the Rings
('934-38567-DS-LOTR_FELLOWSHIP_EXTENDED_FTR-1-2D_F_EN-TR_51_4K_20250115_WARNER_OV', 'Yedekleme başladı', DATEADD(hour, -4, GETDATE()), 1, '03:58:42', '234.7 GB', 'Mars Bursa', '20.8 MB/s', '25.1 MB/s', '234.7 GB'),
('934-38567-DS-LOTR_FELLOWSHIP_EXTENDED_FTR-1-2D_F_EN-TR_51_4K_20250115_WARNER_OV', 'Yedekleme tamamlandı', DATEADD(hour, -1, GETDATE()), 1, '03:58:42', '234.7 GB', 'Mars Bursa', '20.8 MB/s', '25.1 MB/s', '234.7 GB'),

-- Film 5: Mad Max
('145-39890-DS-MAD_MAX_FURY_ROAD_BLACK_CHROME_ADV-1-2D_F_EN-TR_51_4K_20250120_WARNER_OV', 'Yedekleme başladı', DATEADD(minute, -45, GETDATE()), 1, '02:12:15', '128.4 GB', 'Mars Bursa', '17.3 MB/s', '20.8 MB/s', '128.4 GB');

-- Mars Konya için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Oppenheimer
('256-40123-DS-OPPENHEIMER_IMAX_70MM_FTR-1-2D_F_EN-TR_51_4K_20250125_UNIVERSAL_OV', 'Yedekleme başladı', DATEADD(hour, -10, GETDATE()), 1, '03:12:28', '189.6 GB', 'Mars Konya', '19.1 MB/s', '23.0 MB/s', '189.6 GB'),
('256-40123-DS-OPPENHEIMER_IMAX_70MM_FTR-1-2D_F_EN-TR_51_4K_20250125_UNIVERSAL_OV', 'Yedekleme tamamlandı', DATEADD(hour, -7, GETDATE()), 1, '03:12:28', '189.6 GB', 'Mars Konya', '19.1 MB/s', '23.0 MB/s', '189.6 GB'),

-- Film 2: Barbie
('367-41456-DS-BARBIE_PINK_EDITION_TLR-1-3D_F_EN-TR_71_2K_20250130_WARNER_OV', 'Geri yükleme başladı', DATEADD(hour, -14, GETDATE()), 1, '01:54:35', '87.3 GB', 'Mars Konya', '15.2 MB/s', '18.3 MB/s', '87.3 GB'),
('367-41456-DS-BARBIE_PINK_EDITION_TLR-1-3D_F_EN-TR_71_2K_20250130_WARNER_OV', 'Geri yükleme tamamlandı', DATEADD(hour, -12, GETDATE()), 1, '01:54:35', '87.3 GB', 'Mars Konya', '15.2 MB/s', '18.3 MB/s', '87.3 GB'),

-- Film 3: Casino Royale
('478-42789-DS-CASINO_ROYALE_REMASTERED_ADV-1-2D_F_EN-TR_51_4K_20250201_MGM_OV', 'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 1, '02:28:18', '142.1 GB', 'Mars Konya', '17.8 MB/s', '21.4 MB/s', '142.1 GB'),
('478-42789-DS-CASINO_ROYALE_REMASTERED_ADV-1-2D_F_EN-TR_51_4K_20250201_MGM_OV', 'Yedekleme tamamlandı', DATEADD(hour, -4, GETDATE()), 1, '02:28:18', '142.1 GB', 'Mars Konya', '17.8 MB/s', '21.4 MB/s', '142.1 GB'),

-- Film 4: Shawshank Redemption
('589-43012-DS-SHAWSHANK_REDEMPTION_25TH_FTR-1-2D_F_EN-TR_51_4K_20250205_COLUMBIA_OV', 'Yedekleme başladı', DATEADD(hour, -3, GETDATE()), 0, '01:18:45', '56.7 GB', 'Mars Konya', '11.8 MB/s', '14.2 MB/s', '156.9 GB'),

-- Film 5: Forrest Gump
('690-44345-DS-FORREST_GUMP_DIRECTORS_CUT_FTR-1-2D_F_EN-TR_51_2K_20250210_PARAMOUNT_OV', 'Geri yükleme başladı', DATEADD(hour, -1, GETDATE()), 1, '02:22:33', '109.8 GB', 'Mars Konya', '16.5 MB/s', '19.8 MB/s', '109.8 GB');

-- Mars Adana için backup logları
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Film 1: Mission Impossible
('701-45678-DS-MISSION_IMPOSSIBLE_DEAD_RECKONING_ADV-7-IMAX_F_EN-TR_71_4K_20250215_PARAMOUNT_OV', 'Yedekleme başladı', DATEADD(hour, -9, GETDATE()), 1, '02:43:52', '158.4 GB', 'Mars Adana', '18.1 MB/s', '21.7 MB/s', '158.4 GB'),
('701-45678-DS-MISSION_IMPOSSIBLE_DEAD_RECKONING_ADV-7-IMAX_F_EN-TR_71_4K_20250215_PARAMOUNT_OV', 'Yedekleme tamamlandı', DATEADD(hour, -6, GETDATE()), 1, '02:43:52', '158.4 GB', 'Mars Adana', '18.1 MB/s', '21.7 MB/s', '158.4 GB'),

-- Film 2: Indiana Jones
('812-46901-DS-INDIANA_JONES_DIAL_DESTINY_FTR-5-2D_F_EN-TR_51_4K_20250220_DISNEY_OV', 'Yedekleme başladı', DATEADD(hour, -13, GETDATE()), 1, '02:34:28', '149.7 GB', 'Mars Adana', '17.7 MB/s', '21.2 MB/s', '149.7 GB'),
('812-46901-DS-INDIANA_JONES_DIAL_DESTINY_FTR-5-2D_F_EN-TR_51_4K_20250220_DISNEY_OV', 'Yedekleme tamamlandı', DATEADD(hour, -11, GETDATE()), 1, '02:34:28', '149.7 GB', 'Mars Adana', '17.7 MB/s', '21.2 MB/s', '149.7 GB'),

-- Film 3: Transformers
('923-47234-DS-TRANSFORMERS_RISE_BEASTS_TLR-7-3D_F_EN-TR_71_2K_20250225_PARAMOUNT_OV', 'Geri yükleme başladı', DATEADD(hour, -17, GETDATE()), 0, '01:35:18', '78.4 GB', 'Mars Adana', '13.5 MB/s', '16.2 MB/s', '167.8 GB'),

-- Film 4: Aliens
('134-48567-DS-ALIENS_DIRECTORS_CUT_FTR-2-2D_F_EN-TR_51_4K_20250301_FOX_OV', 'Yedekleme başladı', DATEADD(hour, -5, GETDATE()), 1, '02:17:45', '132.6 GB', 'Mars Adana', '17.2 MB/s', '20.7 MB/s', '132.6 GB'),
('134-48567-DS-ALIENS_DIRECTORS_CUT_FTR-2-2D_F_EN-TR_51_4K_20250301_FOX_OV', 'Yedekleme tamamlandı', DATEADD(hour, -3, GETDATE()), 1, '02:17:45', '132.6 GB', 'Mars Adana', '17.2 MB/s', '20.7 MB/s', '132.6 GB'),

-- Film 5: Terminator 2
('245-49890-DS-TERMINATOR_2_JUDGMENT_DAY_ADV-2-3D_F_EN-TR_71_4K_20250305_STUDIOCANAL_OV', 'Yedekleme başladı', DATEADD(minute, -30, GETDATE()), 1, '02:29:12', '143.8 GB', 'Mars Adana', '17.9 MB/s', '21.5 MB/s', '143.8 GB');

-- Güncellenmiş verileri kontrol et
SELECT 
    LocationName,
    COUNT(*) as TotalLogs,
    COUNT(CASE WHEN Status = 1 THEN 1 END) as SuccessfulLogs,
    COUNT(CASE WHEN Status = 0 THEN 1 END) as FailedLogs,
    COUNT(DISTINCT SUBSTRING(FolderName, 1, CHARINDEX('_', FolderName + '_') - 1)) as UniqueMovies
FROM BackupLogs 
WHERE LocationName LIKE 'Mars%'
GROUP BY LocationName
ORDER BY LocationName;

-- Son eklenen logları göster
SELECT TOP 10
    FolderName,
    Action,
    LocationName,
    Status,
    FileSize,
    Timestamp
FROM BackupLogs 
WHERE LocationName LIKE 'Mars%'
ORDER BY Timestamp DESC;

PRINT 'BackupLogs tablosu gerçekçi DCP klasör isimleri ile güncellendi!'
PRINT 'Her lokasyon için en az 5 film backup log''u eklendi!'
PRINT 'Backup sayfası: http://localhost:5032/Backup'

