$NAMESPACE=$args[0]

if (-not $NAMESPACE ) {
  Write-Host  "Please provide the namespace as first argument." -ForegroundColor Red
  exit 1
}

$OCLI_PATH=$args[1]

if (-not $OCLI_PATH ) {
  Write-Host "Please provide the ocli path as second argument." -ForegroundColor Red
  exit 1
}

$GATEWAY = $args[2]

if (-not $GATEWAY ) {
  Write-Host "Gateway URL not provided. Attempting to fetch from Ingress."
  $REGEX="gateway\.[\d\.-]+\.([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}"
  $GATEWAY=kubectl get ingress -n $NAMESPACE | Select-String -Pattern "$REGEX" | ForEach-Object { $_.Matches.Value }
    if (-not $GATEWAY) {
        Write-Host "No gateway URL found in Ingress. Please provide the gateway URL as third argument. E.g. https://gateway.example.com" -ForegroundColor Red
        exit 1
    }
  $METRICS_URL="https://$GATEWAY/q/metrics"
} else {
  $METRICS_URL="$GATEWAY/q/metrics"
}
Write-Host "Using metrics URL: $METRICS_URL" -ForegroundColor Cyan

mkdir logs

# Fetch the list of pods in the specified namespace
$PODS = kubectl get pods --namespace $NAMESPACE --no-headers -o custom-columns=":metadata.name"

# Iterate over each pod
Foreach ($POD IN $PODS) {
  # Fetch the list of containers within the pod
  $CONTAINERS = kubectl get pods "$POD" --namespace "$NAMESPACE" --no-headers -o jsonpath='{.spec.containers[*].name}'
  # Iterate over each container in the pod
  Foreach ($CONTAINER IN $CONTAINERS) {
    # Generate a unique filename for each log file
    $CONTAINER_FOLDER=$POD + "_" + $CONTAINER
    mkdir logs/"$CONTAINER_FOLDER"
    # Fetch the log file from the container and copy it to log folder
    kubectl cp  $NAMESPACE/$POD":/opt/app/stdlist" logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
    # Fetch the metrics of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$NAMESPACE" -- curl -sSk "$METRICS_URL" > logs/"$CONTAINER_FOLDER"/metrics.log
  }
}
#Zip the logs
Compress-Archive -Path logs -DestinationPath data-gather.zip -Force
#Delete the logs folder
Remove-Item logs -Recurse

mkdir definitions

#Extract all the Jobs
& $OCLI_PATH model extract definitions/allJobs.txt from jd=@/@#@/@
#Extract all the Job Streams
& $OCLI_PATH model extract definitions/allJobStreams.txt from js=@/@#@/@
#Extract all the Workstations
& $OCLI_PATH model extract definitions/allWorkstations.txt from ws=@/@
#Extract all the Users
& $OCLI_PATH model extract definitions/allUsers.txt from user=@/@#@
#Extract all the Calenders
& $OCLI_PATH model extract definitions/allCalendar.txt from cal=@/@
#Extract all the Folders
& $OCLI_PATH model extract definitions/allFolders.txt from fol=@/@
#Extract all the Access Control List
& $OCLI_PATH model extract definitions/allACL.txt from acl=@
#Extract all the Security Roles
& $OCLI_PATH model extract definitions/allRoles.txt from srol=@
#Extract all the Variable Table
& $OCLI_PATH model extract definitions/allVariableTables.txt from vt=@/@
#Extract all the API Keys
& $OCLI_PATH model extract definitions/allAPIKeys.txt from api=@
#Extract all the event sources
& $OCLI_PATH model extract definitions/allEventSources.txt from eventsource=@
#Extract all the resources
& $OCLI_PATH model extract definitions/allResources.txt from res=@/@
#Extract all the human task queues
& $OCLI_PATH model extract definitions/allHumanTaskQueues.txt from htq=@/@
#Extract all AI Agents
& $OCLI_PATH model extract definitions/allAIAgents.txt from aiagent=@/@

#Zip the definitions
Compress-Archive -Path definitions -Update -DestinationPath data-gather.zip

#Delete the definition folder
Remove-Item definitions -Recurse