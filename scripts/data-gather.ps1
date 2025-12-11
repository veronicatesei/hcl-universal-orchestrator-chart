param(
    [switch]$Help,
    [string]$Namespace,
    [string]$OcliPath,
    [switch]$SkipDefs
)

function Print-Usage {
    Write-Host "Usage: .\data-gather.ps1 [-Help] -Namespace <namespace> [-OcliPath <path>] [-SkipDefs]"
    Write-Host "Options:"
    Write-Host "  -Help          Show this help message"
    Write-Host "  -Namespace     [Mandatory] Specify the K8s namespace where UNO is deployed"
    Write-Host "  -OcliPath      [Optional] Specify the path to OCLI executable to gather definitions. If not provided and not found in PATH, definitions gathering will be skipped."
    Write-Host "  -SkipDefs      [Optional] Skip gathering definitions from OCLI"
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

if (-not $Namespace ) {
  Write-Host  "Please provide the namespace with option -Namespace." -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host "Universal Orchestrator Data Gather Script" -ForegroundColor Magenta
Write-Host "===================================================" -ForegroundColor Magenta
Write-Host ""

if (-not $OcliPath -and -not $SkipDefs) {
  if ( Get-Command ocli -ErrorAction SilentlyContinue) {
    $OcliPath = (Get-Command ocli).Source
    Write-Host "OCLI found in PATH. It will be used for definitions gathering" -ForegroundColor Cyan
  } else {
    Write-Host "OCLI path not provided. Definitions gathering will be skipped." -ForegroundColor Yellow
    $SkipDefs = $true
  }
}

Write-Host "Gathering logs from namespace: $Namespace" -ForegroundColor Cyan

mkdir logs

# Fetch the list of pods in the specified namespace
$PODS = kubectl get pods --namespace $Namespace --no-headers -o custom-columns=":metadata.name"

# Iterate over each pod
Foreach ($POD IN $PODS) {
  # Fetch the list of containers within the pod
  $CONTAINERS = kubectl get pods "$POD" --namespace "$Namespace" --no-headers -o jsonpath='{.spec.containers[*].name}'
  # Iterate over each container in the pod
  Foreach ($CONTAINER IN $CONTAINERS) {
    # Generate a unique filename for each log file
    $CONTAINER_FOLDER=$POD + "_" + $CONTAINER
    mkdir logs/"$CONTAINER_FOLDER"
    # Fetch the log file from the container and copy it to log folder
    kubectl cp  $Namespace/$POD":/opt/app/stdlist" logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
    # Fetch the metrics of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$Namespace" -- curl -sSk https://localhost:8443/q/metrics > logs/"$CONTAINER_FOLDER"/metrics.log
    # Fetch the health of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$Namespace" -- curl -sSk https://localhost:8443/q/health > logs/"$CONTAINER_FOLDER"/health.log
  }
}
#Zip the logs
Compress-Archive -Path logs -DestinationPath data-gather.zip -Force
#Delete the logs folder
Remove-Item logs -Recurse

Write-Host "Logs gathering completed." -ForegroundColor Cyan

if ($SkipDefs) {
    Write-Host "Skipping definitions gathering." -ForegroundColor Yellow
    exit 0
}

Write-Host "Gathering definitions using OCLI at path: $OcliPath" -ForegroundColor Cyan

mkdir definitions

#Extract all the Jobs
& $OcliPath model extract definitions/allJobs.txt from jd=@/@#@/@
#Extract all the Job Streams
& $OcliPath model extract definitions/allJobStreams.txt from js=@/@#@/@
#Extract all the Workstations
& $OcliPath model extract definitions/allWorkstations.txt from ws=@/@
#Extract all the Users
& $OcliPath model extract definitions/allUsers.txt from user=@/@#@
#Extract all the Calenders
& $OcliPath model extract definitions/allCalendar.txt from cal=@/@
#Extract all the Folders
& $OcliPath model extract definitions/allFolders.txt from fol=@/@
#Extract all the Access Control List
& $OcliPath model extract definitions/allACL.txt from acl=@
#Extract all the Security Roles
& $OcliPath model extract definitions/allRoles.txt from srol=@
#Extract all the Variable Table
& $OcliPath model extract definitions/allVariableTables.txt from vt=@/@
#Extract all the API Keys
& $OcliPath model extract definitions/allAPIKeys.txt from api=@
#Extract all the event sources
& $OcliPath model extract definitions/allEventSources.txt from eventsource=@/@
#Extract all the resources
& $OcliPath model extract definitions/allResources.txt from res=@/@
#Extract all the human task queues
& $OcliPath model extract definitions/allHumanTaskQueues.txt from htq=@/@
#Extract all AI Agents
& $OcliPath model extract definitions/allAIAgents.txt from aiagent=@/@

#Zip the definitions
Compress-Archive -Path definitions -Update -DestinationPath data-gather.zip

#Delete the definition folder
Remove-Item definitions -Recurse

Write-Host "Definitions gathering completed." -ForegroundColor Cyan