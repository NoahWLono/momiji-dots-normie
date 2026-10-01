# A plain Arch Linux summary in interactive terminals only.
if status is-interactive
    function fish_greeting
        if command -q fastfetch
            set -l config_dir "$HOME/.config"
            if set -q XDG_CONFIG_HOME; and test -n "$XDG_CONFIG_HOME"
                set config_dir "$XDG_CONFIG_HOME"
            end
            command fastfetch --config "$config_dir/fastfetch/config.jsonc" --logo arch
        end
    end
end
