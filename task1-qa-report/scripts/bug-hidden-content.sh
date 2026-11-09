#!/usr/bin/env bash
# Hypothesis: articles and comments by normal (non-"demo") users are invisible to everyone else.
source "$(dirname "$0")/lib.sh"; evidence bug-hidden-content.txt
A=$(register alice); B=$(register bob)
echo "## Alice publishes an article"
req POST /articles '{"article":{"title":"Visible to all '"$RUN_ID"'","description":"d","body":"hello","tagList":["qa'"$RUN_ID"'"]}}' "$A"
SLUG="Visible-to-all-$RUN_ID"; SLUG=$(curl -s "$API/articles?author=alice_$RUN_ID" -H "Authorization: Token $A" | sed -E 's/.*"slug":"([^"]+)".*/\1/')
echo "## Alice sees it in her list (articlesCount should be 1)"
req GET "/articles?author=alice_$RUN_ID" '' "$A"
echo "## Bob (logged in) lists Alice's articles - expected 1, check articlesCount"
req GET "/articles?author=alice_$RUN_ID" '' "$B"
echo "## Anonymous visitor lists by tag - expected 1"
req GET "/articles?tag=qa$RUN_ID"
echo "## Bob opens the direct link - works"
req GET "/articles/$SLUG" '' "$B"
echo "## Bob comments on Alice's article"
req POST "/articles/$SLUG/comments" '{"comment":{"body":"Great post from Bob"}}' "$B"
echo "## Alice (the author) loads comments - expected Bob's comment"
req GET "/articles/$SLUG/comments" '' "$A"
echo "## Anonymous loads comments"
req GET "/articles/$SLUG/comments"
