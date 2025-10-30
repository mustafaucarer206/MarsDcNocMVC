-- Gereksiz PostgreSQL tablolarini sil ve sadece gerekli yapiyi olustur
USE [MarsDcNocMVC];
GO

PRINT '=== GEREKSIZ TABLOLARI SILME ===';
PRINT '';

-- Gereksiz tablolari listele ve sil
DECLARE @tableName NVARCHAR(255);
DECLARE @sql NVARCHAR(MAX);

DECLARE tableCursor CURSOR FOR
SELECT name FROM sys.tables 
WHERE name IN (
    'address', 'alembic_version', 'asset', 'assetcplmap', 
    'automation_configuration', 'automation_flag', 'automation_flag_map',
    'avatar', 'bookend_setting', 'contact', 'content_operation_log',
    'cue_pack', 'delay_delete_cpl', 'external_device_map',
    'external_show_attribute_map', 'external_show_attribute_show_attribute_map',
    'external_title_map', 'generated_playlist', 'ieb_channel_device_type',
    'ieb_process', 'ieb_process_detail_history', 'ieb_process_item',
    'ieb_process_pattern', 'ieb_process_record', 'ieb_status_type',
    'kdm', 'license', 'live_log', 'log', 'log_file', 'log_file_playout',
    'macro_pack', 'macro_placeholder', 'message_whitelist',
    'monitoring_oid', 'monitoring_type', 'pack', 'pack_attribute_map',
    'pack_cpl_map', 'pack_rating_map', 'pack_screen_map',
    'permission', 'permission_group', 'placeholder', 'playback',
    'playback_cancel_report', 'playback_monitoring_report',
    'pos', 'pos_show_attribute_map', 'probe_calibration',
    'probe_configuration', 'probe_device_details', 'probe_measurement',
    'probe_timeframe', 'quick_cue', 'quick_cue_map', 'remind_message',
    'schedule_delay_validate_push', 'schedule_deleted_history',
    'schedule_history_log', 'schedule_overlap_relation',
    'schedule_playback_log', 'schedule_show_attribute_map',
    'schedule_validation_log', 'screen_show_attribute_map',
    'script', 'show_attribute', 'spl_mappings', 'template',
    'template_screen_map', 'template_show_attribute_map',
    'timeframe', 'timeframe_map', 'title_rating_map',
    'transfer', 'transfer_history_log', 'trim_drop_log',
    'user_permission_map', 'user_tab_map', 'user_type',
    'playlist', 'playlist_cpl_map', 'schedule',
    'title', 'title_cpl_map', 'device_cpl_map',
    'cpl_custom_parameters', 'cpl_sync_transfer_date', 'cpl_validation',
    'device_custom_parameters', 'device_daylight_saving', 'device_specification'
);

OPEN tableCursor;
FETCH NEXT FROM tableCursor INTO @tableName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'DROP TABLE IF EXISTS dbo.' + QUOTENAME(@tableName);
    PRINT 'Siliniyor: ' + @tableName;
    EXEC sp_executesql @sql;
    FETCH NEXT FROM tableCursor INTO @tableName;
END;

CLOSE tableCursor;
DEALLOCATE tableCursor;

PRINT '';
PRINT '=== YENİ YAPI OLUSTURULUYOR ===';
PRINT '';

-- Eski tabloları temizle (varsa)
DROP TABLE IF EXISTS dbo.Movies;
DROP TABLE IF EXISTS dbo.cpl;
DROP TABLE IF EXISTS dbo.device;
DROP TABLE IF EXISTS dbo.screen;

-- MOVIES tablosu - Sadece ihtiyac duyulan bilgiler
CREATE TABLE dbo.Movies (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FilmAdi NVARCHAR(500) NOT NULL,
    Sure_Dakika DECIMAL(10,2),
    Boyut_GB DECIMAL(10,2),
    Cozunurluk NVARCHAR(50),
    Siniflandirma NVARCHAR(50),
    Lokasyon NVARCHAR(100) DEFAULT 'Cevahir',
    CihazAdi NVARCHAR(200),
    SalonAdi NVARCHAR(200),
    Sifreli BIT,
    SesDili NVARCHAR(50),
    AltyaziDili NVARCHAR(50),
    EklenmeTarihi DATETIME2 DEFAULT GETDATE(),
    
    -- Ek Bilgiler
    EnBoyOrani NVARCHAR(20),
    FrameRate NVARCHAR(20),
    IcerikTuru NVARCHAR(50),
    
    -- Index'ler
    INDEX IX_Movies_FilmAdi (FilmAdi),
    INDEX IX_Movies_Lokasyon (Lokasyon),
    INDEX IX_Movies_CihazAdi (CihazAdi),
    INDEX IX_Movies_SalonAdi (SalonAdi)
);

PRINT 'Movies tablosu olusturuldu';
PRINT '';

-- Ornek veri ekle (PostgreSQL'den alinacak)
PRINT '=== ORNEK VERI EKLENIYOR ===';
PRINT 'Not: PostgreSQL''den gercek veri alinacak';
PRINT '';

-- Tablonun yapisini goster
PRINT '=== MOVIES TABLOSU YAPISI ===';
EXEC sp_help 'dbo.Movies';

PRINT '';
PRINT '=== KULLANIM ORNEKLERI ===';
PRINT '';
PRINT '-- Tum filmleri gormek:';
PRINT '  SELECT * FROM Movies ORDER BY FilmAdi;';
PRINT '';
PRINT '-- Belirli bir salondaki filmleri gormek:';
PRINT '  SELECT FilmAdi, Sure_Dakika, SalonAdi FROM Movies WHERE SalonAdi = ''Salon 1'';';
PRINT '';
PRINT '-- Cevahir lokasyonundaki filmleri gormek:';
PRINT '  SELECT * FROM Movies WHERE Lokasyon = ''Cevahir'';';
PRINT '';
PRINT '-- 4K filmleri gormek:';
PRINT '  SELECT FilmAdi, Cozunurluk, Boyut_GB FROM Movies WHERE Cozunurluk LIKE ''%4096%'';';

GO

-- Kalan tablolari listele
PRINT '';
PRINT '=== KALAN TABLOLAR ===';
SELECT name AS TabloAdi FROM sys.tables ORDER BY name;
GO
