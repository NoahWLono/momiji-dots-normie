-- User-owned additions for Caelestia's Lua configuration.
-- Authentication prompts and wallpaper rotation; no audio startup hook.
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprpolkitagent.service")
    hl.exec_cmd('fish "$HOME/.local/bin/normie-wallpaper.fish"')
end)
