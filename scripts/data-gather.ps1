param(
    [switch]$Help,
    [string]$Namespace,
    [string]$OcliPath,
    [string]$OcliContext,
    [switch]$SkipDefs
)

function Print-Usage {
    Write-Host "Usage: .\data-gather.ps1 [-Help] [-Namespace <namespace>] [-OcliPath <path>] [-SkipDefs] [-OcliContext <context>]"
    Write-Host "Options:"
    Write-Host "  -Help          Show this help message"
    Write-Host "  -Namespace     [Optional] Specify the K8s namespace where UNO is deployed (if omitted, it will be requested interactively)"
    Write-Host "  -OcliPath      [Optional] Specify the path to OCLI executable to gather definitions. If not provided and not found in PATH, definitions gathering will be skipped."
    Write-Host "  -OcliContext   [Optional] Specify the OCLI context to use when gathering definitions."
    Write-Host "                 If omitted and definitions are enabled, you'll be asked whether to use current context or provide one."
    Write-Host "  -SkipDefs      [Optional] Skip gathering definitions from OCLI"
}

function Format-OcliCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    $formatted = foreach ($arg in $Arguments) {
        if ([string]::IsNullOrEmpty($arg)) {
            "''"
        }
        elseif ($arg -match '[\s''"`$&|;<>(){}\[\]*?]') {
            "'" + ($arg -replace "'", "''") + "'"
        }
        else {
            $arg
        }
    }

    return ($formatted -join ' ')
}

function Write-OcliCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OcliPath,
        [string[]]$OcliArgs,
        [Parameter(Mandatory = $true)]
        [string[]]$CommandArgs
    )

    $command = @($OcliPath) + @($OcliArgs) + @($CommandArgs)
    Write-Host ("Executing OCLI command: $(Format-OcliCommand -Arguments $command)") -ForegroundColor Cyan
}

function Gather-Logs {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Namespace
    )

    Write-Host "Gathering logs using kubectl context '$(kubectl config current-context)' and namespace '$Namespace'" -ForegroundColor Cyan

    $pods = @(kubectl get pods --namespace $Namespace --no-headers -o custom-columns=":metadata.name" -l prometheus)
    if ($pods.Count -eq 0) {
        Write-Host "No pods found in namespace $Namespace. Skipping logs gathering." -ForegroundColor Yellow
        return
    }

    mkdir logs | Out-Null
    $logsCollected = $false

    Foreach ($POD IN $pods) {
        Write-Host "Collecting logs from pod: $POD"
        $containersRaw = kubectl get pods "$POD" --namespace "$Namespace" --no-headers -o jsonpath='{.spec.containers[*].name}'
        $CONTAINERS = $containersRaw -split '\s+'

        Foreach ($CONTAINER IN $CONTAINERS) {
            if ([string]::IsNullOrWhiteSpace($CONTAINER)) { continue }
            if ($POD -like "*audit*" -and $CONTAINER -eq "audit-log-sidecar") { continue }

            $logsCollected = $true
            $CONTAINER_FOLDER = $POD + "_" + $CONTAINER
            mkdir logs/"$CONTAINER_FOLDER" | Out-Null

            if ($POD -like "*audit*" -and $CONTAINER -eq "error-log-sidecar") {
                kubectl cp "${Namespace}/${POD}:/opt/app/audit/errors.json" "logs/$CONTAINER_FOLDER/errors.json" -c "$CONTAINER"
            }
            else {
                kubectl cp $Namespace/$POD":/opt/app/stdlist" logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
            }

            kubectl exec "$POD" -c "$CONTAINER" --namespace "$Namespace" -- curl -sSk https://localhost:8443/q/metrics > logs/"$CONTAINER_FOLDER"/metrics.log
            kubectl exec "$POD" -c "$CONTAINER" --namespace "$Namespace" -- curl -sSk https://localhost:8443/q/health > logs/"$CONTAINER_FOLDER"/health.log
        }
    }

    if (-not $logsCollected) {
        Write-Host "No logs were collected from namespace $Namespace. Skipping logs archive creation." -ForegroundColor Yellow
        if (Test-Path logs) {
            Remove-Item logs -Recurse
        }
        return
    }

    Write-Host "Finished gathering logs from all pods and containers in namespace $Namespace." -ForegroundColor Cyan
    Write-Host "Compressing logs into data-gather.zip file." -ForegroundColor Cyan
    try {
        Compress-Archive -Path logs -DestinationPath data-gather.zip -Force
        Write-Host "Created data-gather.zip containing collected logs." -ForegroundColor Green
    } catch {
        Write-Host "Error occurred while compressing logs: $_" -ForegroundColor Red
        exit 1
    }

    if (Test-Path logs) {
        Remove-Item logs -Recurse
    }
    Write-Host "Logs gathering completed." -ForegroundColor Cyan
}

