#!/usr/bin/env bash
# Storm — summonable dragon companion. Prints a speech bubble + ASCII dragon + repo status.
# Usage: dragon.sh [message for the dragon to say]
# Override the name with: export DRAGON_NAME="YourDragon"

name="${DRAGON_NAME:-Storm}"
O=$'\033[38;5;208m'; R=$'\033[0m'; B=$'\033[1m'; DIM=$'\033[2m'; GRN=$'\033[32m'

msg="$*"
branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
changes="$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')"

if [ -n "$msg" ]; then
  say="$msg"
else
  lines=(
    "Your code burns bright today!"
    "I smell a bug nearby... sniff it out."
    "Commit often; hoard your gold wisely."
    "Rawr means 'ship it' in dragon."
    "Even legends started with one line."
  )
  say="${lines[$RANDOM % ${#lines[@]}]}"
fi

# cowsay-style speech bubble sized to the message.
len=${#say}
bar="$(printf '%*s' "$((len + 2))" '' | tr ' ' '_')"
dash="$(printf '%*s' "$((len + 2))" '' | tr ' ' '-')"
printf '%s %s%s\n' "$DIM" "$bar" "$R"
printf '< %s >\n' "$say"
printf '%s %s%s\n' "$DIM" "$dash" "$R"
printf '%s        \\%s\n' "$O" "$R"
printf '%s         \\%s\n' "$O" "$R"

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
printf '%s🐉 %s%s  %s⎇ %s%s  %s%s change(s)%s\n' "$B" "$name" "$R" "$GRN" "$branch" "$R" "$DIM" "$changes" "$R"
