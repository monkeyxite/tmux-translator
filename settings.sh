default_launch_key="t"
launch_key="@tmux-translator"

default_width="60%"
width="@tmux-translator-width"

default_height="60%"
height="@tmux-translator-height"

default_from="en"
from="@tmux-translator-from"

default_to="zh"
to="@tmux-translator-to"

default_engine="trans"
engine="@tmux-translator-engine"

get_tmux_option() {
	local option="$1"
	local default_value="$2"
	local option_value=$(tmux show-option -gqv "$option")
	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

# LLM engine settings
llm_api_base="@tmux-translator-llm-api-base"
default_llm_api_base="http://127.0.0.1:8000/v1"
llm_model="@tmux-translator-llm-model"
default_llm_model="mlx-community/translategemma-4b-it-4bit"
llm_api_key_cmd="@tmux-translator-llm-api-key-cmd"
default_llm_api_key_cmd="pass show ai/omlx"
