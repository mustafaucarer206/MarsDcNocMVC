-- DcpOnlineFolderTracking Tablosu Optimizasyon Scriptleri
-- Bu scriptler duplicate kayıtları önlemek ve performansı artırmak için kullanılır

-- 1. Duplicate kayıtları önlemek için unique constraint ekle
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DcpOnlineFolderTracking_FolderName_Unique')
BEGIN
    -- Önce mevcut duplicate kayıtları temizle
    WITH DuplicateEntries AS (
        SELECT ID, FolderName, FirstSeenDate,
               ROW_NUMBER() OVER (PARTITION BY FolderName ORDER BY FirstSeenDate DESC) as rn
        FROM DcpOnlineFolderTracking
        WHERE Status = 'MovedToWatchFolder' AND IsProcessed = 1
    )
    DELETE FROM DcpOnlineFolderTracking 
    WHERE ID IN (
        SELECT ID FROM DuplicateEntries WHERE rn > 1
    );
    
    -- Şimdi unique index ekle
    CREATE UNIQUE NONCLUSTERED INDEX IX_DcpOnlineFolderTracking_FolderName_Unique
    ON DcpOnlineFolderTracking(FolderName)
    WHERE IsProcessed = 1 AND Status = 'MovedToWatchFolder';
END;

-- 2. İşlenmiş kayıtlar için hızlı arama
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DcpOnlineFolderTracking_Status_IsProcessed')
BEGIN
    CREATE NONCLUSTERED INDEX IX_DcpOnlineFolderTracking_Status_IsProcessed
    ON DcpOnlineFolderTracking(Status, IsProcessed)
    INCLUDE (FolderName, FileSize, LastCheckDate);
END;

-- 3. Duplicate temizleme için stored procedure
IF OBJECT_ID('sp_CleanDuplicateFolderEntries', 'P') IS NOT NULL
    DROP PROCEDURE sp_CleanDuplicateFolderEntries;
GO

CREATE PROCEDURE sp_CleanDuplicateFolderEntries
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @DeletedRows INT = 0;
    
    -- Duplicate kayıtları sil (en son olanı koru)
    WITH DuplicateEntries AS (
        SELECT ID, FolderName, FirstSeenDate,
               ROW_NUMBER() OVER (PARTITION BY FolderName ORDER BY FirstSeenDate DESC) as rn
        FROM DcpOnlineFolderTracking
        WHERE Status = 'MovedToWatchFolder' AND IsProcessed = 1
    )
    DELETE FROM DcpOnlineFolderTracking 
    WHERE ID IN (
        SELECT ID FROM DuplicateEntries WHERE rn > 1
    );
    
    SET @DeletedRows = @@ROWCOUNT;
    
    PRINT CONCAT('Temizlenen duplicate kayit sayisi: ', @DeletedRows);
    
    RETURN @DeletedRows;
END;
GO

-- 4. Folder processing için optimized stored procedure
IF OBJECT_ID('sp_ProcessFolderSafely', 'P') IS NOT NULL
    DROP PROCEDURE sp_ProcessFolderSafely;
GO

CREATE PROCEDURE sp_ProcessFolderSafely
    @FolderName NVARCHAR(255),
    @FileSize BIGINT,
    @LocationName NVARCHAR(255),
    @Tolerance FLOAT = 1.0,
    @Action NVARCHAR(50) OUTPUT,
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ExistingSize BIGINT;
    DECLARE @IsProcessed BIT;
    DECLARE @Status NVARCHAR(50);
    DECLARE @SizeDifference FLOAT;
    
    BEGIN TRANSACTION;
    
    BEGIN TRY
        -- Lock ile kayıt kontrol et
        SELECT @ExistingSize = FileSize, 
               @IsProcessed = IsProcessed, 
               @Status = Status
        FROM DcpOnlineFolderTracking WITH (ROWLOCK, UPDLOCK)
        WHERE FolderName = @FolderName;
        
        -- Eğer kayıt yoksa yeni ekle
        IF @@ROWCOUNT = 0
        BEGIN
            INSERT INTO DcpOnlineFolderTracking 
            (FolderName, FirstSeenDate, LastCheckDate, FileSize, Status, IsProcessed, LocationName)
            VALUES 
            (@FolderName, GETDATE(), GETDATE(), @FileSize, 'New', 0, @LocationName);
            
            SET @Action = 'INSERTED';
            SET @Message = 'Yeni klasor eklendi';
        END
        ELSE
        BEGIN
            -- Eğer zaten işlenmiş ise atla
            IF @IsProcessed = 1 AND @Status = 'MovedToWatchFolder'
            BEGIN
                SET @Action = 'SKIP';
                SET @Message = 'Klasor zaten islenmis';
            END
            ELSE
            BEGIN
                -- Boyut kontrolü yap
                SET @SizeDifference = ABS(@ExistingSize - @FileSize);
                
                IF @SizeDifference <= @Tolerance
                BEGIN
                    -- Boyut aynı, işleme hazır
                    UPDATE DcpOnlineFolderTracking
                    SET LastCheckDate = GETDATE(),
                        Status = 'ReadyForProcessing',
                        LocationName = @LocationName
                    WHERE FolderName = @FolderName;
                    
                    SET @Action = 'READY';
                    SET @Message = 'Klasor islemeye hazir';
                END
                ELSE
                BEGIN
                    -- Boyut değişmiş
                    UPDATE DcpOnlineFolderTracking
                    SET FileSize = @FileSize,
                        LastCheckDate = GETDATE(),
                        Status = 'SizeChanged',
                        IsProcessed = 0,
                        LocationName = @LocationName
                    WHERE FolderName = @FolderName;
                    
                    SET @Action = 'SIZE_CHANGED';
                    SET @Message = CONCAT('Boyut degisti. Eski: ', @ExistingSize, ', Yeni: ', @FileSize);
                END
            END
        END
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        SET @Action = 'ERROR';
        SET @Message = ERROR_MESSAGE();
    END CATCH
END;
GO

-- 5. Monitoring için view
IF OBJECT_ID('vw_FolderTrackingStatus', 'V') IS NOT NULL
    DROP VIEW vw_FolderTrackingStatus;
GO

CREATE VIEW vw_FolderTrackingStatus
AS
SELECT 
    FolderName,
    LocationName,
    Status,
    IsProcessed,
    FileSize,
    FirstSeenDate,
    LastCheckDate,
    DATEDIFF(MINUTE, LastCheckDate, GETDATE()) as MinutesSinceLastCheck,
    CASE 
        WHEN IsProcessed = 1 AND Status = 'MovedToWatchFolder' THEN 'Completed'
        WHEN Status = 'SizeChanged' THEN 'Size Changing'
        WHEN Status = 'ReadyForProcessing' THEN 'Ready'
        WHEN Status = 'New' THEN 'New Folder'
        ELSE 'Unknown'
    END as StatusDescription
FROM DcpOnlineFolderTracking;
GO

PRINT 'DcpOnlineFolderTracking optimizasyon scriptleri basariyla calistirildi!'; 