-- BackupLogs tablosunu UTF-8 uyumlu verilerle yeniden oluştur

USE [MarsDcNocMVC]
GO

-- Mevcut Mars lokasyonlarındaki verileri temizle
DELETE FROM BackupLogs WHERE LocationName LIKE 'Mars%';

-- UTF-8 uyumlu verilerle yeniden ekle
INSERT INTO BackupLogs (FolderName, Action, Timestamp, Status, Duration, FileSize, LocationName, AverageSpeed, DownloadSpeed, TotalFileSize)
VALUES 
-- Mars Ankara
(N'488-15954-DS-INCEPTION_ADV-1-2D_F_EN-TR_51_4K_20240315_MARS_OV', N'Yedekleme başladı', DATEADD(hour, -8, GETDATE()), 1, N'02:45:30', N'145.2 GB', N'Mars Ankara', N'18.5 MB/s', N'22.1 MB/s', N'145.2 GB'),
(N'488-15954-DS-INCEPTION_ADV-1-2D_F_EN-TR_51_4K_20240315_MARS_OV', N'Yedekleme tamamlandı', DATEADD(hour, -6, GETDATE()), 1, N'02:45:30', N'145.2 GB', N'Mars Ankara', N'18.5 MB/s', N'22.1 MB/s', N'145.2 GB'),
(N'512-16789-DS-DARK_KNIGHT_TLR-2-3D_F_EN-TR_71_2K_20240420_WARNER_OV', N'Yedekleme başladı', DATEADD(hour, -12, GETDATE()), 1, N'01:58:45', N'98.7 GB', N'Mars Ankara', N'16.2 MB/s', N'19.8 MB/s', N'98.7 GB'),
(N'512-16789-DS-DARK_KNIGHT_TLR-2-3D_F_EN-TR_71_2K_20240420_WARNER_OV', N'Yedekleme tamamlandı', DATEADD(hour, -10, GETDATE()), 1, N'01:58:45', N'98.7 GB', N'Mars Ankara', N'16.2 MB/s', N'19.8 MB/s', N'98.7 GB'),
(N'623-17234-DS-INTERSTELLAR_FTR-1-2D_F_EN-TR_51_4K_20240510_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -16, GETDATE()), 0, N'00:45:12', N'67.3 GB', N'Mars Ankara', N'12.1 MB/s', N'14.5 MB/s', N'178.9 GB'),
(N'734-18567-DS-MATRIX_RELOADED_ADV-3-2D_F_EN-TR_51_4K_20240605_WARNER_OV', N'Yedekleme başladı', DATEADD(hour, -4, GETDATE()), 1, N'02:12:18', N'132.4 GB', N'Mars Ankara', N'17.8 MB/s', N'21.3 MB/s', N'132.4 GB'),
(N'734-18567-DS-MATRIX_RELOADED_ADV-3-2D_F_EN-TR_51_4K_20240605_WARNER_OV', N'Yedekleme tamamlandı', DATEADD(hour, -2, GETDATE()), 1, N'02:12:18', N'132.4 GB', N'Mars Ankara', N'17.8 MB/s', N'21.3 MB/s', N'132.4 GB'),
(N'845-19890-DS-PULP_FICTION_FTR-1-2D_F_EN-TR_51_2K_20240715_MIRAMAX_OV', N'Geri yükleme başladı', DATEADD(hour, -1, GETDATE()), 1, N'01:45:33', N'89.6 GB', N'Mars Ankara', N'15.4 MB/s', N'18.7 MB/s', N'89.6 GB'),

-- Mars İstanbul
(N'956-20123-DS-AVENGERS_ENDGAME_FTR-4-3D_F_EN-TR_71_4K_20240801_DISNEY_OV', N'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 1, N'03:15:45', N'198.7 GB', N'Mars İstanbul', N'19.2 MB/s', N'23.4 MB/s', N'198.7 GB'),
(N'956-20123-DS-AVENGERS_ENDGAME_FTR-4-3D_F_EN-TR_71_4K_20240801_DISNEY_OV', N'Yedekleme tamamlandı', DATEADD(hour, -3, GETDATE()), 1, N'03:15:45', N'198.7 GB', N'Mars İstanbul', N'19.2 MB/s', N'23.4 MB/s', N'198.7 GB'),
(N'167-21456-DS-JOKER_FOLIE_DEUX_TLR-1-2D_F_EN-TR_51_2K_20240915_WARNER_OV', N'Yedekleme başladı', DATEADD(hour, -10, GETDATE()), 1, N'02:28:12', N'112.3 GB', N'Mars İstanbul', N'16.8 MB/s', N'20.1 MB/s', N'112.3 GB'),
(N'167-21456-DS-JOKER_FOLIE_DEUX_TLR-1-2D_F_EN-TR_51_2K_20240915_WARNER_OV', N'Yedekleme tamamlandı', DATEADD(hour, -8, GETDATE()), 1, N'02:28:12', N'112.3 GB', N'Mars İstanbul', N'16.8 MB/s', N'20.1 MB/s', N'112.3 GB'),
(N'278-22789-DS-DUNE_PART_TWO_ADV-2-IMAX_F_EN-TR_71_4K_20241001_LEGENDARY_OV', N'Yedekleme başladı', DATEADD(hour, -14, GETDATE()), 1, N'02:55:38', N'167.9 GB', N'Mars İstanbul', N'18.1 MB/s', N'21.8 MB/s', N'167.9 GB'),
(N'278-22789-DS-DUNE_PART_TWO_ADV-2-IMAX_F_EN-TR_71_4K_20241001_LEGENDARY_OV', N'Yedekleme tamamlandı', DATEADD(hour, -11, GETDATE()), 1, N'02:55:38', N'167.9 GB', N'Mars İstanbul', N'18.1 MB/s', N'21.8 MB/s', N'167.9 GB'),
(N'389-23012-DS-SPIDER_MAN_NO_WAY_HOME_FTR-3-3D_F_EN-TR_71_4K_20241015_SONY_OV', N'Geri yükleme başladı', DATEADD(hour, -5, GETDATE()), 0, N'01:12:45', N'45.2 GB', N'Mars İstanbul', N'11.3 MB/s', N'13.7 MB/s', N'134.8 GB'),
(N'490-24345-DS-GODFATHER_TRILOGY_FTR-1-2D_F_EN-TR_51_4K_20241020_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -2, GETDATE()), 1, N'03:45:22', N'223.1 GB', N'Mars İstanbul', N'20.5 MB/s', N'24.8 MB/s', N'223.1 GB'),

-- Mars İzmir
(N'501-25678-DS-TOP_GUN_MAVERICK_ADV-1-IMAX_F_EN-TR_71_4K_20241105_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -9, GETDATE()), 1, N'02:18:55', N'142.6 GB', N'Mars İzmir', N'17.9 MB/s', N'21.5 MB/s', N'142.6 GB'),
(N'501-25678-DS-TOP_GUN_MAVERICK_ADV-1-IMAX_F_EN-TR_71_4K_20241105_PARAMOUNT_OV', N'Yedekleme tamamlandı', DATEADD(hour, -7, GETDATE()), 1, N'02:18:55', N'142.6 GB', N'Mars İzmir', N'17.9 MB/s', N'21.5 MB/s', N'142.6 GB'),
(N'612-26901-DS-AVATAR_WAY_OF_WATER_FTR-2-3D_F_EN-TR_71_4K_20241110_FOX_OV', N'Yedekleme başladı', DATEADD(hour, -13, GETDATE()), 1, N'03:28:42', N'201.4 GB', N'Mars İzmir', N'19.8 MB/s', N'23.9 MB/s', N'201.4 GB'),
(N'612-26901-DS-AVATAR_WAY_OF_WATER_FTR-2-3D_F_EN-TR_71_4K_20241110_FOX_OV', N'Yedekleme tamamlandı', DATEADD(hour, -10, GETDATE()), 1, N'03:28:42', N'201.4 GB', N'Mars İzmir', N'19.8 MB/s', N'23.9 MB/s', N'201.4 GB'),
(N'723-27234-DS-BLACK_PANTHER_WAKANDA_TLR-1-2D_F_EN-TR_51_2K_20241115_DISNEY_OV', N'Geri yükleme başladı', DATEADD(hour, -17, GETDATE()), 1, N'02:05:18', N'95.7 GB', N'Mars İzmir', N'15.8 MB/s', N'19.1 MB/s', N'95.7 GB'),
(N'723-27234-DS-BLACK_PANTHER_WAKANDA_TLR-1-2D_F_EN-TR_51_2K_20241115_DISNEY_OV', N'Geri yükleme tamamlandı', DATEADD(hour, -15, GETDATE()), 1, N'02:05:18', N'95.7 GB', N'Mars İzmir', N'15.8 MB/s', N'19.1 MB/s', N'95.7 GB'),
(N'834-28567-DS-TITANIC_REMASTERED_FTR-1-3D_F_EN-TR_71_4K_20241120_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -3, GETDATE()), 0, N'01:35:22', N'78.9 GB', N'Mars İzmir', N'13.2 MB/s', N'15.9 MB/s', N'189.3 GB'),
(N'945-29890-DS-STAR_WARS_NEW_HOPE_ADV-4-2D_F_EN-TR_51_4K_20241125_DISNEY_OV', N'Yedekleme başladı', DATEADD(hour, -1, GETDATE()), 1, N'02:42:15', N'156.8 GB', N'Mars İzmir', N'18.3 MB/s', N'22.0 MB/s', N'156.8 GB'),

-- Mars Antalya
(N'156-30123-DS-THE_BATMAN_RIDDLER_TLR-2-IMAX_F_EN-TR_71_4K_20241201_WARNER_OV', N'Yedekleme başladı', DATEADD(hour, -7, GETDATE()), 1, N'02:58:33', N'178.2 GB', N'Mars Antalya', N'18.7 MB/s', N'22.5 MB/s', N'178.2 GB'),
(N'156-30123-DS-THE_BATMAN_RIDDLER_TLR-2-IMAX_F_EN-TR_71_4K_20241201_WARNER_OV', N'Yedekleme tamamlandı', DATEADD(hour, -4, GETDATE()), 1, N'02:58:33', N'178.2 GB', N'Mars Antalya', N'18.7 MB/s', N'22.5 MB/s', N'178.2 GB'),
(N'267-31456-DS-DOCTOR_STRANGE_MULTIVERSE_ADV-3-3D_F_EN-TR_71_4K_20241205_DISNEY_OV', N'Geri yükleme başladı', DATEADD(hour, -11, GETDATE()), 1, N'02:26:48', N'134.5 GB', N'Mars Antalya', N'17.1 MB/s', N'20.6 MB/s', N'134.5 GB'),
(N'267-31456-DS-DOCTOR_STRANGE_MULTIVERSE_ADV-3-3D_F_EN-TR_71_4K_20241205_DISNEY_OV', N'Geri yükleme tamamlandı', DATEADD(hour, -9, GETDATE()), 1, N'02:26:48', N'134.5 GB', N'Mars Antalya', N'17.1 MB/s', N'20.6 MB/s', N'134.5 GB'),
(N'378-32789-DS-THOR_LOVE_THUNDER_FTR-4-2D_F_EN-TR_51_2K_20241210_DISNEY_OV', N'Yedekleme başladı', DATEADD(hour, -15, GETDATE()), 1, N'02:15:12', N'108.9 GB', N'Mars Antalya', N'16.4 MB/s', N'19.7 MB/s', N'108.9 GB'),
(N'378-32789-DS-THOR_LOVE_THUNDER_FTR-4-2D_F_EN-TR_51_2K_20241210_DISNEY_OV', N'Yedekleme tamamlandı', DATEADD(hour, -13, GETDATE()), 1, N'02:15:12', N'108.9 GB', N'Mars Antalya', N'16.4 MB/s', N'19.7 MB/s', N'108.9 GB'),
(N'489-33012-DS-GLADIATOR_DIRECTORS_CUT_FTR-1-2D_F_EN-TR_51_4K_20241215_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 0, N'01:28:35', N'67.8 GB', N'Mars Antalya', N'12.8 MB/s', N'15.4 MB/s', N'165.4 GB'),
(N'590-34345-DS-BLADE_RUNNER_2049_ADV-2-IMAX_F_EN-TR_71_4K_20241220_SONY_OV', N'Geri yükleme başladı', DATEADD(hour, -2, GETDATE()), 1, N'02:44:28', N'159.7 GB', N'Mars Antalya', N'18.0 MB/s', N'21.6 MB/s', N'159.7 GB'),

-- Mars Bursa
(N'601-35678-DS-FAST_X_FINAL_CHAPTER_TLR-5-3D_F_EN-TR_71_4K_20250101_UNIVERSAL_OV', N'Yedekleme başladı', DATEADD(hour, -8, GETDATE()), 1, N'02:35:45', N'147.3 GB', N'Mars Bursa', N'17.6 MB/s', N'21.1 MB/s', N'147.3 GB'),
(N'601-35678-DS-FAST_X_FINAL_CHAPTER_TLR-5-3D_F_EN-TR_71_4K_20250101_UNIVERSAL_OV', N'Yedekleme tamamlandı', DATEADD(hour, -5, GETDATE()), 1, N'02:35:45', N'147.3 GB', N'Mars Bursa', N'17.6 MB/s', N'21.1 MB/s', N'147.3 GB'),
(N'712-36901-DS-JOHN_WICK_CHAPTER_4_ADV-4-2D_F_EN-TR_51_4K_20250105_LIONSGATE_OV', N'Yedekleme başladı', DATEADD(hour, -12, GETDATE()), 1, N'02:49:18', N'162.8 GB', N'Mars Bursa', N'18.2 MB/s', N'21.9 MB/s', N'162.8 GB'),
(N'712-36901-DS-JOHN_WICK_CHAPTER_4_ADV-4-2D_F_EN-TR_51_4K_20250105_LIONSGATE_OV', N'Yedekleme tamamlandı', DATEADD(hour, -9, GETDATE()), 1, N'02:49:18', N'162.8 GB', N'Mars Bursa', N'18.2 MB/s', N'21.9 MB/s', N'162.8 GB'),
(N'823-37234-DS-GUARDIANS_GALAXY_VOL3_FTR-3-IMAX_F_EN-TR_71_4K_20250110_DISNEY_OV', N'Geri yükleme başladı', DATEADD(hour, -16, GETDATE()), 0, N'01:45:33', N'89.2 GB', N'Mars Bursa', N'14.1 MB/s', N'17.0 MB/s', N'185.6 GB'),
(N'934-38567-DS-LOTR_FELLOWSHIP_EXTENDED_FTR-1-2D_F_EN-TR_51_4K_20250115_WARNER_OV', N'Yedekleme başladı', DATEADD(hour, -4, GETDATE()), 1, N'03:58:42', N'234.7 GB', N'Mars Bursa', N'20.8 MB/s', N'25.1 MB/s', N'234.7 GB'),
(N'934-38567-DS-LOTR_FELLOWSHIP_EXTENDED_FTR-1-2D_F_EN-TR_51_4K_20250115_WARNER_OV', N'Yedekleme tamamlandı', DATEADD(hour, -1, GETDATE()), 1, N'03:58:42', N'234.7 GB', N'Mars Bursa', N'20.8 MB/s', N'25.1 MB/s', N'234.7 GB'),
(N'145-39890-DS-MAD_MAX_FURY_ROAD_BLACK_CHROME_ADV-1-2D_F_EN-TR_51_4K_20250120_WARNER_OV', N'Yedekleme başladı', DATEADD(minute, -45, GETDATE()), 1, N'02:12:15', N'128.4 GB', N'Mars Bursa', N'17.3 MB/s', N'20.8 MB/s', N'128.4 GB'),

-- Mars Konya
(N'256-40123-DS-OPPENHEIMER_IMAX_70MM_FTR-1-2D_F_EN-TR_51_4K_20250125_UNIVERSAL_OV', N'Yedekleme başladı', DATEADD(hour, -10, GETDATE()), 1, N'03:12:28', N'189.6 GB', N'Mars Konya', N'19.1 MB/s', N'23.0 MB/s', N'189.6 GB'),
(N'256-40123-DS-OPPENHEIMER_IMAX_70MM_FTR-1-2D_F_EN-TR_51_4K_20250125_UNIVERSAL_OV', N'Yedekleme tamamlandı', DATEADD(hour, -7, GETDATE()), 1, N'03:12:28', N'189.6 GB', N'Mars Konya', N'19.1 MB/s', N'23.0 MB/s', N'189.6 GB'),
(N'367-41456-DS-BARBIE_PINK_EDITION_TLR-1-3D_F_EN-TR_71_2K_20250130_WARNER_OV', N'Geri yükleme başladı', DATEADD(hour, -14, GETDATE()), 1, N'01:54:35', N'87.3 GB', N'Mars Konya', N'15.2 MB/s', N'18.3 MB/s', N'87.3 GB'),
(N'367-41456-DS-BARBIE_PINK_EDITION_TLR-1-3D_F_EN-TR_71_2K_20250130_WARNER_OV', N'Geri yükleme tamamlandı', DATEADD(hour, -12, GETDATE()), 1, N'01:54:35', N'87.3 GB', N'Mars Konya', N'15.2 MB/s', N'18.3 MB/s', N'87.3 GB'),
(N'478-42789-DS-CASINO_ROYALE_REMASTERED_ADV-1-2D_F_EN-TR_51_4K_20250201_MGM_OV', N'Yedekleme başladı', DATEADD(hour, -6, GETDATE()), 1, N'02:28:18', N'142.1 GB', N'Mars Konya', N'17.8 MB/s', N'21.4 MB/s', N'142.1 GB'),
(N'478-42789-DS-CASINO_ROYALE_REMASTERED_ADV-1-2D_F_EN-TR_51_4K_20250201_MGM_OV', N'Yedekleme tamamlandı', DATEADD(hour, -4, GETDATE()), 1, N'02:28:18', N'142.1 GB', N'Mars Konya', N'17.8 MB/s', N'21.4 MB/s', N'142.1 GB'),
(N'589-43012-DS-SHAWSHANK_REDEMPTION_25TH_FTR-1-2D_F_EN-TR_51_4K_20250205_COLUMBIA_OV', N'Yedekleme başladı', DATEADD(hour, -3, GETDATE()), 0, N'01:18:45', N'56.7 GB', N'Mars Konya', N'11.8 MB/s', N'14.2 MB/s', N'156.9 GB'),
(N'690-44345-DS-FORREST_GUMP_DIRECTORS_CUT_FTR-1-2D_F_EN-TR_51_2K_20250210_PARAMOUNT_OV', N'Geri yükleme başladı', DATEADD(hour, -1, GETDATE()), 1, N'02:22:33', N'109.8 GB', N'Mars Konya', N'16.5 MB/s', N'19.8 MB/s', N'109.8 GB'),

-- Mars Adana
(N'701-45678-DS-MISSION_IMPOSSIBLE_DEAD_RECKONING_ADV-7-IMAX_F_EN-TR_71_4K_20250215_PARAMOUNT_OV', N'Yedekleme başladı', DATEADD(hour, -9, GETDATE()), 1, N'02:43:52', N'158.4 GB', N'Mars Adana', N'18.1 MB/s', N'21.7 MB/s', N'158.4 GB'),
(N'701-45678-DS-MISSION_IMPOSSIBLE_DEAD_RECKONING_ADV-7-IMAX_F_EN-TR_71_4K_20250215_PARAMOUNT_OV', N'Yedekleme tamamlandı', DATEADD(hour, -6, GETDATE()), 1, N'02:43:52', N'158.4 GB', N'Mars Adana', N'18.1 MB/s', N'21.7 MB/s', N'158.4 GB'),
(N'812-46901-DS-INDIANA_JONES_DIAL_DESTINY_FTR-5-2D_F_EN-TR_51_4K_20250220_DISNEY_OV', N'Yedekleme başladı', DATEADD(hour, -13, GETDATE()), 1, N'02:34:28', N'149.7 GB', N'Mars Adana', N'17.7 MB/s', N'21.2 MB/s', N'149.7 GB'),
(N'812-46901-DS-INDIANA_JONES_DIAL_DESTINY_FTR-5-2D_F_EN-TR_51_4K_20250220_DISNEY_OV', N'Yedekleme tamamlandı', DATEADD(hour, -11, GETDATE()), 1, N'02:34:28', N'149.7 GB', N'Mars Adana', N'17.7 MB/s', N'21.2 MB/s', N'149.7 GB'),
(N'923-47234-DS-TRANSFORMERS_RISE_BEASTS_TLR-7-3D_F_EN-TR_71_2K_20250225_PARAMOUNT_OV', N'Geri yükleme başladı', DATEADD(hour, -17, GETDATE()), 0, N'01:35:18', N'78.4 GB', N'Mars Adana', N'13.5 MB/s', N'16.2 MB/s', N'167.8 GB'),
(N'134-48567-DS-ALIENS_DIRECTORS_CUT_FTR-2-2D_F_EN-TR_51_4K_20250301_FOX_OV', N'Yedekleme başladı', DATEADD(hour, -5, GETDATE()), 1, N'02:17:45', N'132.6 GB', N'Mars Adana', N'17.2 MB/s', N'20.7 MB/s', N'132.6 GB'),
(N'134-48567-DS-ALIENS_DIRECTORS_CUT_FTR-2-2D_F_EN-TR_51_4K_20250301_FOX_OV', N'Yedekleme tamamlandı', DATEADD(hour, -3, GETDATE()), 1, N'02:17:45', N'132.6 GB', N'Mars Adana', N'17.2 MB/s', N'20.7 MB/s', N'132.6 GB'),
(N'245-49890-DS-TERMINATOR_2_JUDGMENT_DAY_ADV-2-3D_F_EN-TR_71_4K_20250305_STUDIOCANAL_OV', N'Yedekleme başladı', DATEADD(minute, -30, GETDATE()), 1, N'02:29:12', N'143.8 GB', N'Mars Adana', N'17.9 MB/s', N'21.5 MB/s', N'143.8 GB');

-- Kontrol et
SELECT DISTINCT Action FROM BackupLogs WHERE LocationName LIKE N'Mars%';
SELECT DISTINCT LocationName FROM BackupLogs WHERE LocationName LIKE N'Mars%';

-- Son 5 kaydı kontrol et
SELECT TOP 5 
    FolderName,
    Action,
    LocationName,
    Timestamp
FROM BackupLogs 
WHERE LocationName LIKE N'Mars%'
ORDER BY Timestamp DESC;

PRINT N'UTF-8 uyumlu veriler başarıyla eklendi!'


