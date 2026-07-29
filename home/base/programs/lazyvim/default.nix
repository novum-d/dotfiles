# LazyVim設定
{
  lib,
  pkgs,
  isWsl ? false,
  ...
}:
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    withRuby = true;
    withPython3 = true;
    extraPackages =
      with pkgs;
      [ git ]
      ++ lib.optionals isWsl [
        marksman
        nodejs
      ];
    initLua = ''
      ${lib.optionalString isWsl ''
        vim.g.clipboard = {
          name = "WslClipboard",
          copy = {
            ["+"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::InputEncoding = [System.Text.UTF8Encoding]::new(); Set-Clipboard -Value ([Console]::In.ReadToEnd())" },
            ["*"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::InputEncoding = [System.Text.UTF8Encoding]::new(); Set-Clipboard -Value ([Console]::In.ReadToEnd())" },
          },
          paste = {
            ["+"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); [Console]::Out.Write((Get-Clipboard -Raw).ToString().Replace(\"`r\", \"\"))" },
            ["*"] = { "powershell.exe", "-NoLogo", "-NoProfile", "-Command", "[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new(); [Console]::Out.Write((Get-Clipboard -Raw).ToString().Replace(\"`r\", \"\"))" },
          },
          cache_enabled = 0,
        }
      ''}

      -- Bootstrap lazy.nvim
      local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
      if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
          "git", "clone", "--filter=blob:none",
          "https://github.com/folke/lazy.nvim.git",
          "--branch=stable", lazypath,
        })
      end
      vim.opt.rtp:prepend(lazypath)

      require("lazy").setup({
        spec = {
          { "ellisonleao/gruvbox.nvim" },
          {
            "LazyVim/LazyVim",
            import = "lazyvim.plugins",
            opts = {
              colorscheme = "gruvbox",
            },
          },
          { import = "lazyvim.plugins.extras.util.project" },
          { import = "lazyvim.plugins.extras.lsp.neoconf" },
          { import = "lazyvim.plugins.extras.test.core" },
          { import = "lazyvim.plugins.extras.dap.core" },
          { import = "lazyvim.plugins.extras.lang.json" },
          { import = "lazyvim.plugins.extras.lang.yaml" },
          { import = "lazyvim.plugins.extras.lang.elixir" },
          { import = "lazyvim.plugins.extras.lang.markdown" },
          { import = "lazyvim.plugins.extras.lang.typescript" },
          { import = "lazyvim.plugins.extras.linting.eslint" },
          { import = "lazyvim.plugins.extras.lang.toml" },
          { import = "lazyvim.plugins.extras.lang.rust" },
          { import = "lazyvim.plugins.extras.lang.nix" },
          { import = "lazyvim.plugins.extras.lang.sql" },
          { import = "lazyvim.plugins.extras.ai.copilot" },
          { import = "lazyvim.plugins.extras.ai.copilot-chat" },
          ${lib.optionalString isWsl ''
            {
              "neovim/nvim-lspconfig",
              opts = {
                servers = {
                  marksman = {
                    mason = false,
                    cmd = { "${pkgs.marksman}/bin/marksman", "server" },
                  },
                },
              },
            },
            {
              "iamcco/markdown-preview.nvim",
              build = "rm -f app/bin/markdown-preview-linux && cd app && npm install",
              init = function()
                vim.g.mkdp_browser = "wsl-open"
              end,
            },
          ''}
          {
            "zbirenbaum/copilot.lua",
            opts = {
              copilot_model = "gpt-5.5",
            },
          },
          {
            "CopilotC-Nvim/CopilotChat.nvim",
            opts = {
              model = "gpt-5.5",
            },
          },
          { import = "plugins" },
        },
        defaults = {
          lazy = true,
          version = false,
        },
        install = {
          colorscheme = { "gruvbox", "tokyonight", "habamax" },
        },
        checker = {
          enabled = false,
          notify = false,
        },
        performance = {
          rtp = {
            reset_packpath = false,
            disabled_plugins = {
              "gzip",
              "matchit",
              "matchparen",
              "netrwPlugin",
              "tarPlugin",
              "tohtml",
              "tutor",
              "zipPlugin",
            },
          },
        },
      })

      vim.g.lazyvim_rust_diagnostics = "rust-analyzer"
      vim.api.nvim_set_keymap("i", "jj", "<esc>", { noremap = true, silent = true })
      vim.opt.spelllang = { "en", "cjk" }
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.api.nvim_set_hl(0, "SpellBad", { fg = "#669966", undercurl = true })
          vim.api.nvim_set_hl(0, "SpellCap", { fg = "#669966", undercurl = true })
          vim.api.nvim_set_hl(0, "SpellRare", { fg = "#669966", undercurl = true })
          vim.api.nvim_set_hl(0, "SpellLocal", { fg = "#669966", undercurl = true })
        end,
      })
    '';
  };
}
