#!/bin/bash

NAMESPACE="$1"

if [ -z "$NAMESPACE" ]; then
  echo "Please provide the namespace as an argument."
  exit 1
fi

mkdir logs

# Fetch the list of pods in the specified namespace
PODS=$(kubectl get pods --namespace "$NAMESPACE" --no-headers -o custom-columns=":metadata.name")

# Iterate over each pod
for POD in $PODS
do

  # Fetch the list of containers within the pod
  CONTAINERS=$(kubectl get pods "$POD" --namespace "$NAMESPACE" --no-headers -o jsonpath='{.spec.containers[*].name}')


  # Iterate over each container in the pod
  for CONTAINER in $CONTAINERS
  do
    # Generate a unique filename for each log file
    CONTAINER_FOLDER="${POD}_${CONTAINER}"

    # Fetch the log file from the container and copy it to log folder
    kubectl cp "$NAMESPACE/$POD":opt/app/stdlist logs/"$CONTAINER_FOLDER"/ -c "$CONTAINER"
    # Fetch the metrics of the container
    kubectl exec "$POD" -c "$CONTAINER" --namespace "$NAMESPACE" -- curl -sSk https://localhost:8443/q/metrics > logs/"$CONTAINER_FOLDER"/metrics.log
  done
done
#Zip the logs
zip -r data-gather.zip logs
#Delete the logs folder
rm -rf logs

OCLI_PATH="$2"

if [ -z "$OCLI_PATH" ]; then
  echo "Please provide the ocli path as an argument."
  exit 1
fi

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
"$OCLI_PATH" model extract definitions/allEventSources.txt from eventsource=@

#Zip the definitions
zip -r data-gather.zip definitions
#Delete the definition folder
rm -rf definitions