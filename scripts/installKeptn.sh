#!/bin/bash

LOG_LOCATION=./logs
exec > >(tee -i $LOG_LOCATION/installKeptn.log)
exec 2>&1

if [[ -z "${PLATFORM}" ]]; then
  ./gke/installOnGKE.sh
fi

if [ "$PLATFORM" == "gke" ]; then
  ./gke/installOnGKE.sh
fi

if [ "$PLATFORM" == "ocp" ]; then
  ./openshift/installOnOpenshift.sh
fi