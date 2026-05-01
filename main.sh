#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$CURRENT_DIR/settings.sh"

get_from() { echo "$(get_tmux_option "$from" "$default_from")"; }
get_to() { echo "$(get_tmux_option "$to" "$default_to")"; }
get_width() { echo "$(get_tmux_option "$width" "$default_width")"; }
get_height() { echo "$(get_tmux_option "$height" "$default_height")"; }
get_engine() { echo "$(get_tmux_option "$engine" "$default_engine")"; }

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
FROM="__FROM__"
TO="__TO__"
ENGINE="__ENGINE__"
CDIR="__CDIR__"
TEXT=$(cat /tmp/tmux-translator-input.txt)

show() {
  tput clear
  printf '\e[1;34m 󰗊  Translate │ %s→%s │ %s\e[0m\n' "$FROM" "$TO" "$ENGINE"
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '\e[36m⟨ Source ⟩\e[0m\n'
  printf '%s\n' "$TEXT"
  printf '─────────────────────────────────────────\n'
  printf '\e[32m⟨ Translation ⟩\e[0m\n'
  /Users/ehoujin/.local/bin/uv run --with requests python3 "$CDIR/engine/translator.py" --engine="$ENGINE" --from="$FROM" --to="$TO" "$TEXT" 2>/dev/null
  printf '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
  printf '\e[90m [q]uit [s]wap [f]rom [t]o [e]ngine\e[0m\n'
}

show

while IFS= read -rsn1 key; do
  case "$key" in
    q|"") rm -f /tmp/tmux-translator-input.txt; exit 0 ;;
    s) TMP="$FROM"; FROM="$TO"; TO="$TMP"; show ;;
    f) printf '\e[33m from: \e[0m'; read -r FROM; show ;;
    t) printf '\e[33m to: \e[0m'; read -r TO; show ;;
    e) printf '\e[33m engine: \e[0m'; read -r ENGINE; show ;;
  esac
done
HEREDOC

sed -i '' "s|__FROM__|${FROM}|;s|__TO__|${TO}|;s|__ENGINE__|${ENGINE}|;s|__CDIR__|${CURRENT_DIR}|" "$SCRIPT"
chmod +x "$SCRIPT"
tmux popup -w "$(get_width)" -h "$(get_height)" -E "bash $SCRIPT"