function Gather-Definitions {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OcliPath,
        [string]$OcliContext
    )

    $ocliArgs = @()
    if (-not [string]::IsNullOrWhiteSpace($OcliContext)) {
        $ocliArgs += "-context"
        $ocliArgs += $OcliContext
        Write-Host "Gathering definitions using OCLI at path: $OcliPath with context: $OcliContext" -ForegroundColor Cyan
    } else {
        Write-Host "Gathering definitions using OCLI at path: $OcliPath using current context" -ForegroundColor Cyan
    }

    mkdir definitions | Out-Null

            $commandArgs = @('model', 'extract', 'definitions/allJobs.txt', 'from', 'jd=@/@#@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allJobStreams.txt', 'from', 'js=@/@#@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allWorkstations.txt', 'from', 'ws=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allUsers.txt', 'from', 'user=@/@#@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allCalendar.txt', 'from', 'cal=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allFolders.txt', 'from', 'fol=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allACL.txt', 'from', 'acl=@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allRoles.txt', 'from', 'srol=@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allVariableTables.txt', 'from', 'vt=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allAPIKeys.txt', 'from', 'api=@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allEventSources.txt', 'from', 'eventsource=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allResources.txt', 'from', 'res=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allHumanTaskQueues.txt', 'from', 'htq=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allAIAgents.txt', 'from', 'aiagent=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allEndpoints.txt', 'from', 'endpoints=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

            $commandArgs = @('model', 'extract', 'definitions/allRunCycleGroups.txt', 'from', 'rcg=@/@')
            Write-OcliCommand -OcliPath $OcliPath -OcliArgs $ocliArgs -CommandArgs $commandArgs
            & $OcliPath @ocliArgs @commandArgs

    Write-Host "Definitions extraction completed." -ForegroundColor Cyan
    Write-Host "Adding extracted definitions to data-gather.zip file..." -ForegroundColor Cyan
    try {
        if (Test-Path data-gather.zip) {
            Compress-Archive -Path definitions -Update -DestinationPath data-gather.zip
        } else {
            Compress-Archive -Path definitions -DestinationPath data-gather.zip -Force
        }
        Write-Host "Added extracted definitions to data-gather.zip file." -ForegroundColor Cyan
        Remove-Item definitions -Recurse
        Write-Host "Done." -ForegroundColor Cyan
    } catch {
        Write-Host "Failed to update data-gather.zip with definitions." -ForegroundColor Red
        Remove-Item definitions -Recurse
        exit 1
    }
}

