return {
  -- Файлове дерево
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = "Neotree",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    keys = {
      { "<leader>e", "<cmd>Neotree toggle reveal<CR>", desc = "File explorer" },
      { "<leader>E", "<cmd>Neotree float reveal<CR>", desc = "File explorer (float)" },
    },
    opts = {
      close_if_last_window = true,
      filesystem = {
        follow_current_file = { enabled = true },
        use_libuv_file_watcher = true,
        filtered_items = { hide_dotfiles = false, hide_gitignored = false, never_show = { ".git" } },
      },
      window = { width = 32, mappings = { ["<space>"] = "none", ["l"] = "open", ["h"] = "close_node" } },
      default_component_configs = vim.g.have_nerd_font and {} or {
        icon = { folder_closed = "+", folder_open = "-", folder_empty = "~", default = "*" },
        git_status = { symbols = { added = "A", modified = "M", deleted = "D", renamed = "R",
          untracked = "?", ignored = "i", unstaged = "U", staged = "S", conflict = "C" } },
      },
    },
  },

  -- Пошук: файли, текст, буфери, help...
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
        cond = function() return vim.fn.executable("make") == 1 and vim.fn.executable("cc") == 1 end,
      },
      "nvim-telescope/telescope-ui-select.nvim",
    },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
      { "<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<CR>", desc = "Find ALL files" },
      { "<leader>fr", "<cmd>Telescope oldfiles<CR>", desc = "Recent files" },
      { "<leader>fb", "<cmd>Telescope buffers sort_mru=true<CR>", desc = "Buffers" },
      { "<leader>,", "<cmd>Telescope buffers sort_mru=true<CR>", desc = "Buffers" },
      { "<leader>/", "<cmd>Telescope live_grep<CR>", desc = "Grep in project" },
      { "<leader>sg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
      { "<leader>sw", "<cmd>Telescope grep_string<CR>", desc = "Grep word under cursor" },
      { "<leader>sb", "<cmd>Telescope current_buffer_fuzzy_find<CR>", desc = "Search in buffer" },
      { "<leader>sh", "<cmd>Telescope help_tags<CR>", desc = "Help" },
      { "<leader>sk", "<cmd>Telescope keymaps<CR>", desc = "Keymaps" },
      { "<leader>sd", "<cmd>Telescope diagnostics<CR>", desc = "Diagnostics" },
      { "<leader>sr", "<cmd>Telescope resume<CR>", desc = "Resume last search" },
      { "<leader>sc", "<cmd>Telescope commands<CR>", desc = "Commands" },
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Git commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Git status" },
      { "<leader>fc", function() require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") }) end, desc = "Find config file" },
    },
    config = function()
      local telescope = require("telescope")
      local actions = require("telescope.actions")
      telescope.setup({
        defaults = {
          prompt_prefix = vim.g.have_nerd_font and "  " or "> ",
          selection_caret = vim.g.have_nerd_font and " " or "> ",
          layout_strategy = "flex",
          sorting_strategy = "ascending",
          layout_config = { prompt_position = "top" },
          file_ignore_patterns = { "%.git/", "node_modules/", "__pycache__/", "%.venv/" },
          mappings = {
            i = { ["<C-j>"] = actions.move_selection_next, ["<C-k>"] = actions.move_selection_previous },
          },
        },
        pickers = {
          find_files = { hidden = true },
        },
        extensions = {
          ["ui-select"] = { require("telescope.themes").get_dropdown() },
        },
      })
      pcall(telescope.load_extension, "fzf")
      pcall(telescope.load_extension, "ui-select")
    end,
  },

  -- Git
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      on_attach = function(buf)
        local gs = require("gitsigns")
        local function map(mode, l, r, desc) vim.keymap.set(mode, l, r, { buffer = buf, desc = desc }) end
        map("n", "]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("n", "[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        map("n", "<leader>gp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>gr", gs.reset_hunk, "Reset hunk")
        map("n", "<leader>gS", gs.stage_hunk, "Stage hunk")
        map("n", "<leader>gb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>gB", gs.blame, "Blame file")
        map("n", "<leader>gd", gs.diffthis, "Diff this")
      end,
    },
  },

  -- Навігація між панелями nvim і tmux однаковими клавішами Ctrl+h/j/k/l
  {
    "christoomey/vim-tmux-navigator",
    cmd = { "TmuxNavigateLeft", "TmuxNavigateDown", "TmuxNavigateUp", "TmuxNavigateRight" },
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<CR>", desc = "Window left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<CR>", desc = "Window down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<CR>", desc = "Window up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<CR>", desc = "Window right" },
    },
  },

  -- Автодужки
  { "windwp/nvim-autopairs", event = "InsertEnter", opts = { check_ts = true } },

  -- mini: surround (sa/sd/sr), розширені текстові об'єкти (a/i)
  {
    "nvim-mini/mini.nvim",
    version = false,
    event = "VeryLazy",
    config = function()
      require("mini.ai").setup({ n_lines = 500 })
      require("mini.surround").setup()
    end,
  },

  -- Список діагностики/посилань
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    opts = { icons = vim.g.have_nerd_font and {} or { indent = { fold_open = "v ", fold_closed = "> " } } },
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<CR>", desc = "Diagnostics (project)" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<CR>", desc = "Diagnostics (buffer)" },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<CR>", desc = "Symbols outline" },
    },
  },
}
