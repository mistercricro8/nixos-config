# VSCode setup

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
      #github.copilot-chat
    ]
    ++ [
      pkgs.vscode-marketplace-release.catppuccin.catppuccin-vsc
      pkgs.vscode-marketplace-release.github.copilot-chat
      #(pkgs.forVSCodeVersion pkgs.vscode.version).vscode-marketplace-release.github.copilot-chat
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
      myriad-dreamin.tinymist # bleh!
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
  programs.vscode = {
    enable = true;
    mutableExtensionsDir = false;
    #package = (pkgs.vscode.override { isInsiders = true; }).overrideAttrs (old: {
    #  pname = "vscode-insiders";
    #  version = "1.107.0";
    #  src = inputs.vscode-insiders;
    #  unpackPhase = ''
    #    runHook preUnpack
    #    tar -xf $src
    #    sourceRoot="VSCode-linux-x64"
    #    runHook postUnpack
    #  '';
    #  buildInputs = old.buildInputs ++ [ pkgs.krb5 ];
    #});
  };

  home.packages = with pkgs; [
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
  ];

  # waiting for the day vscode adds global settings like please can we stop setting configuration stuff in the same json file where we cache data
  # specifically the userDataProfiles key under User/globalStorage/storage.json, it would really be nice to be able to set profile content sources somewhere else
  programs.vscode.profiles = {
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
}
