#!/bin/bash

printUsage() {
  echo "Usage: $0 [-h | --help] [-n | --namespace <namespace>] [-o | --ocli-path <ocli-path>] [-oc | --ocli-context <context>] [-sd | --skip-defs]"
  echo "Options:"
  echo "  -h,  --help          Show this help message"
  echo "  -n,  --namespace     [Optional] Specify the K8s namespace where UNO is deployed (if omitted, it will be requested interactively)"
  echo "  -o,  --ocli-path     [Optional] Specify the path to OCLI executable to gather definitions. If not provided and not found in PATH, definitions gathering will be skipped."
  echo "  -oc, --ocli-context  [Optional] Specify the OCLI context for definitions extraction."
  echo "                       If definitions are enabled and this option is omitted, you will be asked whether to use current OCLI context or provide one."
  echo "  -sd, --skip-defs     [Optional] Skip gathering definitions from OCLI"
}

SKIP_DEFS=false

while [[ "$#" -gt 0 ]]; do
  case $1 in
    -h|--help) printUsage; exit 0 ;;
    -n|--namespace) NAMESPACE="$2"; shift ;;
    -o|--ocli-path) OCLI_PATH="$2"; shift ;;
    -oc|--ocli-context) OCLI_CONTEXT="$2"; shift ;;
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

print_ocli_command() {
  local cmd=("$@")
  local formatted
  printf -v formatted '%q ' "${cmd[@]}"
  cyan "Executing OCLI command: ${formatted% }"
}

gather_logs() {
  local namespace="$1"

  cyan "Gathering logs using kubectl context '$(kubectl config current-context)' and namespace '$namespace'"

  local pods
  pods=$(kubectl get pods --namespace "$namespace" --no-headers -o custom-columns=":metadata.name" -l prometheus)

  if [ -z "$pods" ]; then
    yellow "No pods found in namespace $namespace. Skipping logs gathering."
    return 0
  fi

  mkdir logs
  local logs_collected=false

  for pod in $pods
  do
    echo "Collecting logs from pod: $pod"
    local containers
    containers=$(kubectl get pods "$pod" --namespace "$namespace" --no-headers -o jsonpath='{.spec.containers[*].name}')

    for container in $containers
    do
      if [[ "$pod" == *audit* && "$container" == "audit-log-sidecar" ]]; then
        continue
      fi

      logs_collected=true
      local container_folder="${pod}_${container}"
      mkdir -p logs/"$container_folder"

      if [[ "$pod" == *audit* && "$container" == "error-log-sidecar" ]]; then
        kubectl cp "$namespace/$pod":opt/app/audit/errors.json logs/"$container_folder"/errors.json -c "$container"
      else
        kubectl cp "$namespace/$pod":opt/app/stdlist logs/"$container_folder"/ -c "$container"
      fi

      kubectl exec "$pod" -c "$container" --namespace "$namespace" -- curl -sSk https://localhost:8443/q/metrics > logs/"$container_folder"/metrics.log
      kubectl exec "$pod" -c "$container" --namespace "$namespace" -- curl -sSk https://localhost:8443/q/health > logs/"$container_folder"/health.log
    done
  done

  if [ "$logs_collected" = false ]; then
    yellow "No logs were collected from namespace $namespace. Skipping logs archive creation."
    rm -rf logs
    return 0
  fi

  cyan "Finished gathering logs from all pods and containers in namespace $namespace."
  cyan "Compressing logs into data-gather.zip file."
  zip -r data-gather.zip logs
  local exitCode=$?
  if [ $exitCode -ne 0 ]; then
    red "Failed to create data-gather.zip. Please check if zip is installed and try again."
    return 1
  fi

  green "Created data-gather.zip containing collected logs."
  rm -rf logs
  cyan "Logs gathering completed."
}

gather_definitions() {
  local ocli_path="$1"
  local ocli_context="$2"
  local context_args=()

  if [ -n "$ocli_context" ]; then
    context_args=(-context "$ocli_context")
    cyan "Gathering definitions using OCLI at $ocli_path with context: $ocli_context"
  else
    cyan "Gathering definitions using OCLI at $ocli_path using current context"
  fi

  mkdir definitions
  local cmd

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allJobs.txt from jd=@/@#@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allJobStreams.txt from js=@/@#@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allWorkstations.txt from ws=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allUsers.txt from user=@/@#@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allCalendar.txt from cal=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allFolders.txt from fol=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allACL.txt from acl=@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allRoles.txt from srol=@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allVariableTables.txt from vt=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allAPIKeys.txt from api=@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allEventSources.txt from eventsource=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allResources.txt from res=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allHumanTaskQueues.txt from htq=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allAIAgents.txt from aiagent=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allEndpoints.txt from endpoints=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cmd=("$ocli_path" "${context_args[@]}" model extract definitions/allRunCycleGroups.txt from rcg=@/@)
  print_ocli_command "${cmd[@]}"
  "${cmd[@]}"

  cyan "Definitions extraction completed."
  cyan "Adding extracted definitions to data-gather.zip file..."
  zip -r data-gather.zip definitions
  local updateZipCode=$?
  if [ $updateZipCode -ne 0 ]; then
    red "Failed to update data-gather.zip with definitions."
    rm -rf definitions
    return $updateZipCode
  fi

  cyan "Added extracted definitions to data-gather.zip file."
  rm -rf definitions
  green "Done."
}

