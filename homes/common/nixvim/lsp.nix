{
  programs.nixvim.plugins = {
    lspconfig.enable = true;
    lsp = {
      servers = {
        bashls.enable = true;
        cmake.enable = true;
        csharp_ls.enable = true;
        docker_compose_language_service.enable = true;
        dockerls.enable = true;
        emmet_language_server.enable = true;
        eslint.enable = true;
        hyprls.enable = true;
        java_language_server.enable = true;
        jsonls.enable = true;
        lua_ls.enable = true;
        marksman.enable = true;
        nixd.enable = true;
        perlpls.enable = true;
        ruff.enable = true;
        sqls.enable = true;
        svelte.enable = true;
        ts_ls.enable = true;
        tailwindcss.enable = true;
        ccls = {
          enable = true;
          initOptions.compilationDatabaseDirectory = "build";
        };
        clangd = {
          enable = true;
          settings = {
            settings.init_options = {
              usePlaceholders = true;
              completeUnimported = true;
              clangdFileStatus = true;
            };
            cmd = [
              "clangd"
              "--background-index"
              "--clang-tidy"
              "--header-insertion=iwyu"
              "--completion-style=detailed"
              "--function-arg-placeholders"
              "--fallback-style=llvm"
            ];
          };
        };
        rust_analyzer = {
          enable = true;
          installCargo = true;
          installRustc = true;
          settings.settings = {
            diagnostics = {
              enable = true;
              styleLints.enable = true;
            };
            files = {
              excludeDirs = [
                ".direnv"
                "rust/.direnv"
              ];
            };
            inlayHints = {
              bindingModeHints.enable = true;
              closureStyle = "rust_analyzer";
              closureReturnTypeHints.enable = "always";
              discriminantHints.enable = "always";
              expressionAdjustmentHints.enable = "always";
              implicitDrops.enable = true;
              lifetimeElisionHints.enable = "always";
              rangeExclusiveHints.enable = true;
            };
            procMacro = {
              enable = true;
            };
          };
        };
      };
    };
  };
}
