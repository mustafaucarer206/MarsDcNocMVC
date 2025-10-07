using Microsoft.EntityFrameworkCore;
using MarsDcNocMVC.Models;

namespace MarsDcNocMVC.Data
{
    public class ApplicationDbContext : DbContext
    {
        public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
            : base(options)
        {
        }

        public DbSet<BackupLog> BackupLogs { get; set; }
        public DbSet<DcpOnlineFolderTracking> DcpOnlineFolderTracking { get; set; }
        public DbSet<User> Users { get; set; }
        public DbSet<Location> Locations { get; set; }
        public DbSet<LocationLmsDiscCapacity> LocationLmsDiscCapacity { get; set; }
        public DbSet<ServerPingStatus> ServerPingStatus { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            // BackupLog yapılandırması
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.Timestamp)
                .HasDefaultValueSql("GETDATE()");
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.FolderName)
                .HasMaxLength(255);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.Action)
                .HasMaxLength(255);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.LocationName)
                .HasMaxLength(255);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.Duration)
                .HasMaxLength(50);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.FileSize);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.AverageSpeed)
                .HasMaxLength(50);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.DownloadSpeed)
                .HasMaxLength(50);
            modelBuilder.Entity<BackupLog>()
                .Property(b => b.TotalFileSize)
                .HasMaxLength(50);

            // DcpOnlineFolderTracking yapılandırması
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .ToTable("DcpOnlineFolderTracking")
                .Property(d => d.FolderName)
                .HasMaxLength(255);
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .Property(d => d.Status)
                .HasMaxLength(50);
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .Property(d => d.FirstSeenDate)
                .HasDefaultValueSql("GETDATE()");
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .Property(d => d.LastCheckDate)
                .HasDefaultValueSql("GETDATE()");
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .Property(d => d.IsProcessed)
                .HasDefaultValue(false);
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .Property(d => d.FileSize);
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .HasIndex(d => d.FolderName);
            modelBuilder.Entity<DcpOnlineFolderTracking>()
                .HasIndex(d => d.LastCheckDate);

            // User yapılandırması
            modelBuilder.Entity<User>()
                .HasIndex(u => u.Username)
                .IsUnique();

            // Location yapılandırması
            modelBuilder.Entity<Location>()
                .HasIndex(l => l.Name)
                .IsUnique();

            // Seed default admin user
            modelBuilder.Entity<User>().HasData(
                new User
                {
                    Id = 1,
                    Username = "admin",
                    Password = "Admin123!", // In production, this should be hashed
                    Role = "Admin",
                    LocationName = "Merkez",
                    PhoneNumber = "5555555555"
                }
            );

            // Seed sample backup logs
            modelBuilder.Entity<BackupLog>().HasData(
                new BackupLog
                {
                    ID = 1,
                    FolderName = "Cevahir",
                    Action = "Yedekleme",
                    Timestamp = new DateTime(2024, 5, 7, 10, 0, 0),
                    Status = 1
                },
                new BackupLog
                {
                    ID = 2,
                    FolderName = "Cevahir",
                    Action = "Geri Yükleme",
                    Timestamp = new DateTime(2024, 5, 7, 11, 0, 0),
                    Status = 1
                },
                new BackupLog
                {
                    ID = 3,
                    FolderName = "Hiltown",
                    Action = "Yedekleme",
                    Timestamp = new DateTime(2024, 5, 7, 9, 0, 0),
                    Status = 0
                },
                new BackupLog
                {
                    ID = 4,
                    FolderName = "Hiltown",
                    Action = "Geri Yükleme",
                    Timestamp = new DateTime(2024, 5, 7, 8, 0, 0),
                    Status = 1
                }
            );

            modelBuilder.Entity<ServerPingStatus>(entity =>
            {
                entity.ToTable("ServerPingStatus");
                entity.HasKey(e => e.ID);
                entity.Property(e => e.LocationName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.ServerName).IsRequired().HasMaxLength(100);
                entity.Property(e => e.IPAddress).IsRequired().HasMaxLength(50);
                entity.Property(e => e.ErrorMessage).HasMaxLength(500);
            });
        }
    }
} 