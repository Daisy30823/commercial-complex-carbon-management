param(
    [Parameter(Mandatory = $true)]
    [string]$SourcePath,
    [string]$DestinationPath
)

$DestinationPath = if ($DestinationPath) { $DestinationPath } else { Join-Path $PSScriptRoot "..\database\cloud\railway_init.sql" }
$source = (Resolve-Path -LiteralPath $SourcePath).Path
$destination = [System.IO.Path]::GetFullPath($DestinationPath)
[System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($destination)) | Out-Null

$utf8 = [System.Text.UTF8Encoding]::new($false)
$reader = [System.IO.StreamReader]::new($source, $utf8, $true)
$writer = [System.IO.StreamWriter]::new($destination, $false, $utf8)

try {
    $courseDesignLabel = -join ([char[]](0x8BFE, 0x7A0B, 0x8BBE, 0x8BA1))
    $generatedSampleLabel = -join ([char[]](0x7A0B, 0x5E8F, 0x751F, 0x6210, 0x793A, 0x4F8B))
    $skipTemporaryViews = $false
    $writer.WriteLine('-- Railway MySQL 8 initialization for commercial-complex-carbon')
    $writer.WriteLine('-- Generated from the frozen course release dump; do not add credentials here.')
    $writer.WriteLine('CREATE TABLE IF NOT EXISTS `schema_migration_history` (')
    $writer.WriteLine('  `version` varchar(100) NOT NULL,')
    $writer.WriteLine('  `description` varchar(255) NOT NULL,')
    $writer.WriteLine('  `installed_at` timestamp NULL DEFAULT NULL,')
    $writer.WriteLine('  `success` tinyint NOT NULL DEFAULT 0,')
    $writer.WriteLine('  PRIMARY KEY (`version`)')
    $writer.WriteLine(') ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;')
    $writer.WriteLine()

    while (($line = $reader.ReadLine()) -ne $null) {
        if ($line -match '^-- Temporary view structure for view') {
            $skipTemporaryViews = $true
            continue
        }
        if ($skipTemporaryViews) {
            if ($line -match '^-- Dumping events for database') {
                $skipTemporaryViews = $false
                $writer.WriteLine($line)
            }
            continue
        }
        if ($line -match '^CREATE DATABASE\b' -or $line -match '^USE\s+`' -or
            $line -match '\bDROP\s+(DATABASE|TABLE|VIEW|PROCEDURE|FUNCTION|TRIGGER)\b') {
            continue
        }

        $line = [regex]::Replace($line, 'DEFINER=`[^`]+`@`[^`]+`', '')
        $line = [regex]::Replace($line, '\$2[aby]\$\d{2}\$[./A-Za-z0-9]{53}', '!cloud-login-disabled!')
        $line = [regex]::Replace($line, "'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'", 'NULL')
        $line = [regex]::Replace($line, "'(?:\+?86[- ]?)?1[3-9][0-9]{9}'", 'NULL')
        $line = [regex]::Replace($line, "'[0-9]{3,4}-[0-9]{7,8}'", 'NULL')
        $line = $line.Replace($courseDesignLabel, $generatedSampleLabel)

        if ($line.StartsWith('INSERT INTO `app_user` VALUES ')) {
            $line = $line.Replace("(1,4,'admin',", "(1,4,'cloud_admin_pending',")
            $line = $line.Replace(',0,NULL,1,', ',0,NULL,0,')
        }

        $writer.WriteLine($line)
    }
} finally {
    $reader.Dispose()
    $writer.Dispose()
}

Write-Host "Generated $destination"
