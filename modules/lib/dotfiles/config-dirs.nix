{ lib, config, ... }:
{
  # Dynamically present all entries in definitions with type = "flake" to flake-file for flake generation
  flake-file.inputs = lib.pipe config.flake.lib.dotfiles.definitions [
    (lib.filterAttrs (_: cfg: (cfg.type or "path") == "flake"))
    (lib.mapAttrs' (name: cfg: {
      name = cfg.inputName or name;
      value = cfg.input;
    }))
  ];

  # Profile definitions mapping declaration.
  flake.lib.dotfiles.definitions = {
    scripts = {
      path = ".local/bin";
    };
    backgrounds = {
      path = ".config/backgrounds";
    };
    dms = {
      path = ".config/DankMaterialShell";
    };
    dms-gtk-3 = {
      path = ".config/gtk-3.0";
    };
    dms-gtk-4 = {
      path = ".config/gtk-4.0";
    };
    dms-kde = {
      path = ".config";
    };
    dms-qt6ct = {
      path = ".config/qt6ct";
    };
    hyprland = {
      path = ".config/hypr";
    };
    kitty = {
      path = ".config/kitty";
    };
    vscode = {
      path = ".config/Code/User";
    };
    winapps = {
      path = ".config/winapps";
    };
    xsettingsd = {
      path = ".config/xsettingsd";
    };
    yazi = {
      path = ".config/yazi";
    };
    mimeapps = {
      path = ".config";
    };
    starship = {
      path = ".config/starship";
    };
    octave = {
      path = "";
    };
    zed = {
      path = ".config/zed";
    };
    opencode = {
      path = ".config/opencode";
    };
    gemini = {
      path = ".gemini";
    };
    git = {
      path = ".config/git";
    };
    copilot = {
      path = ".copilot";
    };
    mangohud = {
      path = ".config/MangoHud";
    };
    flatpak-overrides = {
      path = ".local/share/flatpak/overrides";
      symlinkDir = true;
    };
    sioyek = {
      path = ".config/sioyek";
    };
    arduino-ide = {
      path = ".arduinoIDE";
    };
    fish = {
      path = ".config/fish";
    };
    micro = {
      path = ".config/micro";
    };
    bat = {
      path = ".config/bat";
    };
    atuin = {
      path = ".config/atuin";
    };
    imv = {
      path = ".config/imv";
    };
    icons = {
      type = "flake";
      path = ".icons";
      symlinkDir = true;
      inputName = "catppuccin-cursors";
      input = {
        url = "github:catppuccin/cursors";
        flake = false;
      };
    };
  };
}
