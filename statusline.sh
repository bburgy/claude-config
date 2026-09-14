#!/usr/bin/env bash
# Claude Code statusline (single line):
#   [Opus] 🤖 explore×2, plan, ⏳review +3 | 📁 my-app | 🌿 feature/auth | ███░░░░░░░ 42% | $0.08 | 🕐 7m 3s

input=$(cat)

eval "$(printf '%s' "$input" | jq -r '
  @sh "model=\(.model.display_name // "?")",
  @sh "agent=\(.agent.name // "")",
  @sh "tr=\(.transcript_path // "")",
  @sh "dir=\(.workspace.current_dir // "")",
  @sh "cost=\(.cost.total_cost_usd // 0)",
  @sh "dur=\(.cost.total_duration_ms // 0)",
  @sh "pct=\(
    (.context_window.used_percentage
     // (if (.context_window.context_window_size // 0) > 0
         then (.context_window.total_input_tokens // 0) * 100 / .context_window.context_window_size
         else 0 end))
    | floor)"
')"

cyan=$'\033[36m'; grn=$'\033[38;5;46m'; dkgrn=$'\033[38;5;28m'
yel=$'\033[33m'; wht=$'\033[37m'; mag=$'\033[35m'; bmag=$'\033[1;95m'; rst=$'\033[0m'
sep=" ${wht}|${rst} "

# ---------------------------------------------------------------- agents -----
# Scan a transcript on stdin for Agent/Task tool_use blocks -> "type<TAB>id".
scan_transcript() {
  jq -Rrn '
    inputs | fromjson?
    | select((.message.content | type) == "array") | .message.content[]
    | select(.type == "tool_use" and (.name == "Agent" or .name == "Task"))
    | [(.input.subagent_type // "general-purpose"), (.id // "")] | @tsv
  ' 2>/dev/null
}

agent_seg=""
if [ -n "$agent" ]; then
  # Running inside an agent's own session: stdin already names it.
  agent_seg=" 🤖 ${mag}${agent}${rst}"
elif [ -f "$tr" ]; then
  # Cumulative list of every agent this session spawned, chronologically.
  # Primary source: the per-agent sidecar meta files written next to the
  # transcript. O(agents) over tiny files, and agentType is already resolved
  # (the transcript omits subagent_type entirely for default-agent calls).
  pairs=""
  subdir="${tr%.jsonl}/subagents"
  if [ -d "$subdir" ]; then
    metas=()
    while IFS= read -r f; do [ -n "$f" ] && metas+=("$f"); done < <(ls -tr -- "$subdir"/*.meta.json 2>/dev/null)
    if [ "${#metas[@]}" -gt 0 ]; then
      pairs=$(jq -rn 'inputs | [(.agentType // "general-purpose"), (.toolUseId // "")] | @tsv' "${metas[@]}" 2>/dev/null)
    fi
  fi

  # Fallback for sessions with no subagents/ dir: scan the whole transcript,
  # cached by byte size. Cache hit/miss is all-or-nothing rather than
  # incremental: a size offset can land mid-line, and resuming there would
  # drop the split record. This path only runs on finished/legacy transcripts,
  # which do not grow, so the full rescan effectively never repeats.
  if [ -z "$pairs" ]; then
    size=$(wc -c < "$tr" 2>/dev/null | tr -d ' ')
    cdir="${TMPDIR:-/tmp}/cc-statusline-agents"
    cf="$cdir/$(basename "$tr").cache"
    cached=$(head -n 1 "$cf" 2>/dev/null)
    if [ -n "$size" ] && [ "$cached" = "$size" ]; then
      pairs=$(tail -n +2 "$cf" 2>/dev/null)
    else
      pairs=$(scan_transcript < "$tr")
      if mkdir -p "$cdir" 2>/dev/null; then
        { printf '%s\n' "$size"; printf '%s\n' "$pairs"; } > "$cf" 2>/dev/null
      fi
    fi
  fi

  if [ -n "$pairs" ]; then
    # In-flight = Agent tool_use ids with no tool_result yet. Anything still
    # running was started recently, so the tail is enough.
    live=$(tail -n 500 "$tr" 2>/dev/null | jq -Rrn '
      [inputs | fromjson? | select((.message.content | type) == "array") | .message.content[]] as $c
      | [$c[] | select(.type == "tool_result") | .tool_use_id] as $done
      | $c[]
      | select(.type == "tool_use" and (.name == "Agent" or .name == "Task"))
      | . as $tu
      | select(($done | index($tu.id)) == null)
      | $tu.id
    ' 2>/dev/null)

    agents=$(printf '%s\n' "$pairs" | awk -F'\t' \
      -v live="$live" -v mag="$mag" -v bmag="$bmag" -v rst="$rst" -v wht="$wht" \
      -v times="×" -v hour="⏳" '
      BEGIN {
        n = split(live, L, "\n")
        for (i = 1; i <= n; i++) if (L[i] != "") running_id[L[i]] = 1
      }
      {
        t = tolower($1)
        if (t == "" || t == "workflow-subagent") next
        cnt[t]++
        seq[t] = ++k                       # last-use order
        if ($2 != "" && ($2 in running_id)) live_name[t] = 1
      }
      END {
        m = 0
        for (t in cnt) names[++m] = t
        for (i = 2; i <= m; i++) {         # insertion sort by last use
          v = names[i]; j = i - 1
          while (j >= 1 && seq[names[j]] > seq[v]) { names[j+1] = names[j]; j-- }
          names[j+1] = v
        }
        start = (m > 4) ? m - 3 : 1
        extra = (m > 4) ? m - 4 : 0
        out = ""
        for (i = start; i <= m; i++) {
          t = names[i]
          lbl = t
          if (cnt[t] > 1) lbl = lbl times cnt[t]
          lbl = (t in live_name) ? hour bmag lbl rst : mag lbl rst
          out = out (out == "" ? "" : wht ", " rst) lbl
        }
        if (extra > 0) out = out " " wht "+" extra rst
        printf "%s", out
      }')

    [ -n "$agents" ] && agent_seg=" 🤖 ${agents}"
  fi
fi

out="${cyan}[${model%% *}]${rst}"                  # "Opus 5" -> "Opus"

out+="$agent_seg"

out+="${sep}📁 ${wht}$(basename "${dir:-$PWD}")${rst}"

if branch=$(git -C "${dir:-.}" branch --show-current 2>/dev/null) && [ -n "$branch" ]; then
  out+="${sep}🌿 ${wht}${branch}${rst}"
fi

# context bar
cells=10
case "$pct" in (*[!0-9]*|'') pct=0 ;; esac
[ "$pct" -gt 100 ] && pct=100
filled=$(( (pct * cells + 50) / 100 ))             # round to nearest cell

bar="${grn}"
for ((i = 0; i < filled; i++)); do bar+="█"; done
bar+="${dkgrn}"
for ((i = filled; i < cells; i++)); do bar+="░"; done
bar+="${rst}"

# elapsed: 12s / 7m 3s / 1h 15m
secs=$(( dur / 1000 ))
if   [ "$secs" -ge 3600 ]; then elapsed="$(( secs / 3600 ))h $(( secs % 3600 / 60 ))m"
elif [ "$secs" -ge 60 ];   then elapsed="$(( secs / 60 ))m $(( secs % 60 ))s"
else                            elapsed="${secs}s"
fi

out+="${sep}${bar} ${wht}${pct}%${rst}"
out+="${sep}${yel}\$$(printf '%.2f' "$cost")${rst}"
out+="${sep}🕐 ${wht}${elapsed}${rst}"

printf '%s' "$out"
