#!/usr/bin/env bash
# Storm — SessionStart greeter. Prints ASCII dragon art + a tip when a session opens.
# Override the name with: export DRAGON_NAME="YourDragon"

name="${DRAGON_NAME:-Storm}"
O=$'\033[38;5;208m'; R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'

branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"

tips=(
  "Confidence first — check before you build."
  "Small commits, clear messages."
  "Verify with tests; never guess."
  "Read the error message twice."
  "Parallel reads, then act."
  "Evidence beats speculation."
)
tip="${tips[$RANDOM % ${#tips[@]}]}"

printf '%s' "$O"
cat <<'DRAGON'
              \||/
              |  @___oo
    /\  /\   / (__,,,,|
   ) /^\) ^\/ _)
   )   /^\/   _)
   )   _ /  / _)
   /\  )/\/ ||  | )_)
  <  >      |(,,) )__)
   ||      /    \)___)\
   | \____(      )___) )___
    \______(_______;;; __;;;
DRAGON
printf '%s' "$R"
printf '%s🐉 %s awakens%s  %s⎇ %s%s\n' "$B" "$name" "$R" "$DIM" "$branch" "$R"
printf '%s🔥 Tip: %s%s\n' "$DIM" "$tip" "$R"
