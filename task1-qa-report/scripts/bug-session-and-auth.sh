#!/usr/bin/env bash
# Hypotheses: logout does not revoke the token; tokens live 60 days; no login rate limit.
# Also checks that IDOR protections and tampered tokens behave (expected passes).
source "$(dirname "$0")/lib.sh"; evidence bug-session-and-auth.txt
A=$(register gina); B=$(register hank)
echo "## Token lifetime (decoded JWT payload)"
echo "$A" | cut -d. -f2 | tr '_-' '/+' | base64 -d 2>/dev/null; echo
echo "## The UI's 'Log out' only deletes the token from localStorage (no API call exists)."
echo "## A copied token keeps working afterwards:"
req GET /user '' "$A" | sed -E 's/"token":"[^"]+"/"token":"<jwt>"/'
echo "## Tampered token (last char changed) - expected 401"
req GET /user '' "${A%?}x"
echo "## IDOR: Bob tries to edit / delete Alice's article - expected 403"
req POST /articles '{"article":{"title":"Owned by gina '"$RUN_ID"'","description":"d","body":"b"}}' "$A" > /dev/null
SLUG=$(curl -s "$API/articles?author=gina_$RUN_ID" -H "Authorization: Token $A" | sed -E 's/.*"slug":"([^"]+)".*/\1/')
req PUT "/articles/$SLUG" '{"article":{"body":"hacked"}}' "$B"
req DELETE "/articles/$SLUG" '' "$B"
echo "## Brute force: 30 wrong passwords in a row, then the right one"
for i in $(seq 1 30); do
  curl -s -o /dev/null -w '%{http_code} ' -X POST "$API/users/login" -H 'Content-Type: application/json' \
    -d '{"user":{"email":"gina_'"$RUN_ID"'@qa.localhost","password":"wrong'"$i"'"}}'
done; echo
req POST /users/login '{"user":{"email":"gina_'"$RUN_ID"'@qa.localhost","password":"Passw0rd!123"}}' | sed -E 's/"token":"[^"]+"/"token":"<jwt>"/'
echo "## CORS headers for a foreign origin"
curl -s -o /dev/null -D - -X OPTIONS "$API/user" -H 'Origin: https://evil.example' -H 'Access-Control-Request-Method: PUT' | grep -i '^access-control' || true
