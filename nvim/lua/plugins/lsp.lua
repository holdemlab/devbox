-- LSP: Mason ставить сервери в ~/.local/share/nvim/mason (без sudo).
-- Сервери, яким потрібні node/go, додаються лише якщо node/go є в PATH.

local has = function(bin) return vim.fn.executable(bin) == 1 end

local function wanted_tools()
  local tools = {
    -- LSP
    "lua-language-server",
    "ruff", -- python: лінтер + форматер + LSP
    -- форматери / лінтери
    "stylua",
    "shfmt",
    "shellcheck",
  }
  if has("npm") then
    vim.list_extend(tools, {
      "bash-language-server",
      "yaml-language-server",
      "json-lsp",
      "dockerfile-language-server",
      "docker-compose-language-service",
      "pyright",
      "typescript-language-server",
      "html-lsp",
      "css-lsp",
      "prettier",
    })
  end
  if has("go") then
    vim.list_extend(tools, { "gopls", "goimports", "gofumpt" })
  end
  return tools
end

return {
  -- Підказки для Lua API Neovim (для редагування самого конфігу)
  { "folke/lazydev.nvim", ft = "lua", opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } } },

  -- JSON/YAML схеми (docker-compose, k8s, GitHub Actions, ...)
  { "b0o/SchemaStore.nvim", lazy = true, version = false },

  {
    "mason-org/mason.nvim",
    cmd = { "Mason", "MasonInstall", "MasonUpdate" },
    opts = {
      ui = { border = "rounded", icons = vim.g.have_nerd_font and {} or
        { package_installed = "+", package_pending = "~", package_uninstalled = "-" } },
    },
  },

  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    dependencies = { "mason-org/mason.nvim" },
    cmd = { "MasonToolsInstall", "MasonToolsInstallSync", "MasonToolsUpdate", "MasonToolsUpdateSync" },
    event = "VeryLazy",
    opts = function()
      return { ensure_installed = wanted_tools(), run_on_start = true, start_delay = 2000 }
    end,
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason-org/mason.nvim",
      "mason-org/mason-lspconfig.nvim",
      "saghen/blink.cmp",
    },
    config = function()
      -- Можливості автодоповнення для всіх серверів
      vim.lsp.config("*", {
        capabilities = require("blink.cmp").get_lsp_capabilities(),
      })

      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            completion = { callSnippet = "Replace" },
            hint = { enable = true },
          },
        },
      })

      vim.lsp.config("jsonls", {
        before_init = function(_, cfg)
          cfg.settings = vim.tbl_deep_extend("force", cfg.settings or {}, {
            json = { schemas = require("schemastore").json.schemas(), validate = { enable = true } },
          })
        end,
      })

      vim.lsp.config("yamlls", {
        before_init = function(_, cfg)
          cfg.settings = vim.tbl_deep_extend("force", cfg.settings or {}, {
            yaml = {
              schemaStore = { enable = false, url = "" },
              schemas = require("schemastore").yaml.schemas(),
              keyOrdering = false,
              format = { enable = true },
            },
            redhat = { telemetry = { enabled = false } },
          })
        end,
      })

      vim.lsp.config("gopls", {
        settings = {
          gopls = {
            gofumpt = true,
            usePlaceholders = true,
            staticcheck = true,
            analyses = { unusedparams = true, nilness = true, unusedwrite = true },
            hints = { parameterNames = true, assignVariableTypes = true },
          },
        },
      })

      vim.lsp.config("pyright", {
        settings = {
          pyright = { disableOrganizeImports = true }, -- імпорти впорядковує ruff
          python = { analysis = { typeCheckingMode = "basic" } },
        },
      })

      -- Ruff і pyright разом: hover лишаємо pyright
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_ruff", { clear = true }),
        callback = function(ev)
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          if client and client.name == "ruff" then client.server_capabilities.hoverProvider = false end
        end,
      })

      -- mason-lspconfig v2: автоматично вмикає (vim.lsp.enable) всі сервери, встановлені Mason
      -- (stylua має LSP-режим, але форматуванням займається conform — тому виключаємо)
      require("mason-lspconfig").setup({ automatic_enable = { exclude = { "stylua" } } })

      -- Клавіші для буферів з LSP
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user_lsp_keys", { clear = true }),
        callback = function(ev)
          local function map(keys, fn, desc, mode)
            vim.keymap.set(mode or "n", keys, fn, { buffer = ev.buf, desc = "LSP: " .. desc })
          end
          local tb = function(name) return function() require("telescope.builtin")[name]() end end

          map("gd", tb("lsp_definitions"), "Go to definition")
          map("gr", tb("lsp_references"), "References")
          map("gI", tb("lsp_implementations"), "Go to implementation")
          map("gy", tb("lsp_type_definitions"), "Type definition")
          map("gD", vim.lsp.buf.declaration, "Go to declaration")
          map("K", function() vim.lsp.buf.hover() end, "Hover docs")
          map("gK", vim.lsp.buf.signature_help, "Signature help")
          map("<leader>ca", vim.lsp.buf.code_action, "Code action", { "n", "x" })
          map("<leader>cr", vim.lsp.buf.rename, "Rename symbol")
          map("<leader>ss", tb("lsp_document_symbols"), "Document symbols")
          map("<leader>sS", tb("lsp_dynamic_workspace_symbols"), "Workspace symbols")
          map("<leader>ch", function()
            vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = ev.buf }), { bufnr = ev.buf })
          end, "Toggle inlay hints")
          map("<leader>ci", "<cmd>checkhealth vim.lsp<CR>", "LSP info")
        end,
      })
    end,
  },
}
