#!/usr/bin/env bash
# Storm — dragon status line companion for Claude Code.
# Reads the status JSON from stdin and prints a single status line.
# Override the name with: export DRAGON_NAME="YourDragon"

name="${DRAGON_NAME:-Storm}"
input="$(cat)"

# Pull everything we need in one jq pass (tab-separated; paths may contain spaces).
IFS=$'\t' read -r model dir branch ctx < <(
  printf '%s' "$input" | jq -r '
    [ (.model.display_name // "Claude"),
      (.workspace.current_dir // .cwd // "."),
      (.worktree.branch // "-"),
      (.context_window.used_percentage // -1)
    ] | @tsv' 2>/dev/null
)
: "${model:=Claude}" "${dir:=.}" "${branch:=-}" "${ctx:=-1}"

dir_name="$(basename "$dir")"

R=$'\033[0m'; O=$'\033[38;5;208m'; CYN=$'\033[36m'; GRN=$'\033[32m'; MAG=$'\033[35m'; DIM=$'\033[2m'

# Storm's mood tracks how full the context window is.
mood="(•̀ᴗ•́)"      # energetic
ctxstr=""
ci="${ctx%.*}"
if [[ "$ci" =~ ^[0-9]+$ ]]; then
  if   [ "$ci" -ge 80 ]; then mood="(-.-)zZ"   # full / sleepy
  elif [ "$ci" -ge 50 ]; then mood="(◔ᴥ◔)"     # content
  fi
  ctxstr=" ${ci}%"
fi

out="${O}🐉 ${name}${R}"
out+=" ${DIM}·${R} ${CYN}${model}${R}"
out+=" ${DIM}·${R} 📂 ${dir_name}"
[ -n "$branch" ] && [ "$branch" != "-" ] && out+=" ${DIM}·${R} ${GRN}⎇ ${branch}${R}"
out+=" ${DIM}·${R} ${MAG}${mood}${R}${DIM}${ctxstr}${R}"

printf '%s\n' "$out"
