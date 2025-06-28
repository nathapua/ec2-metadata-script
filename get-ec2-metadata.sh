#!/bin/bash

METADATA_URL="http://169.254.169.254/latest/meta-data"
TOKEN_URL="http://169.254.169.254/latest/api/token"

get_token() {
    curl -s --retry 2 --connect-timeout 1 -X PUT "$TOKEN_URL" \
         -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"
}

fetch_metadata_key() {
    curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_URL/$1"
}

fetch_all_metadata() {
    local path="$1"
    local indent="$2"
    local list=$(curl -s -H "X-aws-ec2-metadata-token: $TOKEN" "$METADATA_URL/$path")

    while IFS= read -r item; do
        if [[ "$item" == */ ]]; then
            echo "${indent}\"${item%/}\": {"
            fetch_all_metadata "$path$item" "  $indent"
            echo "${indent}},"
        else
            value=$(fetch_metadata_key "$path$item")
            echo "${indent}\"$item\": \"${value}\","
        fi
    done <<< "$list"
}

TOKEN=$(get_token)

if [[ -z "$TOKEN" ]]; then
    echo "Unable to fetch token. Make sure you're running on EC2."
    exit 1
fi

if [[ $# -gt 0 ]]; then
    value=$(fetch_metadata_key "$1")
    if [[ -z "$value" ]]; then
        echo "Metadata key not found: $1"
        exit 2
    fi
    echo "$value"
else
    echo "{"
    fetch_all_metadata "" "  "
    echo "}"
fi

