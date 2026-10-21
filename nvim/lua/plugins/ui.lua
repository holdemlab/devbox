local icons = vim.g.have_nerd_font

return {
  -- Тема (спільна з tmux)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      auto_integrations = true,
      float = { transparent = false, solid = false },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  { "nvim-tree/nvim-web-devicons", lazy = true, enabled = icons },

  -- Статусна лінія
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = {
      options = {
        theme = "catppuccin",
        globalstatus = true,
        icons_enabled = icons,
        component_separators = icons and { left = "", right = "" } or { left = "|", right = "|" },
        section_separators = icons and { left = "", right = "" } or { left = "", right = "" },
        disabled_filetypes = { statusline = { "neo-tree" } },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = {
          {
            -- ім'я хоста: щоб завжди бачити, на якому сервері ти редагуєш
            function() return (vim.env.SSH_CONNECTION and "@" or "") .. vim.fn.hostname() end,
          },
          "encoding", "filetype",
        },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
  },

  -- Вкладки буферів
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    opts = function()
      return {
        options = {
          diagnostics = "nvim_lsp",
          always_show_bufferline = false,
          show_buffer_icons = icons,
          offsets = { { filetype = "neo-tree", text = "Files", highlight = "Directory", text_align = "left" } },
        },
        highlights = (function()
          local ok, bl = pcall(require, "catppuccin.special.bufferline")
          return ok and bl.get_theme() or nil
        end)(),
      }
    end,
  },

  -- Підказки клавіш
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "helix",
      icons = { mappings = icons },
      spec = {
        { "<leader>b", group = "buffer" },
        { "<leader>c", group = "code" },
        { "<leader>f", group = "find" },
        { "<leader>g", group = "git" },
        { "<leader>s", group = "search" },
        { "<leader>x", group = "diagnostics" },
        { "g", group = "goto" },
        { "[", group = "prev" },
        { "]", group = "next" },
      },
    },
  },

  -- Лінії відступів
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile" },
    opts = { indent = { char = "│" }, scope = { enabled = true, show_start = false, show_end = false } },
  },

  -- TODO/FIXME підсвітка
  {
    "folke/todo-comments.nvim",
    event = { "BufReadPost", "BufNewFile" },
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = { signs = icons },
    keys = {
      { "<leader>st", "<cmd>TodoTelescope<CR>", desc = "Search TODOs" },
    },
  },
}
