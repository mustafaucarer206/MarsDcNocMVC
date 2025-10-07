-- MarsDcNocMVC Veritabanı Oluşturma SQL Script'i
-- Bu script PowerShell dosyalarınız için gerekli veritabanını oluşturur

-- 1. Veritabanını oluştur (eğer yoksa)
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'MarsDcNocMVC')
BEGIN
    CREATE DATABASE [MarsDcNocMVC]
END
GO

USE [MarsDcNocMVC]
GO

-- 2. Locations Tablosu
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Locations' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Locations] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Name] nvarchar(450) NOT NULL,
        [Address] nvarchar(max) NULL,
        [PhoneNumber] nvarchar(max) NULL,
        CONSTRAINT [PK_Locations] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    
    -- Index oluştur
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Locations_Name] ON [dbo].[Locations]([Name] ASC)
    
    PRINT 'Locations tablosu oluşturuldu.'
END
ELSE
    PRINT 'Locations tablosu zaten mevcut.'
GO

-- 3. Users Tablosu
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Users' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id] int IDENTITY(1,1) NOT NULL,
        [Username] nvarchar(450) NOT NULL,
        [Password] nvarchar(max) NOT NULL,
        [Role] nvarchar(max) NOT NULL,
        [LocationName] nvarchar(max) NOT NULL,
        [PhoneNumber] nvarchar(max) NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC)
    )
    
    -- Index oluştur
    CREATE UNIQUE NONCLUSTERED INDEX [IX_Users_Username] ON [dbo].[Users]([Username] ASC)
    
    -- Varsayılan admin kullanıcısı ekle
    INSERT INTO [dbo].[Users] ([Username], [Password], [Role], [LocationName], [PhoneNumber])
    VALUES ('admin', 'Admin123!', 'Admin', 'Merkez', '5555555555')
    
    PRINT 'Users tablosu oluşturuldu ve admin kullanıcısı eklendi.'
END
ELSE
    PRINT 'Users tablosu zaten mevcut.'
GO

-- 4. BackupLogs Tablosu (PowerShell BackupScript.ps1 için)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='BackupLogs' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[BackupLogs] (
        [ID] int IDENTITY(1,1) NOT NULL,
        [FolderName] nvarchar(255) NOT NULL,
        [Action] nvarchar(255) NOT NULL,
        [Status] int NOT NULL,
        [Timestamp] datetime2(7) NOT NULL DEFAULT GETDATE(),
        [Duration] nvarchar(50) NULL,
        [FileSize] nvarchar(50) NULL,
        [TotalFileSize] nvarchar(50) NULL,
        [DownloadSpeed] nvarchar(50) NULL,
        [AverageSpeed] nvarchar(50) NULL,
        [LocationName] nvarchar(255) NULL,
        CONSTRAINT [PK_BackupLogs] PRIMARY KEY CLUSTERED ([ID] ASC)
    )
    
    -- Test verileri ekle
    INSERT INTO [dbo].[BackupLogs] ([FolderName], [Action], [Status], [Timestamp])
    VALUES 
    ('Cevahir', 'Yedekleme', 1, '2024-05-07 10:00:00'),
    ('Cevahir', 'Geri Yükleme', 1, '2024-05-07 11:00:00'),
    ('Hiltown', 'Yedekleme', 0, '2024-05-07 09:00:00'),
    ('Hiltown', 'Geri Yükleme', 1, '2024-05-07 08:00:00')
    
    PRINT 'BackupLogs tablosu oluşturuldu ve test verileri eklendi.'
END
ELSE
    PRINT 'BackupLogs tablosu zaten mevcut.'
GO

-- 5. DcpOnlineFolderTracking Tablosu (PowerShell DcpOnlineFolderTracker.ps1 için)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='DcpOnlineFolderTracking' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[DcpOnlineFolderTracking] (
        [ID] int IDENTITY(1,1) NOT NULL,
        [FolderName] nvarchar(255) NOT NULL,
        [FirstSeenDate] datetime2(7) NOT NULL DEFAULT GETDATE(),
        [LastCheckDate] datetime2(7) NOT NULL DEFAULT GETDATE(),
        [LastProcessedDate] datetime2(7) NULL,
        [FileSize] bigint NULL,
        [Status] nvarchar(50) NULL,
        [IsProcessed] bit NOT NULL DEFAULT 0,
        [ProcessCount] int NOT NULL DEFAULT 0,
        [LocationName] nvarchar(255) NULL,
        CONSTRAINT [PK_DcpOnlineFolderTracking] PRIMARY KEY CLUSTERED ([ID] ASC)
    )
    
    -- Index'ler oluştur
    CREATE NONCLUSTERED INDEX [IX_DcpOnlineFolderTracking_FolderName] ON [dbo].[DcpOnlineFolderTracking]([FolderName] ASC)
    CREATE NONCLUSTERED INDEX [IX_DcpOnlineFolderTracking_LastCheckDate] ON [dbo].[DcpOnlineFolderTracking]([LastCheckDate] ASC)
    
    PRINT 'DcpOnlineFolderTracking tablosu oluşturuldu.'
