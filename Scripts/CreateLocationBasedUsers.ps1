# Lokasyon Bazlı Kullanıcı Oluşturma PowerShell Script'i
# Her lokasyon için kullanıcı adı lokasyon adı, şifre Mars2025! olacak

param(
    [string]$ConnectionString = "Server=(local);Database=master;Integrated Security=True;",
    [switch]$DryRun = $false  # Test modu için
)

# Sabit değerler
$Password = "Mars2025!"
$Role = "User"

function Write-ColorLog {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $Color
}

function Test-DatabaseConnection {
    param([string]$ConnectionString)
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        $connection.Close()
        return $true
    }
    catch {
        Write-ColorLog "Database connection failed: $_" -Color "Red"
        return $false
    }
}

function Get-Locations {
    param([string]$ConnectionString)
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $query = "SELECT Name FROM Locations WHERE Name != 'Merkez' ORDER BY Name"
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        
        $reader = $command.ExecuteReader()
        $locations = @()
        
        while ($reader.Read()) {
            $locations += $reader["Name"]
        }
        
        $reader.Close()
        $connection.Close()
        
        return $locations
    }
    catch {
        Write-ColorLog "Error getting locations: $_" -Color "Red"
        return @()
    }
}

function Test-UserExists {
    param(
        [string]$ConnectionString,
        [string]$Username
    )
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $query = "SELECT COUNT(*) FROM Users WHERE Username = @username"
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@username", $Username)))
        
        $count = [int]$command.ExecuteScalar()
        $connection.Close()
        
        return $count -gt 0
    }
    catch {
        Write-ColorLog "Error checking user existence: $_" -Color "Red"
        return $false
    }
}

function Create-LocationUser {
    param(
        [string]$ConnectionString,
        [string]$Username,
        [string]$Password,
        [string]$LocationName,
        [bool]$DryRun
    )
    
    if ($DryRun) {
        Write-ColorLog "DRY RUN: Would create user '$Username' for location '$LocationName'" -Color "Yellow"
        return $true
    }
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $query = @"
            INSERT INTO Users (Username, Password, Role, LocationName, PhoneNumber)
            VALUES (@username, @password, @role, @locationName, NULL)
"@
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@username", $Username)))
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@password", $Password)))
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@role", $Role)))
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@locationName", $LocationName)))
        
        $rowsAffected = $command.ExecuteNonQuery()
        $connection.Close()
        
        return $rowsAffected -gt 0
    }
    catch {
        Write-ColorLog "Error creating user '$Username': $_" -Color "Red"
        return $false
    }
}

function Update-UserPassword {
    param(
        [string]$ConnectionString,
        [string]$Username,
        [string]$Password,
        [string]$LocationName,
        [bool]$DryRun
    )
    
    if ($DryRun) {
        Write-ColorLog "DRY RUN: Would update user '$Username' password and location" -Color "Yellow"
        return $true
    }
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $query = @"
            UPDATE Users 
            SET Password = @password, LocationName = @locationName
            WHERE Username = @username
"@
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@username", $Username)))
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@password", $Password)))
        $command.Parameters.Add((New-Object System.Data.SqlClient.SqlParameter("@locationName", $LocationName)))
        
        $rowsAffected = $command.ExecuteNonQuery()
        $connection.Close()
        
        return $rowsAffected -gt 0
    }
    catch {
        Write-ColorLog "Error updating user '$Username': $_" -Color "Red"
        return $false
    }
}

function Get-UserStatistics {
    param([string]$ConnectionString)
    
    try {
        $connection = New-Object System.Data.SqlClient.SqlConnection($ConnectionString)
        $connection.Open()
        
        $query = @"
            SELECT 
                COUNT(*) as TotalUsers,
                COUNT(CASE WHEN Role = 'Admin' THEN 1 END) as AdminUsers,
                COUNT(CASE WHEN Role = 'User' THEN 1 END) as RegularUsers
            FROM Users
"@
        
        $command = $connection.CreateCommand()
        $command.CommandText = $query
        
        $reader = $command.ExecuteReader()
        $stats = @{}
        
        if ($reader.Read()) {
            $stats = @{
                TotalUsers = $reader["TotalUsers"]
                AdminUsers = $reader["AdminUsers"]
                RegularUsers = $reader["RegularUsers"]
            }
        }
        
        $reader.Close()
        $connection.Close()
        
        return $stats
    }
    catch {
        Write-ColorLog "Error getting statistics: $_" -Color "Red"
        return @{}
    }
}

