# VSCode.
{ inputs, ... }:
{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:
    let
      vm = pkgs.vscode-marketplace;

      common-pkgs =
        with pkgs.vscode-marketplace;
        [
          github.copilot
          chaitanyashahare.lazygit
          tomoki1207.pdf
          jnoortheen.nix-ide
          cweijan.vscode-mysql-client2
          mads-hartmann.bash-ide-vscode
          esbenp.prettier-vscode
          ms-azuretools.vscode-docker
          catppuccin.catppuccin-vsc-icons
        ]
        ++ [
          pkgs.vscode-marketplace-release.catppuccin.catppuccin-vsc
          pkgs.vscode-marketplace-release.github.copilot-chat
        ];

      remote-pkgs =
        common-pkgs
        ++ (with vm; [
          ms-vsliveshare.vsliveshare
          ms-vscode-remote.remote-ssh
        ]);

      web-pkgs =
        common-pkgs
        ++ (with vm; [
          ms-vscode.vscode-typescript-next
          bradlc.vscode-tailwindcss
          prisma.prisma
          dbaeumer.vscode-eslint
          visualstudioexptteam.vscodeintellicode
        ]);

      python-pkgs =
        common-pkgs
        ++ (with vm; [
          ms-python.python
          ms-python.debugpy
          charliermarsh.ruff
          detachhead.basedpyright
          ms-toolsai.jupyter
        ]);

      java-pkgs =
        common-pkgs
        ++ (with vm; [
          vscjava.vscode-java-pack
          redhat.java
          vscjava.vscode-java-debug
          vscjava.vscode-java-dependency
          vscjava.vscode-maven
        ]);

      latex-pkgs =
        common-pkgs
        ++ (with vm; [
          james-yu.latex-workshop
          myriad-dreamin.tinymist
        ]);

      cpp-pkgs =
        common-pkgs
        ++ (with vm; [
          ms-vscode.cpptools
          llvm-vs-code-extensions.vscode-clangd
        ])
        ++ [ pkgs.vscode-marketplace-release.bbenoist.doxygen ];

      go-pkgs =
        common-pkgs
        ++ (with vm; [
          golang.go
        ]);
    in
    {
      home.packages = inputs.self.lib.filterPlatformPackages pkgs (
        with pkgs;
        [
          ruff
          clang-tools
          nixd
          nixfmt
          typst
          jdk
          lazygit
          go
          shellcheck
          shfmt
        ]
      );

      programs.vscode = {
        enable = true;
        mutableExtensionsDir = false;
        profiles = {
          default.extensions = common-pkgs;
          default-remote.extensions = remote-pkgs;
          python.extensions = python-pkgs;
          python-remote.extensions = python-pkgs ++ remote-pkgs;
          web.extensions = web-pkgs;
          web-remote.extensions = web-pkgs ++ remote-pkgs;
          java.extensions = java-pkgs;
          java-remote.extensions = java-pkgs ++ remote-pkgs;
          cpp.extensions = cpp-pkgs;
          cpp-remote.extensions = cpp-pkgs ++ remote-pkgs;
          go.extensions = go-pkgs;
          go-remote.extensions = go-pkgs ++ remote-pkgs;
          latex.extensions = latex-pkgs;
          latex-remote.extensions = latex-pkgs ++ remote-pkgs;
        };
      };
    };
}