END
ELSE
    PRINT 'DcpOnlineFolderTracking tablosu zaten mevcut.'
GO

-- 6. ServerPingStatus Tablosu (PowerShell CheckServerStatus.ps1 için)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='ServerPingStatus' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[ServerPingStatus] (
        [ID] int IDENTITY(1,1) NOT NULL,
        [LocationName] nvarchar(100) NOT NULL,
        [ServerName] nvarchar(100) NOT NULL,
        [IPAddress] nvarchar(50) NOT NULL,
        [IsOnline] bit NOT NULL,
        [LastPingTime] datetime2(7) NOT NULL,
        [ResponseTime] int NULL,
        [ErrorMessage] nvarchar(500) NULL,
        CONSTRAINT [PK_ServerPingStatus] PRIMARY KEY CLUSTERED ([ID] ASC)
    )
    
    PRINT 'ServerPingStatus tablosu oluşturuldu.'
END
ELSE
    PRINT 'ServerPingStatus tablosu zaten mevcut.'
GO

-- 7. LocationLmsDiscCapacity Tablosu (PowerShell CheckDiskCapacity.ps1 için)
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='LocationLmsDiscCapacity' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[LocationLmsDiscCapacity] (
        [ID] int IDENTITY(1,1) NOT NULL,
        [LocationName] nvarchar(255) NOT NULL,
        [CheckDate] datetime2(7) NOT NULL,
        [TotalSpace] decimal(18,2) NOT NULL,
        [UsedSpace] decimal(18,2) NOT NULL,
        [FreeSpace] decimal(18,2) NOT NULL,
        CONSTRAINT [PK_LocationLmsDiscCapacity] PRIMARY KEY CLUSTERED ([ID] ASC)
    )
    
    PRINT 'LocationLmsDiscCapacity tablosu oluşturuldu.'
END
ELSE
    PRINT 'LocationLmsDiscCapacity tablosu zaten mevcut.'
GO

-- 8. Entity Framework Migration Tablosu
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='__EFMigrationsHistory' AND xtype='U')
BEGIN
    CREATE TABLE [dbo].[__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY CLUSTERED ([MigrationId] ASC)
    )
    
    -- Migration kayıtları ekle
    INSERT INTO [dbo].[__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES 
    ('20250506173722_InitialCreate', '8.0.8'),
    ('20250506175754_AddLocations', '8.0.8'),
    ('20250507022344_RemoveEmailFromLocation', '8.0.8'),
    ('20250507022825_RemoveDescriptionFromLocation', '8.0.8'),
    ('20250507023735_AddBackupLogs', '8.0.8'),
    ('20250507030043_CreateDatabase', '8.0.8'),
    ('20250507105551_UpdateDatabase', '8.0.8'),
    ('20250527220826_AddBackupLogAndDcpOnlineFolderTrackingColumns', '8.0.8'),
    ('20250528000858_AddLocationNameToDcpOnlineFolderTracking', '8.0.8'),
    ('20250602093212_AddAddressToUser', '8.0.8'),
    ('20250605190714_FixFileSizeDataType', '8.0.8')
    
    PRINT '__EFMigrationsHistory tablosu oluşturuldu ve migration kayıtları eklendi.'
END
ELSE
    PRINT '__EFMigrationsHistory tablosu zaten mevcut.'
GO

PRINT '========================================='
PRINT 'MarsDcNocMVC veritabanı başarıyla oluşturuldu!'
PRINT 'Oluşturulan tablolar:'
PRINT '- Locations (Lokasyon bilgileri)'
PRINT '- Users (Kullanıcı bilgileri)'
PRINT '- BackupLogs (BackupScript.ps1 logları)'
PRINT '- DcpOnlineFolderTracking (DcpOnlineFolderTracker.ps1 takip bilgileri)'
PRINT '- ServerPingStatus (CheckServerStatus.ps1 ping sonuçları)'
PRINT '- LocationLmsDiscCapacity (CheckDiskCapacity.ps1 disk bilgileri)'
PRINT '- __EFMigrationsHistory (Entity Framework migration geçmişi)'
PRINT '========================================='
PRINT 'PowerShell scriptleriniz artık bu veritabanını kullanabilir!'

-- Veritabanı bilgilerini göster
SELECT 
    'MarsDcNocMVC' as DatabaseName,
    COUNT(*) as TableCount
FROM INFORMATION_SCHEMA.TABLES 
WHERE TABLE_TYPE = 'BASE TABLE'

PRINT 'Connection String: Server=GMDCMUCARERNB;Database=MarsDcNocMVC;Trusted_Connection=True;TrustServerCertificate=True;' 