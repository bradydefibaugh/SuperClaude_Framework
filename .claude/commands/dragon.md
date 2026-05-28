---
description: Summon Storm, your dragon companion, for a status check and a word of encouragement
argument-hint: [optional message for the dragon to say]
allowed-tools: Bash(bash:*)
---

The user summoned their dragon companion. Run it and relay the result:

!`bash "${CLAUDE_PROJECT_DIR:-.}/.claude/dragon/dragon.sh" $ARGUMENTS`

Show the dragon's output above to the user exactly as printed — it is ASCII art, so
preserve it inside a code block. Then add one short, encouraging sentence about the
user's current task or repo state.
