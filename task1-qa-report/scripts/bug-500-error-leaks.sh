#!/usr/bin/env bash
# Hypothesis: bad input causes 500s that return raw internal error text (Prisma / JS) to the client.
source "$(dirname "$0")/lib.sh"; evidence bug-500-error-leaks.txt
A=$(register carol); B=$(register dave)
echo "## 1. Comment on an article that does not exist (expected 404)"
req POST /articles/does-not-exist-$RUN_ID/comments '{"comment":{"body":"hi"}}' "$A"
echo "## 2. Comment request without the 'comment' wrapper (expected 422)"
req POST /articles/does-not-exist-$RUN_ID/comments '{"body":"hi"}' "$A"
echo "## 3. Favorite an article that does not exist (expected 404)"
req POST /articles/does-not-exist-$RUN_ID/favorite '' "$A"
echo "## 4. Change my email to one another user already has (expected 422 'has already been taken')"
req PUT /user '{"user":{"email":"dave_'"$RUN_ID"'@qa.localhost"}}' "$A"
echo "## 5. Create article without the 'article' wrapper (expected 422)"
req POST /articles '{"title":"x"}' "$A"
