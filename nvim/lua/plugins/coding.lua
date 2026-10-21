return {
  -- Автодоповнення
  {
    "saghen/blink.cmp",
    version = "1.*", -- тег релізу => готовий бінарник fuzzy-матчера, нічого не компілюємо
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "default", -- <C-y> прийняти, <C-n>/<C-p> вибір, <C-space> меню, <C-e> закрити
        ["<Tab>"] = { "select_and_accept", "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
      },
      appearance = { nerd_font_variant = "mono", use_nvim_cmp_as_default = false },
      completion = {
        documentation = { auto_show = true, auto_show_delay_ms = 300 },
        menu = { draw = { treesitter = { "lsp" } } },
        list = { selection = { preselect = true, auto_insert = false } },
      },
      signature = { enabled = true },
      sources = {
        default = { "lazydev", "lsp", "path", "snippets", "buffer" },
        providers = {
          lazydev = { name = "LazyDev", module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
      cmdline = { enabled = true },
      -- Якщо готовий бінарник недоступний — тихо використовуємо Lua-реалізацію
      fuzzy = { implementation = "prefer_rust" },
    },
  },

  -- Форматування
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd = "ConformInfo",
    keys = {
      { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, mode = { "n", "x" }, desc = "Format" },
      {
        "<leader>uf",
        function()
          vim.g.disable_autoformat = not vim.g.disable_autoformat
          vim.notify("Format on save: " .. (vim.g.disable_autoformat and "OFF" or "ON"))
        end,
        desc = "Toggle format on save",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        python = { "ruff_organize_imports", "ruff_format" },
        go = { "goimports", "gofumpt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      -- Форматування при збереженні. Вимкнути глобально: <leader>uf
      -- (на серверах часто правиш чужі конфіги — тому YAML/JSON/MD не чіпаємо автоматично)
      format_on_save = function(buf)
        if vim.g.disable_autoformat then return end
        local skip = { yaml = true, json = true, jsonc = true, markdown = true, html = true }
        if skip[vim.bo[buf].filetype] then return end
        return { timeout_ms = 1500, lsp_format = "fallback" }
      end,
      formatters = {
        shfmt = { prepend_args = { "-i", "2", "-ci" } },
      },
    },
  },
}
