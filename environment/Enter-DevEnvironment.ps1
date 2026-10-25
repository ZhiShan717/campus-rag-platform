[CmdletBinding()]
param([switch]$Quiet)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$localRoot = Join-Path $workspaceRoot '.local'
$pythonRoot = Join-Path $localRoot 'Python311'
$venvRoot = Join-Path $workspaceRoot '.venv'

if (-not $env:JAVA_HOME -or -not (Test-Path -LiteralPath (Join-Path $env:JAVA_HOME 'bin\java.exe'))) { $env:JAVA_HOME = 'D:\JDK' }
if (-not $env:MAVEN_HOME -or -not (Test-Path -LiteralPath (Join-Path $env:MAVEN_HOME 'bin\mvn.cmd'))) { $env:MAVEN_HOME = 'D:\maven\apache-maven-3.9.9-bin\apache-maven-3.9.9' }
$env:OLLAMA_MODELS = Join-Path $localRoot 'ollama-models'
$env:OLLAMA_HOST = '127.0.0.1:11434'
$env:OLLAMA_MODEL = 'qwen3:1.7b'
$env:OLLAMA_NUM_PARALLEL = '1'
$env:OLLAMA_MAX_LOADED_MODELS = '1'
$env:OLLAMA_KEEP_ALIVE = '0'
$env:OLLAMA_CONTEXT_LENGTH = '2048'
$env:HF_HOME = Join-Path $localRoot 'huggingface'
$env:TORCH_HOME = Join-Path $localRoot 'torch'
$env:SENTENCE_TRANSFORMERS_HOME = Join-Path $localRoot 'models\cache'
$env:EMBEDDING_MODEL_PATH = Join-Path $localRoot 'models\bge-large-zh-v1.5'
$env:EMBEDDING_DIMENSIONS = '1024'
$env:RERANKER_MODEL_PATH = Join-Path $localRoot 'models\bge-reranker-base'
$env:LANGGRAPH_STRICT_MSGPACK = 'true'
$env:DOCKER_CONFIG = Join-Path $localRoot 'docker-cli'
$env:DOCKER_CONTEXT = 'desktop-linux'
$env:DOCKER_HOST = $null
$env:DOCKER_TLS_VERIFY = $null
$env:DOCKER_CERT_PATH = $null
$env:PYTHONIOENCODING = 'utf-8'
$env:PYTHONUTF8 = '1'

$developmentPaths = @()
if (Test-Path -LiteralPath (Join-Path $venvRoot 'Scripts\python.exe')) {
    $developmentPaths += Join-Path $venvRoot 'Scripts'
    $env:VIRTUAL_ENV = $venvRoot
}
$developmentPaths += @(
    $pythonRoot,
    (Join-Path $pythonRoot 'Scripts'),
    (Join-Path $env:JAVA_HOME 'bin'),
    (Join-Path $env:MAVEN_HOME 'bin'),
    'D:\nodejs',
    'D:\git\Git\cmd',
    'D:\Microsoft VS Code\bin',
    (Join-Path $localRoot 'DockerDesktop\resources\bin'),
    (Join-Path $env:LOCALAPPDATA 'Programs\DockerDesktop\resources\bin'),
    (Join-Path $env:ProgramFiles 'Docker\Docker\resources\bin'),
    (Join-Path $localRoot 'Ollama'),
    (Join-Path $localRoot 'GitHubCLI\bin'),
    (Join-Path $env:LOCALAPPDATA 'Programs\Ollama')
)
$developmentPaths = @($developmentPaths | Where-Object { Test-Path -LiteralPath $_ -PathType Container })
$seenPaths = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
$combinedPaths = foreach ($entry in ($developmentPaths + @($env:PATH -split ';'))) {
    if ($entry -and $seenPaths.Add($entry.TrimEnd('\'))) { $entry }
}
$env:PATH = $combinedPaths -join ';'

if (-not $Quiet) {
    Write-Host 'Campus RAG development environment is active in this terminal.'
    Write-Host ('Python: ' + (Get-Command python -ErrorAction SilentlyContinue).Source)
    Write-Host ('JAVA_HOME: ' + $env:JAVA_HOME)
    Write-Host ('Workspace: ' + $workspaceRoot)
    Write-Host 'Run .\environment\Check-Environment.ps1 to check installed tools.'
    Set-Location -LiteralPath $workspaceRoot
}
