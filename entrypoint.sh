#!/bin/bash
set -eu

# Check env variables
if [[ -z "$GITHUB_TOKEN" ]]; then
  echo "Set the GITHUB_TOKEN env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_NAME" ]]; then
  echo "Set the GITHUB_EVENT_NAME env variable."
  exit 1
fi

if [[ -z "$GITHUB_EVENT_PATH" ]]; then
  echo "Set the GITHUB_EVENT_PATH env variable."
  exit 1
fi

if [[ -z "$PERMANENT_REVIEWER" ]]; then
  echo "Set the PERMANENT_REVIEWER env variable."
  exit 1
fi

if [[ -z "$AVAILABLE_REVIEWERS" ]]; then
  echo "Set the AVAILABLE_REVIEWERS env variable."
  exit 1
fi

if [[ -z "$FINAL_REVIEWER" ]]; then
  echo "Set the FINAL_REVIEWER env variable."
  exit 1
fi

GITHUB_API_HEADER="Accept: application/vnd.github.v3+json; application/vnd.github.antiope-preview+json"
GITHUB_AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"
GITHUB_REPOSITORY_URL="https://api.github.com/repos/${GITHUB_REPOSITORY}"

event=$(jq --raw-output . "$GITHUB_EVENT_PATH")
pull_request=${event} | jq '.pull_request'
action=${event} | jq '.action' 
label=${event} | jq '.label.name'

echo ${pull_request} | jq '.state'
exit 0;

add_reviewers() {
  if [[ ! -z "$1" ]]; then
    curl -sSL \
      -H "Content-Type: application/json" \
      -H "${GITHUB_AUTH_HEADER}" \
      -H "${GITHUB_API_HEADER}" \
      -X "POST" \
      -d "{\"reviewers\":[$1]}" \
      "${GITHUB_REPOSITORY_URL}/pulls/${number}/requested_reviewers"
  fi
}

if [[ $action == "labeled" ]];then
    reviewers=""
    if [[ "$label_name" == "RFR" ]]; then
      # add permanent reviewer
      reviewers+="\"${PERMANENT_REVIEWER}\""
      # add random reviewer
      IFS=',' read -ra available <<< "${AVAILABLE_REVIEWERS}"
      count=${#available[@]}
      reviewers+=",\"${available[RANDOM%${count}]}\""

    elif [[ "$label_name" == "RTM" ]]; then
      reviewers+="\"${FINAL_REVIEWER}\""
    fi

    add_reviewers $reviewers
fi

