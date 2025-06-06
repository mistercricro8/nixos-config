{
  programs.nixvim = {
    enable = true;
    opts = {
      number = true;
      shiftwidth = 2;
      completeopt = [ "menu" "menuone" "noselect" ];
      termguicolors = true;
    };
    nixpkgs = {
      config = {
        allowUnfree = true;
      };
    };
    colorschemes.catppuccin = {
      enable = true;
    };
    dependencies = {
      imagemagick.enable = true;
      chafa.enable = true;
      gcc.enable = true;
      fzf.enable = true;
      lazygit.enable = true;
      rust-analyzer.enable = true;
    };
  };
}
