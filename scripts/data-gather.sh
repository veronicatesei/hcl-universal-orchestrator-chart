#!/bin/bash

printUsage() {
  echo "Usage: $0 [-h | --help] [-n | --namespace <namespace>] [-o | --ocli-path <ocli-path>] [-sd | --skip-defs]"
  echo "Options:"
  echo "  -h,  --help          Show this help message"
  echo "  -n,  --namespace     [Mandatory] Specify the K8s namespace where UNO is deployed"
  echo "  -o,  --ocli-path     [Optional] Specify the path to OCLI executable to gather definitions. If not provided and not found in PATH, definitions gathering will be skipped."
  echo "  -sd, --skip-defs     [Optional] Skip gathering definitions from OCLI"
}

SKIP_DEFS=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) printUsage; exit 0 ;;
    -n|--namespace) NAMESPACE="$2"; shift ;;
    -o|--ocli-path) OCLI_PATH="$2"; shift ;;
    -sd|--skip-defs) SKIP_DEFS=true ;;
    *) echo "Unknown option: $1"; printUsage; exit 1 ;;
  esac
  shift
done

red()   { echo -e "\e[31m$*\e[0m"; }
yellow() { echo -e "\e[33m$*\e[0m"; }
green() { echo -e "\e[32m$*\e[0m"; }
cyan() { echo -e "\e[36m$*\e[0m"; }
magenta() { echo -e "\e[35m$*\e[0m"; }

magenta " ========================================== "
magenta " Universal Orchestrator Data Gather Script"
magenta " ========================================== "
echo

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    red "kubectl could not be found. Please install kubectl to proceed."
    exit 1
fi

if [ -z "$NAMESPACE" ]; then
  red "Please provide the namespace with the -n or --namespace argument."
  exit 1
fi

if [ -z "$OCLI_PATH" ] && [ "$SKIP_DEFS" = false ]; then
  if command -v ocli &> /dev/null; then
    OCLI_PATH="ocli"
    cyan "Found OCLI in PATH. It will be used for definitions gathering."
  else
    yellow "OCLI path not provided. Definitions gathering will be skipped."
    SKIP_DEFS=true
  fi
fi

cyan "Gathering logs from namespace: $NAMESPACE"

mkdir logs

# Fetch the list of pods in the specified namespace
PODS=$(kubectl get pods --namespace "$NAMESPACE" --no-headers -o custom-columns=":metadata.name") -l prometheus

# Iterate over each pod
for POD in $PODS
do

  # Fetch the list of containers within the pod
  CONTAINERS=$(kubectl get pods "$POD" --namespace "$NAMESPACE" --no-headers -o jsonpath='{.spec.containers[*].name}')


  # Iterate over each container in the pod
  for CONTAINER in $CONTAINERS
  do
    # Skip audit-log-sidecar
    if [[ "$POD" == *audit* && "$CONTAINER" == "audit-log-sidecar" ]]; then
      continue
    fi

    CONTAINER_FOLDER="${POD}_${CONTAINER}"
    mkdir -p logs/"$CONTAINER_FOLDER"

    # Copy logs
    if [[ "$POD" == *audit* && "$CONTAINER" == "error-log-sidecar" ]]; then
      kubectl cp "$NAMESPACE/$POD":opt/app/audit/errors.json logs/"$CONTAINER_FOLDER"/errors.json -c "$CONTAINER"
    else
      kubectl cp "$NAMESPACE/$POD":opt/app/stdlist logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
    fi

    # Fetch the log file from the container and copy it to log folder
    kubectl cp "$NAMESPACE/$POD":opt/app/stdlist logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
    # Fetch the metrics of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$NAMESPACE" -- curl -sSk https://localhost:8443/q/metrics > logs/"$CONTAINER_FOLDER"/metrics.log
    # Fetch the health of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$NAMESPACE" -- curl -sSk https://localhost:8443/q/health > logs/"$CONTAINER_FOLDER"/health.log
  done
done
cyan "Finished gathering logs from all pods and containers in namespace $NAMESPACE."
cyan "Compressing logs into data-gather.zip file."
#Zip the logs
zip -r data-gather.zip logs
exitCode=$?
if [ $exitCode -ne 0 ]; then
  red "Failed to create data-gather.zip. Please check if zip is installed and try again."
  exit 1
else
  green "Created data-gather.zip containing collected logs."
fi
#Delete the logs folder
rm -rf logs

cyan "Logs gathering completed."

if [ "$SKIP_DEFS" = true ]; then
  yellow "Skipping definitions gathering."
  exit 0
fi

cyan "Gathering definitions using OCLI at $OCLI_PATH"

mkdir definitions
#Extract all the Jobs
"$OCLI_PATH" model extract definitions/allJobs.txt from jd=@/@#@/@
#Extract all the Job Streams
"$OCLI_PATH" model extract definitions/allJobStreams.txt from js=@/@#@/@
#Extract all the Workstations
"$OCLI_PATH" model extract definitions/allWorkstations.txt from ws=@/@
#Extract all the Users
"$OCLI_PATH" model extract definitions/allUsers.txt from user=@/@#@
#Extract all the Calenders
"$OCLI_PATH" model extract definitions/allCalendar.txt from cal=@/@
#Extract all the Folders
"$OCLI_PATH" model extract definitions/allFolders.txt from fol=@/@
#Extract all the Access Control List
"$OCLI_PATH" model extract definitions/allACL.txt from acl=@
#Extract all the Security Roles
"$OCLI_PATH" model extract definitions/allRoles.txt from srol=@
#Extract all the Variable Table
"$OCLI_PATH" model extract definitions/allVariableTables.txt from vt=@/@
#Extract all the API Keys
"$OCLI_PATH" model extract definitions/allAPIKeys.txt from api=@
#Extract all the event sources
"$OCLI_PATH" model extract definitions/allEventSources.txt from eventsource=@/@
#Extract all the resources
"$OCLI_PATH" model extract definitions/allResources.txt from res=@/@
#Extract all the human task queues
"$OCLI_PATH" model extract definitions/allHumanTaskQueues.txt from htq=@/@
#Extract all AI Agents
"$OCLI_PATH" model extract definitions/allAIAgents.txt from aiagent=@/@
#Extract all Endpoints
"$OCLI_PATH" model extract definitions/allEndpoints.txt from endpoints=@/@
#Extract all the run cycle groups
"$OCLI_PATH" model extract definitions/allRunCycleGroups.txt from rcg=@/@

cyan "Finished gathering definitions using OCLI."
cyan "Adding extracted definitions to data-gather.zip file..."
#Zip the definitions
zip -r data-gather.zip definitions
updateZipCode=$?
if [ $updateZipCode -ne 0 ]; then
  red "Failed to update data-gather.zip with definitions."
  exit $updateZipCode
else
  green "Added extracted definitions to data-gather.zip file."
fi
#Delete the definition folder
rm -rf definitions

cyan "Definitions gathering completed."