#!/usr/bin/env bash
# Hypothesis: sign-up and article input are barely validated.
source "$(dirname "$0")/lib.sh"; evidence bug-weak-validation.txt
echo "## 1. Sign up with an invalid email and a 1-character password (expected 422)"
req POST /users '{"user":{"username":"weak_'"$RUN_ID"'","email":"not-an-email-'"$RUN_ID"'","password":"1"}}'
A=$(register frank)
echo "## 2. Article whose title is only spaces (expected 422 can't be blank)"
req POST /articles '{"article":{"title":"     ","description":"d","body":"b"}}' "$A"
echo "## 3. Title made only of punctuation - two different titles"
req POST /articles '{"article":{"title":"!!!","description":"d","body":"b"}}' "$A"
req POST /articles '{"article":{"title":"???","description":"d","body":"b"}}' "$A"
echo "## 4. 20,000-character title (expected a length limit)"
LONG=$(printf 'A%.0s' $(seq 1 20000))
req POST /articles '{"article":{"title":"'"$LONG"'","description":"d","body":"b"}}' "$A" | cut -c1-400
echo "## Non-Latin titles: see bug-non-latin-titles.mjs (Node, so UTF-8 is sent correctly on Windows)"
