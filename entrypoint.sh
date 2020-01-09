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

API_HEADER="Accept: application/vnd.github.v3+json; application/vnd.github.antiope-preview+json"
AUTH_HEADER="Authorization: token ${GITHUB_TOKEN}"

action=$(jq --raw-output .action "$GITHUB_EVENT_PATH")
number=$(jq --raw-output .pull_request.number "$GITHUB_EVENT_PATH")
label=$(jq --raw-output .label.name "$GITHUB_EVENT_PATH")

set_reviewers() {
  reviewers=''

  if [[ "$2" == "RFR" ]]; then
    # add permanent reviewer
    reviewers+="${PERMANENT_REVIEWER}"
    # add random reviewer
    IFS=',' read -ra available <<< "${AVAILABLE_REVIEWERS}"
    count=${#available[@]}
    reviewers+=",${available[RANDOM%${count}]}"

  elif [[ "$2" == "RTM" ]]; then
    reviewers+="${FINAL_REVIEWER}"
  fi
  echo "${reviewers}"
  if [[ ! -z "${reviewers}" ]]; then
    curl -sSL \
      -H "Content-Type: application/json" \
      -H "${AUTH_HEADER}" \
      -H "${API_HEADER}" \
      -X $1 \
      -d "{\"reviewers\":[\"${reviewers}\"]}" \
      "https://api.github.com/repos/${GITHUB_REPOSITORY}/pulls/${number}/requested_reviewers"
  fi
}

set_reviewers 'POST' $label