prompt_ocli_context_if_needed() {
  if [ "$SKIP_DEFS" = true ] || [ -n "$OCLI_CONTEXT" ]; then
    return 0
  fi

  local max_confirmation_attempts=3
  local confirmation_attempt=1
  local use_current_context

  while [ $confirmation_attempt -le $max_confirmation_attempts ]; do
    read -r -p "Use current OCLI context for definitions extraction? [Y/n]: " use_current_context
    case "$use_current_context" in
      ""|[yY]|[yY][eE][sS])
        OCLI_CONTEXT=""
        return 0
        ;;
      [nN]|[nN][oO])
        break
        ;;
      *)
        yellow "Please answer y or n."
        ;;
    esac
    confirmation_attempt=$((confirmation_attempt + 1))
  done

  if [ $confirmation_attempt -gt $max_confirmation_attempts ]; then
    red "No valid answer provided. Exiting."
    exit 1
  fi

  local max_context_attempts=3
  local context_attempt=1
  while [ $context_attempt -le $max_context_attempts ]; do
    read -r -p "Enter OCLI context name: " OCLI_CONTEXT
    if [ -n "$OCLI_CONTEXT" ]; then
      return 0
    fi
    yellow "OCLI context cannot be empty."
    context_attempt=$((context_attempt + 1))
  done

  red "No OCLI context provided . Exiting."
  exit 1
}

check_existing_folders() {
  for folder in logs definitions; do
    if [ -d "$folder" ]; then
      yellow "Folder '$folder' already exists."
      read -r -p "Do you want to remove it before proceeding? [y/N]: " answer
      case "$answer" in
        [yY][eE][sS]|[yY])
          rm -rf "$folder"
          green "Folder '$folder' removed."
          ;;
        *)
          red "Cannot proceed with existing '$folder' folder. Remove it manually and rerun the script."
          exit 1
          ;;
      esac
    fi
  done

  if [ -f "data-gather.zip" ]; then
    yellow "File 'data-gather.zip' already exists."
    read -r -p "Do you want to remove it before proceeding? [y/N]: " answer
    case "$answer" in
      [yY][eE][sS]|[yY])
        rm -f "data-gather.zip"
        green "File 'data-gather.zip' removed."
        ;;
      *)
        red "Cannot proceed with existing 'data-gather.zip'. Remove it manually and rerun the script."
        exit 1
        ;;
    esac
  fi
}

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null
then
    red "kubectl is not installed or not found in PATH. Please install kubectl to proceed."
    exit 1
fi

magenta " ========================================== "
magenta " Universal Orchestrator Data Gather Script"
magenta " ========================================== "
echo

check_existing_folders

if [ -z "$NAMESPACE" ]; then
  MAX_NAMESPACE_ATTEMPTS=3
  CURRENT_ATTEMPT=1

  yellow "Kubernetes namespace not provided as an argument."

  while [ $CURRENT_ATTEMPT -le $MAX_NAMESPACE_ATTEMPTS ]; do
    read -r -p "Enter Kubernetes namespace: " NAMESPACE
    if [ -n "$NAMESPACE" ]; then
      break
    fi
    yellow "Namespace cannot be empty."
    CURRENT_ATTEMPT=$((CURRENT_ATTEMPT + 1))
  done

  if [ -z "$NAMESPACE" ]; then
    red "No namespace provided. Exiting."
    exit 1
  fi
fi

gather_logs "$NAMESPACE"
logGatherExitCode=$?
if [ $logGatherExitCode -ne 0 ]; then
  exit $logGatherExitCode
fi

if [ -z "$OCLI_PATH" ] && [ "$SKIP_DEFS" = false ]; then
  if command -v ocli &> /dev/null; then
    OCLI_PATH="ocli"
    cyan "Found OCLI in PATH. It will be used for definitions gathering."
  else
    yellow "OCLI path not provided and not found in path. Definitions gathering will be skipped. Add OCLI to path or provide the path to OCLI with -o or --ocli-path argument."
    SKIP_DEFS=true
  fi
fi

if [ "$SKIP_DEFS" = true ]; then
  yellow "Skipping definitions gathering."
  exit 0
fi

prompt_ocli_context_if_needed

gather_definitions "$OCLI_PATH" "$OCLI_CONTEXT"
definitionsExitCode=$?
if [ $definitionsExitCode -ne 0 ]; then
  exit $definitionsExitCode
fi