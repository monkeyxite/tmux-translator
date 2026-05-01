# tmux-translator

Translate selected text in tmux with an interactive popup. Fork of [sainnhe/tmux-translator](https://github.com/sainnhe/tmux-translator).

## Features

- Interactive popup with keybindings (swap, change language, change engine)
- 4 translation engines: `trans`, `google`, `translategemma`, `llm`
- Clean output (source text separated from translation)
- Handles multi-line selections
- Short aliases for engine switching (`g`, `tg`, `l`)

## Requirements

- tmux >= 3.2
- [`trans`](https://github.com/soimort/translate-shell) — default engine
- `uv` + `requests` — for `google` engine
- `uv` + `mlx-lm` — for `translategemma` engine (Apple Silicon only)
- OpenAI-compatible LLM server — for `llm` engine

## Installation

```tmux
set -g @plugin 'monkeyxite/tmux-translator'
```

Reload and press `prefix + I` to install.

## Usage

1. Enter copy mode: `prefix + [`
2. Select text (vi mode: `v` + movement)
3. Press `t` — popup appears with translation

### Popup keybindings

| Key | Action |
|-----|--------|
| `q` / `Enter` | Quit |
| `s` | Swap from↔to languages |
| `f` | Change source language |
| `t` | Change target language |
| `e` | Change engine (trans/g/tg/l) |

## Engines

| Engine | Alias | Speed | Backend | Offline |
|--------|-------|-------|---------|---------|
| `trans` | — | ~1s | Google Translate via [translate-shell](https://github.com/soimort/translate-shell) | ❌ |
| `google` | `g` | ~0.4s | Google Translate via Python | ❌ |
| `translategemma` | `tg` | ~8s | [translategemma-4b](https://huggingface.co/mlx-community/translategemma-4b-it-4bit) via mlx_lm | ✅ |
| `llm` | `l` | ~50s | Any OpenAI-compatible LLM | ✅ |

> **Note:** `translategemma` does not support `auto` as source language — it defaults to `en` when `auto` is set. Use explicit language codes (e.g. `sv`, `zh`, `de`) for best results.

## Configuration

```tmux
set -g @tmux-translator "t"              # trigger key
set -g @tmux-translator-from "auto"      # source language
set -g @tmux-translator-to "en"          # target language
set -g @tmux-translator-engine "trans"   # default engine
set -g @tmux-translator-width "60%"      # popup width
set -g @tmux-translator-height "60%"     # popup height
```

### LLM engine

The `llm` engine uses any OpenAI-compatible API:

```tmux
set -g @tmux-translator-llm-api-base "http://127.0.0.1:8000/v1"
set -g @tmux-translator-llm-model "gemma-4-26b-a4b-it-4bit"
set -g @tmux-translator-llm-api-key-cmd "pass show ai/omlx"
```

Works with Ollama, vLLM, OpenRouter, etc:

```tmux
set -g @tmux-translator-llm-api-base "http://127.0.0.1:11434/v1"
set -g @tmux-translator-llm-model "qwen3:8b"
set -g @tmux-translator-llm-api-key-cmd "echo ollama"
```

## Language codes

Standard ISO codes: `en`, `zh`, `sv`, `de`, `fr`, `ja`, `ko`, `auto` (auto-detect, not supported by `translategemma`).

## Changes from upstream

- 4 engines (trans, google, translategemma, llm) with short aliases
- Interactive popup with live engine/language switching
- `tmux save-buffer` instead of fragile `xargs` piping
- Fixed `NoneType` errors in `translator.py` for Google API changes
- `uv run` for Python dependency management
- Clean output: strips duplicate source text and alternatives
- Increased default popup size (60%)
