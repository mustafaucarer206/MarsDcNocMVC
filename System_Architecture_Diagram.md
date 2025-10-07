# Sistem Mimarisi - Genel Bakış Diyagramı

```mermaid
graph TB
    subgraph "📡 Remote FTP Server"
        FTP[🌐 FTP Server<br/>REKLAM_DATA<br/>FRAGMAN_DATA]
    end
    
    subgraph "🖥️ Local System"
        subgraph "📁 Folder Structure"
            DCP[📂 DCP Online<br/>Ana giriş klasörü]
            WATCH[📂 WatchFolder<br/>Backup'a hazır dosyalar]
            LOCAL[📂 Local Temp<br/>İndirme geçici alanı]
            DEST[📂 Destination<br/>Final dosya konumu]
        end
        
        subgraph "🔧 PowerShell Scripts"
            TRACKER[📜 DcpOnlineFolderTracker.ps1<br/>🔍 Folder monitoring<br/>📊 Status management]
            BACKUP[📜 BackupScript.ps1<br/>⬇️ FTP download<br/>📦 File transfer]
            DISK[📜 DiskCapacityCheck.ps1<br/>💾 Space monitoring<br/>⚠️ Alerts]
        end
        
        subgraph "🗄️ Database"
            DB[(🗃️ SQL Server<br/>MarsDcNocMVC)]
            
            subgraph "📊 Tables"
                TRACKING[🔍 DcpOnlineFolderTracking<br/>Status: New→Stable→MovedToWatchFolder]
                LOGS[📝 BackupLogs<br/>Download history & status]
                CAPACITY[💾 DiskCapacityLogs<br/>Space monitoring data]
            end
        end
    end
    
    subgraph "🌐 Web Application"
        WEB[🖥️ ASP.NET Core MVC<br/>http://localhost:5032]
        
        subgraph "📄 Web Pages"
            HOME[🏠 Home Dashboard<br/>Transfer statistics]
            BACKUP_UI[📦 Backup Management<br/>Status monitoring]
            DISK_UI[💾 Disk Capacity<br/>Space monitoring]
            USER[👤 User Management<br/>Account settings]
        end
    end
    
    %% Data Flow Connections
    FTP -->|📥 Download| BACKUP
    BACKUP -->|💾 Store Local| LOCAL
    BACKUP -->|📦 Move to| DEST
    BACKUP -->|📝 Log| LOGS
    
    DCP -->|🔍 Monitor| TRACKER
    TRACKER -->|📊 Track Status| TRACKING
    TRACKER -->|📋 Check Processed| LOGS
    TRACKER -->|✅ Ready Files| WATCH
    
    DISK -->|💾 Monitor Space| CAPACITY
    DISK -->|📧 Send Alerts| EMAIL[📧 Email Notifications]
    
    WEB -->|📊 Read Data| DB
    HOME -->|📈 Display Stats| TRACKING
    BACKUP_UI -->|📋 Show Logs| LOGS
    DISK_UI -->|💾 Show Capacity| CAPACITY
    
    %% Status Flow
    TRACKING -->|New| TRACKER
    TRACKER -->|Stable Check| TRACKING
    TRACKING -->|MovedToWatchFolder| WATCH
    
    %% Backup Integration
    WATCH -->|🎯 Backup Ready| BACKUP_UI
    LOGS -->|📊 Statistics| HOME
    
    %% Styling
    style TRACKER fill:#e3f2fd,stroke:#1976d2
    style BACKUP fill:#f3e5f5,stroke:#7b1fa2
    style DISK fill:#e8f5e8,stroke:#388e3c
    style WEB fill:#fff3e0,stroke:#f57c00
    style DB fill:#fce4ec,stroke:#c2185b
    style FTP fill:#e0f2f1,stroke:#00796b
    
    style TRACKING fill:#e1f5fe,stroke:#0277bd
    style LOGS fill:#f3e5f5,stroke:#7b1fa2
    style CAPACITY fill:#e8f5e8,stroke:#2e7d32
</code_block_to_apply_changes_from> 