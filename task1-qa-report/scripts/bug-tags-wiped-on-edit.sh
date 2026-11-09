#!/usr/bin/env bash
# Hypothesis: editing an article without resending tagList silently deletes all its tags.
source "$(dirname "$0")/lib.sh"; evidence bug-tags-wiped-on-edit.txt
A=$(register erin)
echo "## Create article with 2 tags"
req POST /articles '{"article":{"title":"Tagged '"$RUN_ID"'","description":"d","body":"v1","tagList":["keep-me","and-me"]}}' "$A"
SLUG="Tagged-$RUN_ID"; SLUG=$(curl -s "$API/articles?author=erin_$RUN_ID" -H "Authorization: Token $A" | sed -E 's/.*"slug":"([^"]+)".*/\1/')
echo "## Fix a typo in the body only (spec: fields not sent stay unchanged)"
req PUT "/articles/$SLUG" '{"article":{"body":"v2 - typo fixed"}}' "$A"
echo "## Re-read the article: tagList should still be [keep-me, and-me]"
req GET "/articles/$SLUG" '' "$A"