function Resolve-OcliContext {
    param(
        [string]$OcliContext,
        [switch]$SkipDefs
    )

    if ($SkipDefs -or -not [string]::IsNullOrWhiteSpace($OcliContext)) {
        return $OcliContext
    }

    $maxConfirmationAttempts = 3
    for ($attempt = 1; $attempt -le $maxConfirmationAttempts; $attempt++) {
        $useCurrentContext = Read-Host "Use current OCLI context for definitions extraction? [Y/n]"
        if ([string]::IsNullOrWhiteSpace($useCurrentContext) -or $useCurrentContext -match '^[yY]([eE][sS])?$') {
            return $null
        }

        if ($useCurrentContext -match '^[nN]([oO])?$') {
            break
        }

        Write-Host "Please answer y or n." -ForegroundColor Yellow

        if ($attempt -eq $maxConfirmationAttempts) {
            Write-Host "No valid answer provided. Exiting." -ForegroundColor Red
            exit 1
        }
    }

    $maxContextAttempts = 3
    for ($attempt = 1; $attempt -le $maxContextAttempts; $attempt++) {
        $typedContext = Read-Host "Enter OCLI context name"
        if (-not [string]::IsNullOrWhiteSpace($typedContext)) {
            return $typedContext
        }

        Write-Host "OCLI context cannot be empty." -ForegroundColor Yellow
    }

    Write-Host "No OCLI context provided. Exiting." -ForegroundColor Red
    exit 1
}

function Check-ExistingFolders {
    foreach ($folder in @("logs", "definitions")) {
        if (Test-Path $folder) {
            Write-Host "Folder '$folder' already exists." -ForegroundColor Yellow
            $answer = Read-Host "Do you want to remove it before proceeding? [y/N]"
            if ($answer -match '^[yY]([eE][sS])?$') {
                Remove-Item $folder -Recurse -Force
                Write-Host "Folder '$folder' removed." -ForegroundColor Green
            } else {
                Write-Host "Cannot proceed with existing '$folder' folder. Remove it manually and rerun the script." -ForegroundColor Red
                exit 1
            }
        }
    }

    if (Test-Path "data-gather.zip") {
        Write-Host "File 'data-gather.zip' already exists." -ForegroundColor Yellow
        $answer = Read-Host "Do you want to remove it before proceeding? [y/N]"
        if ($answer -match '^[yY]([eE][sS])?$') {
            Remove-Item "data-gather.zip" -Force
            Write-Host "File 'data-gather.zip' removed." -ForegroundColor Green
        } else {
            Write-Host "Cannot proceed with existing 'data-gather.zip'. Remove it manually and rerun the script." -ForegroundColor Red
            exit 1
        }
    }
}

if ($Help) {
    Print-Usage
    exit 0
}

# Check kubectl is installed
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "kubectl is not installed or not found in PATH. Please install kubectl to proceed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host "Universal Orchestrator Data Gather Script" -ForegroundColor Magenta
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host ""

Check-ExistingFolders

if ([string]::IsNullOrWhiteSpace($Namespace)) {
    $maxNamespaceAttempts = 3
    Write-Host "Kubernetes namespace not provided as an argument." -ForegroundColor Yellow
    for ($attempt = 1; $attempt -le $maxNamespaceAttempts; $attempt++) {
        $Namespace = Read-Host "Enter Kubernetes namespace"
        if (-not [string]::IsNullOrWhiteSpace($Namespace)) {
            break
        }
        Write-Host "Namespace cannot be empty." -ForegroundColor Yellow
    }

    if ([string]::IsNullOrWhiteSpace($Namespace)) {
        Write-Host "No namespace provided. Exiting." -ForegroundColor Red
        exit 1
    }
}

Gather-Logs -Namespace $Namespace

if (-not $OcliPath -and -not $SkipDefs) {
  if (Get-Command ocli -ErrorAction SilentlyContinue) {
    $OcliPath = (Get-Command ocli).Source
    Write-Host "OCLI found in PATH. It will be used for definitions gathering" -ForegroundColor Cyan
  } else {
    Write-Host "OCLI path not provided and not found in path. Definitions gathering will be skipped. Add OCLI to path or provide the path to OCLI with -OcliPath argument." -ForegroundColor Yellow
    $SkipDefs = $true
  }
}

if ($SkipDefs) {
    Write-Host "Skipping definitions gathering." -ForegroundColor Yellow
    exit 0
}

$OcliContext = Resolve-OcliContext -OcliContext $OcliContext -SkipDefs:$SkipDefs

Gather-Definitions -OcliPath $OcliPath -OcliContext $OcliContext
