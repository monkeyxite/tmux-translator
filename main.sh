#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/settings.sh"

get_from() { echo "$(get_tmux_option "$from" "$default_from")"; }
get_to() { echo "$(get_tmux_option "$to" "$default_to")"; }
get_width() { echo "$(get_tmux_option "$width" "$default_width")"; }
get_height() { echo "$(get_tmux_option "$height" "$default_height")"; }
get_engine() { echo "$(get_tmux_option "$engine" "$default_engine")"; }
get_llm_base() { echo "$(get_tmux_option "$llm_api_base" "$default_llm_api_base")"; }
get_llm_model() { echo "$(get_tmux_option "$llm_model" "$default_llm_model")"; }
get_llm_key_cmd() { echo "$(get_tmux_option "$llm_api_key_cmd" "$default_llm_api_key_cmd")"; }

TMPF="/tmp/tmux-translator-input.txt"
tmux save-buffer - > "$TMPF" 2>/dev/null
[ ! -s "$TMPF" ] && cat > "$TMPF"

TEXT=$(cat "$TMPF")
[ -z "$TEXT" ] && { tmux display-message "Translator: no text selected"; exit 0; }

FROM=$(get_from)
TO=$(get_to)
ENGINE=$(get_engine)

SCRIPT="/tmp/tmux-translator-run.sh"
cat > "$SCRIPT" << 'HEREDOC'
#!/usr/bin/env bash
export PATH="$HOME/.local/bin:$PATH"
export PASSWORD_STORE_DIR="$HOME/.local/share/pass"
FROM="__FROM__"
TO="__TO__"
ENGINE="__ENGINE__"
CDIR="__CDIR__"
TEXT=$(cat /tmp/tmux-translator-input.txt)

do_translate() {
  case "$ENGINE" in
    trans)
      trans -brief :"$TO" "$TEXT" 2>/dev/null
      ;;
    google)
      local nlines
      nlines=$(printf '%s\n' "$TEXT" | wc -l | tr -d ' ')
      uv run --with requests python3 "$CDIR/engine/translator.py" --engine=google --from="$FROM" --to="$TO" "$TEXT" 2>/dev/null | tail -n +$((nlines + 1)) | grep -v '^ \*'
      ;;
    llm)
      local KEY
      KEY=$(__LLM_KEY_CMD__)
      local ESCAPED_TEXT
      ESCAPED_TEXT=$(echo "$TEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip())[1:-1])")
      curl -s __LLM_BASE__/chat/completions \
        -H "Authorization: Bearer $KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"__LLM_MODEL__\",\"messages\":[{\"role\":\"user\",\"content\":\"Translate the following to ${TO}. Only output the translation, nothing else:\\n${ESCAPED_TEXT}\"}],\"max_tokens\":500,\"temperature\":0}" 2>/dev/null \
        | python3 -c "import sys,json; print(json.load(sys.stdin)['choices'][0]['message']['content'])" 2>/dev/null
      ;;
    translategemma)
      local KEY
      KEY=$(__LLM_KEY_CMD__)
      local ESCAPED_TEXT
      ESCAPED_TEXT=$(echo "$TEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip())[1:-1])")
      local WORDS=$(echo "$TEXT" | wc -w | tr -d ' ')
      local MAX_TOK=$(( WORDS * 3 + 20 ))  # ~3 tokens/word + buffer
      curl -s __LLM_BASE__/chat/completions \
        -H "Authorization: Bearer $KEY" \
        -H "Content-Type: application/json" \
        -d "{\"model\":\"translategemma-4b-it-4bit\",\"messages\":[{\"role\":\"user\",\"content\":\"${FROM} to ${TO}: ${ESCAPED_TEXT}\"}],\"max_tokens\":${MAX_TOK},\"temperature\":0}" 2>/dev/null \
        | python3 -c "import sys,json; r=json.load(sys.stdin)['choices'][0]['message']['content']; print(r.split('<end_of_turn>')[0].strip())" 2>/dev/null
      ;;
  esac
}

show() {
  # Resolve short aliases
  case "$ENGINE" in g) ENGINE="google";; tg) ENGINE="translategemma";; l) ENGINE="llm";; esac
  tput clear
  printf '\e[1;34m 󰗊  Translate │ %s→%s │ %s\e[0m\n' "$FROM" "$TO" "$ENGINE"
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '\e[36m⟨ Source ⟩\e[0m\n'
  printf '%s\n' "$TEXT"
  printf '─────────────────────────────────────────\n'
  printf '\e[32m⟨ Translation ⟩\e[0m\n'
  do_translate
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '\e[90m [q]uit [s]wap [f]rom [t]o [e]ngine(trans/google/llm/translategemma)\e[0m\n'
}

show

while IFS= read -rsn1 key; do
  case "$key" in
    q|"") rm -f /tmp/tmux-translator-input.txt; exit 0 ;;
    s) TMP="$FROM"; FROM="$TO"; TO="$TMP"; show ;;
    f) printf '\e[33m from: \e[0m'; read -r FROM; show ;;
    t) printf '\e[33m to: \e[0m'; read -r TO; show ;;
    e) printf '\e[33m engine (trans/g/tg/l): \e[0m'; read -r ENGINE; show ;;
  esac
done
HEREDOC

LLM_BASE=$(get_llm_base)
LLM_MODEL=$(get_llm_model)
LLM_KEY_CMD=$(get_llm_key_cmd)
sed -i '' "s|__FROM__|${FROM}|;s|__TO__|${TO}|;s|__ENGINE__|${ENGINE}|;s|__CDIR__|${CURRENT_DIR}|;s|__LLM_BASE__|${LLM_BASE}|;s|__LLM_MODEL__|${LLM_MODEL}|;s|__LLM_KEY_CMD__|${LLM_KEY_CMD}|" "$SCRIPT"
chmod +x "$SCRIPT"
tmux popup -w "$(get_width)" -h "$(get_height)" -E "bash $SCRIPT"
