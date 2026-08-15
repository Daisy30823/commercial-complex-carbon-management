param(
    [Parameter(Mandatory = $true)]
    [string]$LocalPropertiesPath
)

$properties = @{}
Get-Content -LiteralPath $LocalPropertiesPath -Encoding UTF8 | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]*)=(.*)$') {
        $properties[$matches[1].Trim()] = $matches[2].Trim()
    }
}

if ($properties['db.url'] -notmatch '^jdbc:mysql://([^:/]+):(\d+)/') {
    throw 'Unsupported local JDBC URL'
}

$mysql = (Get-Command mysql -ErrorAction Stop).Source
$hostName = $matches[1]
$port = $matches[2]
$user = $properties['db.username']
$password = $properties['db.password']
$database = 'cc_railway_verify_' + [Guid]::NewGuid().ToString('N').Substring(0, 12)
$sourceSqlPath = (Resolve-Path (Join-Path $PSScriptRoot '..\database\cloud\railway_init.sql')).Path
$temporarySqlPath = Join-Path ([System.IO.Path]::GetTempPath()) ($database + '.sql')
Copy-Item -LiteralPath $sourceSqlPath -Destination $temporarySqlPath
$sqlPath = $temporarySqlPath.Replace('\', '/')

$env:MYSQL_PWD = $password
try {
    & $mysql --protocol=TCP --host=$hostName --port=$port --user=$user --default-character-set=utf8mb4 --execute="CREATE DATABASE ``$database`` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to create temporary verification database' }

    & $mysql --protocol=TCP --host=$hostName --port=$port --user=$user --database=$database --default-character-set=utf8mb4 --execute="source $sqlPath"
    if ($LASTEXITCODE -ne 0) { throw 'Cloud SQL import failed' }

    & $mysql --protocol=TCP --host=$hostName --port=$port --user=$user --database=$database --default-character-set=utf8mb4 --execute="UPDATE app_user SET username='admin',user_status=1 WHERE user_id=1"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to provision the temporary administrator' }

    $summary = & $mysql --protocol=TCP --host=$hostName --port=$port --user=$user --database=$database --batch --skip-column-names --execute="SELECT CONCAT('tables=',(SELECT COUNT(*) FROM information_schema.tables WHERE table_schema=DATABASE() AND table_type='BASE TABLE' AND table_name<>'schema_migration_history'),', views=',(SELECT COUNT(*) FROM information_schema.views WHERE table_schema=DATABASE()),', functions=',(SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=DATABASE() AND routine_type='FUNCTION'),', procedures=',(SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema=DATABASE() AND routine_type='PROCEDURE'),', triggers=',(SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_schema=DATABASE()),', complexes=',(SELECT COUNT(*) FROM commercial_complex WHERE record_status=1),', energy_records=',(SELECT COUNT(*) FROM energy_consumption_record))"
    if ($LASTEXITCODE -ne 0) { throw 'Unable to read cloud database verification summary' }
    Write-Host "Cloud database verification: $summary"

    $env:DB_HOST = $hostName
    $env:DB_PORT = $port
    $env:DB_NAME = $database
    $env:DB_USER = $user
    $env:DB_PASSWORD = $password
    & (Join-Path $PSScriptRoot '..\mvnw.cmd') test
    if ($LASTEXITCODE -ne 0) { throw 'Maven tests failed against the cloud database' }
} finally {
    & $mysql --protocol=TCP --host=$hostName --port=$port --user=$user --execute="DROP DATABASE IF EXISTS ``$database``" 2>$null
    Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    Remove-Item Env:DB_PASSWORD -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $temporarySqlPath -Force -ErrorAction SilentlyContinue
}
