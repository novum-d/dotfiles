# LazyVim設定
{ pkgs, ... }:
{
  programs.neovim = {
    enable = true;
    extraPackages = with pkgs; [ git ];
    extraLuaConfig = ''
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
          enabled = true,
          notify = false,
        },
        performance = {
          rtp = {
            reset_packpath = false,
            disabled_plugins = {
              "gzip",
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
