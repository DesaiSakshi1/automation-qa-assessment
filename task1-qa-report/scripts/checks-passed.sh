#!/usr/bin/env bash
# Checks that are expected to PASS (listed in report section 5).
source "$(dirname "$0")/lib.sh"; evidence checks-passed.txt
A=$(register kim); B=$(register lee)
echo "## Duplicate email / username at sign-up - expected 422"
req POST /users '{"user":{"username":"kim_'"$RUN_ID"'","email":"other_'"$RUN_ID"'@qa.localhost","password":"Passw0rd!123"}}'
req POST /users '{"user":{"username":"other_'"$RUN_ID"'","email":"kim_'"$RUN_ID"'@qa.localhost","password":"Passw0rd!123"}}'
echo "## Bob tries to delete Alice's comment - expected 403/404"
req POST /articles '{"article":{"title":"Kim post '"$RUN_ID"'","description":"d","body":"b"}}' "$A" > /dev/null
SLUG=$(curl -s "$API/articles?author=kim_$RUN_ID" -H "Authorization: Token $A" | sed -E 's/.*"slug":"([^"]+)".*/\1/')
CID=$(curl -s -X POST "$API/articles/$SLUG/comments" -H 'Content-Type: application/json' -H "Authorization: Token $A" -d '{"comment":{"body":"mine"}}' | sed -E 's/.*"id":([0-9]+).*/\1/')
req DELETE "/articles/$SLUG/comments/$CID" '' "$B"
echo "## Comment still there for its author"
req GET "/articles/$SLUG/comments" '' "$A"
echo "## Follow: Bob follows Kim, then Bob's feed - expected Kim's article"
req POST "/profiles/kim_$RUN_ID/follow" '' "$B"
req GET "/articles/feed" '' "$B" | cut -c1-200
echo "## Owner deletes own article - expected 204, then 404"
req DELETE "/articles/$SLUG" '' "$A"
req GET "/articles/$SLUG" '' "$A"
