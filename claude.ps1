# --- 0. DYNAMIC MODEL SELECTION ---
Clear-Host
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host "            CLAUDE LOCAL SETUP TOOL           " -ForegroundColor Magenta
Write-Host "==============================================" -ForegroundColor Magenta
Write-Host ""
Write-Host "Enter the Ollama model you want to use." -ForegroundColor White
Write-Host "Format Example: qwen2.5:7b, llama3:8b, or phi3" -ForegroundColor Gray
$TargetModel = Read-Host "Model Name"

# Fallback if the user leaves it blank
if ([string]::IsNullOrWhiteSpace($TargetModel)) { 
    $TargetModel = "qwen2.5:7b" 
    Write-Host "No model entered. Defaulting to $TargetModel" -ForegroundColor Yellow
}

# Generate a safe name for the optimized version (e.g., qwen2.5-7b-64k)
$OptimizedModelName = "$($TargetModel.Replace(':', '-'))-64k"

# --- FUNCTION: Network Resilient Execution (Hostel Wi-Fi Proof) ---
function Execute-WithRetry {
    param ([ScriptBlock]$ScriptBlock, [string]$Name)
    $success = $false
    while (-not $success) {
        try {
            & $ScriptBlock
            $success = $true
        } catch {
            Write-Host "Network failed during $Name. Retrying in 10s..." -ForegroundColor Yellow
            Start-Sleep -s 10
        }
    }
}

# --- 1. NODE.JS (Silent Install) ---
Write-Host "`n[1/6] Checking for Node.js..." -ForegroundColor Cyan
if (!(Get-Command node -ErrorAction SilentlyContinue)) {
    Execute-WithRetry -Name "Node.js" -ScriptBlock {
        winget install OpenJS.NodeJS --silent --accept-source-agreements --accept-package-agreements
    }
    # Update current session path
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
}

# --- 2. CLAUDE INSTALL & PERMANENT PATH ---
Write-Host "[2/6] Checking for Claude Code..." -ForegroundColor Cyan
$ClaudeDir = "$env:USERPROFILE\.local\bin"
if (!(Get-Command claude -ErrorAction SilentlyContinue)) {
    Execute-WithRetry -Name "Claude Install" -ScriptBlock { irm https://claude.ai/install.ps1 | iex }
    
    # Permanent Registry Update for Path
    $UserPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($UserPath -notlike "*$ClaudeDir*") {
        [Environment]::SetEnvironmentVariable("Path", $UserPath + ";" + $ClaudeDir, "User")
        $env:Path += ";" + $ClaudeDir
    }
}

# --- 3. OLLAMA SERVICE CHECK ---
Write-Host "[3/6] Ensuring Ollama is running..." -ForegroundColor Cyan
if (!(Get-Command ollama -ErrorAction SilentlyContinue)) {
    Execute-WithRetry -Name "Ollama" -ScriptBlock { irm https://ollama.com/install.ps1 | iex }
}

# Heartbeat check for Ollama API
try {
    Invoke-WebRequest -Uri "http://localhost:11434" -UseBasicParsing -ErrorAction Stop | Out-Null
} catch {
    Write-Host "Starting Ollama background engine..." -ForegroundColor Yellow
    Start-Process "ollama" -ArgumentList "serve" -WindowStyle Hidden
    Start-Sleep -s 5 
}

# --- 4. PERMANENT ENVIRONMENT CONFIG (Registry-Level) ---
Write-Host "[4/6] Setting up Registry Environment Variables..." -ForegroundColor Cyan
$EnvVars = @{ 
    "ANTHROPIC_AUTH_TOKEN" = "ollama"
    "ANTHROPIC_BASE_URL"   = "http://localhost:11434" 
}

foreach ($Var in $EnvVars.GetEnumerator()) {
    # Update Windows Registry permanently
    [System.Environment]::SetEnvironmentVariable($Var.Name, $Var.Value, "User")
    # Update current session immediately
    Set-Item -Path "Env:\$($Var.Name)" -Value $Var.Value
}

# --- 5. DYNAMIC MODEL PULL & 64K OPTIMIZATION ---
Write-Host "[5/6] Preparing model: $TargetModel..." -ForegroundColor Cyan
Execute-WithRetry -Name "Model Pull ($TargetModel)" -ScriptBlock { ollama pull $TargetModel }

$existingModels = ollama list
if ($existingModels -notmatch $OptimizedModelName) {
    Write-Host "Creating optimized version: $OptimizedModelName..." -ForegroundColor Yellow
    $TempModelfile = "$env:TEMP\Modelfile_ClaudeLocal"
    
    # Write raw UTF8 without BOM (prevents Ollama misparsing on older PS versions)
    $ModelfileLines = @("FROM $TargetModel", "PARAMETER num_ctx 65536")
    [System.IO.File]::WriteAllLines($TempModelfile, $ModelfileLines)
    
    ollama create $OptimizedModelName -f $TempModelfile
    Remove-Item -Path $TempModelfile -ErrorAction SilentlyContinue
}

# --- 6. LAUNCH ---
Write-Host "[6/6] Launching Claude Local via custom command..." -ForegroundColor Green

# Executing your specific instruction
ollama launch claude 

Write-Host "`n--- SESSION CLOSED ---" -ForegroundColor Yellow
Write-Host "Press any key to close."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")