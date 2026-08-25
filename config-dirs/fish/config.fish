if status is-interactive
    alias ccode="code . && exit"
    alias zzed="zeditor . && exit"
    alias nix-config="cd ~/nixos-config && zeditor . && exit"
    alias devflake-init="bash ~/nixos-config/apps/devflake-init/init.sh"
    alias relock-hypr="hyprctl --instance 0 \"keyword misc:allow_session_lock_restore 1\" && hyprctl --instance 0 'dispatch exec hyprlock'"
    alias develop-env="/home/cricro/nixos-config/apps/develop-env/develop-env.sh"
    alias nix-cleanup="nh clean all --ask"
    alias cls="clear"
    alias rebuild="bash ~/nixos-config/apps/rebuild/rebuild.sh"
    alias nix-rebuild="bash ~/nixos-config/apps/rebuild/rebuild.sh"
    alias cat="bat"
    alias rcat="bat -p"
    alias eza="eza --icons=always"
    alias ls="eza"
    alias ll="eza -l"
    alias l="eza -la"
    alias kssh="kitten ssh"
    alias k="kubectl"
    alias kbuild="kustomize build --enable-alpha-plugins --enable-exec"

    function e
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if read -z cwd < "$tmp"; and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end

    if test -d ~/.config/fish/integrations
        for f in ~/.config/fish/integrations/*.fish
            source $f
        end
    end
end