# Ana işlem
Write-ColorLog "Lokasyon bazlı kullanıcı oluşturma işlemi başlıyor..." -Color "Cyan"

if ($DryRun) {
    Write-ColorLog "DRY RUN MODE - Hiçbir değişiklik yapılmayacak" -Color "Yellow"
}

# Database bağlantısını test et
if (-not (Test-DatabaseConnection -ConnectionString $ConnectionString)) {
    Write-ColorLog "Database bağlantısı başarısız! İşlem durduruluyor." -Color "Red"
    exit 1
}

Write-ColorLog "Database bağlantısı başarılı" -Color "Green"

# Lokasyonları al
$locations = Get-Locations -ConnectionString $ConnectionString
Write-ColorLog "Toplam $($locations.Count) lokasyon bulundu" -Color "Cyan"

$createdCount = 0
$updatedCount = 0
$errorCount = 0

# Her lokasyon için kullanıcı oluştur/güncelle
foreach ($location in $locations) {
    $username = $location
    
    Write-ColorLog "İşleniyor: $location" -Color "White"
    
    if (Test-UserExists -ConnectionString $ConnectionString -Username $username) {
        # Kullanıcı mevcut, şifreyi güncelle
        if (Update-UserPassword -ConnectionString $ConnectionString -Username $username -Password $Password -LocationName $location -DryRun $DryRun) {
            Write-ColorLog "✓ Kullanıcı güncellendi: $username" -Color "Green"
            $updatedCount++
        }
        else {
            Write-ColorLog "✗ Kullanıcı güncellenemedi: $username" -Color "Red"
            $errorCount++
        }
    }
    else {
        # Yeni kullanıcı oluştur
        if (Create-LocationUser -ConnectionString $ConnectionString -Username $username -Password $Password -LocationName $location -DryRun $DryRun) {
            Write-ColorLog "✓ Kullanıcı oluşturuldu: $username" -Color "Green"
            $createdCount++
        }
        else {
            Write-ColorLog "✗ Kullanıcı oluşturulamadı: $username" -Color "Red"
            $errorCount++
        }
    }
}

# Özet rapor
Write-ColorLog "================== İŞLEM ÖZETI ==================" -Color "Cyan"
Write-ColorLog "Oluşturulan kullanıcılar: $createdCount" -Color "Green"
Write-ColorLog "Güncellenen kullanıcılar: $updatedCount" -Color "Yellow"
Write-ColorLog "Hata sayısı: $errorCount" -Color "Red"

if (-not $DryRun) {
    # Güncel istatistikleri göster
    $stats = Get-UserStatistics -ConnectionString $ConnectionString
    if ($stats.Count -gt 0) {
        Write-ColorLog "================== KULLANICI İSTATİSTİKLERİ ==================" -Color "Cyan"
        Write-ColorLog "Toplam kullanıcı: $($stats.TotalUsers)" -Color "White"
        Write-ColorLog "Admin kullanıcı: $($stats.AdminUsers)" -Color "White"
        Write-ColorLog "Normal kullanıcı: $($stats.RegularUsers)" -Color "White"
    }
}

Write-ColorLog "Tüm kullanıcıların şifresi: $Password" -Color "Magenta"
Write-ColorLog "İşlem tamamlandı!" -Color "Green"

# Örnek kullanım:
# .\CreateLocationBasedUsers.ps1
# .\CreateLocationBasedUsers.ps1 -DryRun  # Test modu
# .\CreateLocationBasedUsers.ps1 -ConnectionString "Server=myserver;Database=mydb;..." 