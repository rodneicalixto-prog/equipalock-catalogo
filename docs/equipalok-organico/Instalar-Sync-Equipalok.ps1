param([switch]$Executar)

$ErrorActionPreference = 'Stop'
$cofre = 'C:\Users\USER\Desktop\Jarvis V8\obsidian-template'
$destino = Join-Path $cofre 'Equipalok'
$appDir = Join-Path $env:LOCALAPPDATA 'EquipalokSync'
$logPath = Join-Path $appDir 'sync.log'
$statePath = Join-Path $appDir 'hashes.json'
$repoApi = 'https://api.github.com/repos/rodneicalixto-prog/equipalock-catalogo/contents/docs/equipalok-organico'
$headers = @{ 'User-Agent' = 'EquipalokObsidianSync'; 'Accept' = 'application/vnd.github+json' }

function Hash-Bytes([byte[]]$bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($bytes)).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Log([string]$message) {
    Add-Content -LiteralPath $logPath -Value "$(Get-Date -Format o) $message" -Encoding UTF8
}

New-Item -ItemType Directory -Path $appDir -Force | Out-Null
if (-not (Test-Path -LiteralPath (Join-Path $cofre '.obsidian') -PathType Container)) {
    throw "Cofre nao encontrado ou nao validado: $cofre. Nenhum arquivo foi escrito."
}

if (-not $Executar) {
    $installed = Join-Path $appDir 'Instalar-Sync-Equipalok.ps1'
    if ($PSCommandPath -ne $installed) { Copy-Item -LiteralPath $PSCommandPath -Destination $installed -Force }
    $action = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$installed`" -Executar"
    $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).AddMinutes(1) -RepetitionInterval (New-TimeSpan -Minutes 15)
    $principal = New-ScheduledTaskPrincipal -UserId ([Security.Principal.WindowsIdentity]::GetCurrent().Name) -LogonType Interactive -RunLevel Limited
    Register-ScheduledTask -TaskName 'Equipalok Obsidian Sync' -Action $action -Trigger $trigger -Principal $principal -Description 'Sincroniza documentos versionados da Equipalok para o Obsidian a cada 15 minutos' -Force | Out-Null
    Write-Host 'Tarefa agendada registrada. Executando primeira sincronizacao.'
}

try {
    $entries = @(Invoke-RestMethod -Uri $repoApi -Headers $headers -TimeoutSec 30)
    if (-not $entries -or -not @($entries | Where-Object { $_.name -eq 'EQUIPALOK_POSTAGENS_INDICE.md' }).Count) {
        throw 'Indice obrigatorio ausente na origem; copia cancelada.'
    }
    New-Item -ItemType Directory -Path $destino -Force | Out-Null
    $state = @{}
    if (Test-Path -LiteralPath $statePath) {
        $old = Get-Content -LiteralPath $statePath -Raw | ConvertFrom-Json
        foreach ($prop in $old.PSObject.Properties) { $state[$prop.Name] = [string]$prop.Value }
    }
    $synced = 0
    foreach ($entry in $entries) {
        if ($entry.type -ne 'file' -or $entry.name -notmatch '^[A-Za-z0-9_-]+\.md$') { continue }
        $file = Invoke-RestMethod -Uri $entry.url -Headers $headers -TimeoutSec 30
        if ($file.encoding -ne 'base64' -or -not $file.content) { throw "Conteudo invalido: $($entry.name)" }
        $bytes = [Convert]::FromBase64String(($file.content -replace '\s', ''))
        $incomingHash = Hash-Bytes $bytes
        $target = Join-Path $destino $entry.name
        if (Test-Path -LiteralPath $target) {
            $currentHash = Hash-Bytes ([IO.File]::ReadAllBytes($target))
            if ($currentHash -eq $incomingHash) { $state[$entry.name] = $incomingHash; continue }
            if (-not $state.ContainsKey($entry.name) -or $currentHash -ne $state[$entry.name]) {
                Log "CONFLITO $($entry.name): versao local modificada; nao sobrescrita"
                continue
            }
        }
        $tmp = Join-Path $destino ($entry.name + '.sync-tmp')
        try {
            [IO.File]::WriteAllBytes($tmp, $bytes)
            if ((Hash-Bytes ([IO.File]::ReadAllBytes($tmp))) -ne $incomingHash) { throw 'Falha na verificacao da copia' }
            Move-Item -LiteralPath $tmp -Destination $target -Force
            if ((Hash-Bytes ([IO.File]::ReadAllBytes($target))) -ne $incomingHash) { throw 'Falha na verificacao final' }
            $state[$entry.name] = $incomingHash
            $synced++
            Log "OK $($entry.name) hash=$incomingHash"
        } finally {
            if (Test-Path -LiteralPath $tmp) { Remove-Item -LiteralPath $tmp -Force }
        }
    }
    $state | ConvertTo-Json | Set-Content -LiteralPath $statePath -Encoding UTF8
    Log "Ciclo concluido; arquivos atualizados=$synced"
    Write-Host "Sincronizacao concluida: $synced arquivo(s) atualizado(s). Destino: $destino"
} catch {
    Log "ERRO $($_.Exception.Message)"
    throw
}
