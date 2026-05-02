#!/usr/bin/env python3
"""Translate text using translategemma via mlx_lm directly."""
import sys
import os
os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"
os.environ["TOKENIZERS_PARALLELISM"] = "false"

def translate(text, source="auto", target="en"):
    from mlx_lm import load, generate
    model, tokenizer = load("mlx-community/translategemma-4b-it-4bit")
    messages = [{"role": "user", "content": [
        {"type": "text", "source_lang_code": source, "target_lang_code": target, "text": text}
    ]}]
    prompt = tokenizer.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
    result = generate(model, tokenizer, prompt=prompt, max_tokens=500)
    # Strip repeated end_of_turn tokens
    return result.split("<end_of_turn>")[0].strip()

if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("text", nargs="+")
    p.add_argument("--from", dest="src", default="auto")
    p.add_argument("--to", dest="tgt", default="en")
    args = p.parse_args()
    print(translate(" ".join(args.text), args.src, args.tgt))
