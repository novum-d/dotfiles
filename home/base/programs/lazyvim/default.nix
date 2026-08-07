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

      local codex_panel_command = { "codex" }

      local function codex_panel_opts()
        return {
          cwd = vim.fn.getcwd(),
          win = {
            position = "right",
            width = 0.35,
            wo = {
              winfixwidth = true,
            },
          },
        }
      end

      local function toggle_codex_panel()
        if not _G.Snacks then
          require("lazy").load({ plugins = { "snacks.nvim" } })
        end
        local terminal, created = Snacks.terminal.get(codex_panel_command, codex_panel_opts())
        if not created then
          terminal:toggle()
        end
        vim.g.CodexPanelOpen = terminal:win_valid() and 1 or 0
      end

      vim.api.nvim_create_user_command("Codex", toggle_codex_panel, {
        desc = "Toggle Codex right panel",
      })
      vim.api.nvim_create_user_command("CodexToggle", toggle_codex_panel, {
        desc = "Toggle Codex right panel",
      })

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
          { import = "lazyvim.plugins.extras.lang.terraform" },
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
          {
            "folke/snacks.nvim",
            keys = {
              {
                "<leader>CC",
                toggle_codex_panel,
                desc = "Toggle Codex right panel",
                mode = { "n", "t" },
              },
            },
          },
          {
            "folke/persistence.nvim",
            event = "VimEnter",
            opts = {},
            init = function()
              -- Terminal jobs are restarted explicitly after restoring the layout.
              vim.opt.sessionoptions:remove("terminal")
            end,
            config = function(_, opts)
              local persistence = require("persistence")
              persistence.setup(opts)

              vim.api.nvim_create_autocmd("User", {
                pattern = "PersistenceLoadPost",
                callback = function()
                  if vim.g.CodexPanelOpen == 1 then
                    vim.g.CodexPanelOpen = 0
                    vim.schedule(toggle_codex_panel)
                  end
                end,
              })

              if vim.fn.argc(-1) == 0 then
                vim.schedule(function()
                  persistence.load()
                end)
              end
            end,
          },
        },
        defaults = {
          lazy = true,
          version = false,
        },
        rocks = {
          enabled = false,
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
