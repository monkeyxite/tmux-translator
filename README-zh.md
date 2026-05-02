# tmux-translator

[![en](https://img.shields.io/badge/lang-English-blue)](README.md) [![zh](https://img.shields.io/badge/lang-中文-red)](README-zh.md)

版本：v1.1.0

Translation:
使用 tmux 翻译选中文文本，并以交互式弹出窗口显示。基于 sainnhe/tmux-translator 的分支。

![screenshot](screenshot.png)

## 功能

- 交互式弹出窗口，支持快捷键（切换、更改语言、更改引擎）
- 以下是根据您提供的四个翻译引擎的翻译结果：

根据您提供的四个翻译引擎，我将提供以下翻译：

**翻译：**

这取决于您提供的具体文本。请您提供需要翻译的原文，我才能进行准确的翻译。

---

为了更好地完成翻译，请您提供需要翻译的英文文本。
- **Source Text:**

Clean out the clutter, organize your space, and create a peaceful environment. Decluttering can be a powerful tool for reducing stress and improving your well-being. Start with a small area, like a drawer or shelf, and work your way up. Don’t be afraid to let go of items you no longer need or use.

**Translation:**
- 支持多行选择
- 引擎切换的简短别名 (g, tg, l)

## 依赖

- tmux >= 3.2
- [`trans`](https://github.com/soimort/translate-shell) — 默认引擎
- `uv` + `requests` — `google` 引擎
- `uv` + `mlx-lm` — `translategemma` 引擎 (仅 Apple Silicon)
- OpenAI 兼容 LLM 服务 — `llm` 引擎

## 安装

```tmux
set -g @plugin 'monkeyxite/tmux-translator'
```

重新加载后按 `prefix + I` 安装。

## 使用

1. 进入复制模式: `prefix + [`
2. 选择文本 (vi 模式: `v` + 移动)
3. 按 `t` — .

进入复制模式，选择文本，按下 t — 弹出翻译

### 弹窗快捷键

| 键 | 操作 |
|-----|--------|
| `q` / `Enter` | 退出 |
| `s` | 交换源/目标语言 |
| `f` | 更改源语言 |
| `t` | 更改目标语言 |
| `e` | 更改引擎 (trans/g/tg/l) |

## 引擎

| 引擎 | 别名 | 离线 | 说明 |
|--------|-------|---------|-------|
| `trans` | — | ❌ | Google 翻译 via [translate-shell](https://github.com/soimort/translate-shell)。**默认** |
| `google` | `g` | ❌ | Google 翻译 via Python |
| `translategemma` | `tg` | ✅ | [translategemma-4b](https://huggingface.co/mlx-community/translategemma-4b-it-4bit) via oMLX |
| `llm` | `l` | ✅ | 任意 OpenAI 兼容 LLM |

### 基准测试 (MacBook Pro M5 24GB, sv→en)

```
                    短文 (2词)          中等 (31词)           长文 (118词)
                    ─────────────────────────────────────────────────────────
trans            ▓▓ 0.5s              ▓▓ 0.5s              ▓▓▓ 0.8s
google           ▓▓ 0.6s              ▓ 0.3s               ▓ 0.2s
tg (oMLX)        ▓▓ 0.6s              ▓▓▓▓▓▓▓ 1.5s         ▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 4.2s
llm (gemma-26b)  ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 15s  ▓▓▓▓▓▓▓▓ 8s          ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 21s
```

主要要点：trans/google 始终约为 0.5 秒，与文本长度无关（网络限制）。tg (oMLX) 随着文本长度线性增长，短文本约为 0.6 秒，段落约为 4 秒。LLM 速度最慢，仅在需要特定模型风格时使用。

## 配置

```tmux
set -g @tmux-translator "t"              # 触发键
set -g @tmux-translator-from "auto"      # 源语言
set -g @tmux-translator-to "en"          # 目标语言
set -g @tmux-translator-engine "trans"   # 默认引擎
set -g @tmux-translator-width "60%"      # 弹窗宽度
set -g @tmux-translator-height "60%"     # 弹窗高度
```

### translategemma 设置

TG 引擎使用 translategemma-4b 引擎，通过 oMLX 进行快速离线翻译。需要一个一次性的聊天模板补丁。

1. 在 oMLX 中下载模型: `mlx-community/translategemma-4b-it-4bit`
2. 替换聊天模板:
   ```bash
   MODEL_DIR=~/.local/share/omlx/translategemma-4b-it-4bit
   cp "$MODEL_DIR/chat_template.jinja" "$MODEL_DIR/chat_template.jinja.orig"
   curl -sL https://raw.githubusercontent.com/monkeyxite/tmux-translator/master/engine/chat_template_translategemma.jinja \
     > "$MODEL_DIR/chat_template.jinja"
   ```
3. 重启 oMLX

### LLM 引擎

`llm` 引擎支持任意 OpenAI 兼容 API:

```tmux
set -g @tmux-translator-llm-api-base "http://127.0.0.1:8000/v1"
set -g @tmux-translator-llm-model "gemma-4-26b-a4b-it-4bit"
set -g @tmux-translator-llm-api-key-cmd "pass show ai/omlx"
```

## 语言代码

标准 ISO 代码: `en`, `zh`, `sv`, `de`, `fr`, `ja`, `ko`, `auto` (自动检测)。
