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

pull_request=$(jq --raw-output .pull_request "$GITHUB_EVENT_PATH")
author=$(jq --raw-output .pull_request.user.login "$GITHUB_EVENT_PATH")
state=$(jq --raw-output .pull_request.state "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
label=$(jq --raw-output .label.name "$GITHUB_EVENT_PATH")

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
    if [[ "$label" == "RFR" ]]; then
      # add permanent reviewer
      reviewers+="\"${PERMANENT_REVIEWER}\""
      # add random reviewer
      available=("${AVAILABLE_REVIEWERS}") 
      # IFS=',' read -ra available <<< "${AVAILABLE_REVIEWERS}"
 
      # remove author from available reviewers
      available=${available[@]/($author)}
      echo "${available[*]}"
      exit 0
      # remove permanent reviewer from available reviewers
      available=${available[@]/$PERMANENT_REVIEWER}
      count=${#available[@]}
      random_reviewer=${available[RANDOM%${count}]}
      reviewers+=",\"${random_reviewer}\""

    elif [[ "$label" == "RTM" ]]; then
      reviewers+="\"${FINAL_REVIEWER}\""
    fi
    echo $reviewers
    add_reviewers $reviewers
fi

