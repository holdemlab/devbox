-- nvim-treesitter (гілка main) потребує:
--   * Neovim 0.12+
--   * tree-sitter CLI (install.sh ставить офіційний бінарник або сумісний shim)
--   * C-компілятор (cc/gcc/clang). Якщо компілятора немає — парсери не
--     ставляться, а підсвітка працює на вбудованих regex-синтаксисах Vim.

local parsers = {
  "bash", "python", "go", "gomod", "gosum", "gowork",
  "javascript", "typescript", "tsx", "html", "css",
  "json", "yaml", "toml", "dockerfile", "make", "ini",
  "lua", "luadoc", "vim", "vimdoc", "query", "regex",
  "markdown", "markdown_inline", "diff",
  "git_config", "gitcommit", "gitignore", "git_rebase",
  "nginx", "sql", "xml",
}

-- Мови, де treesitter-відступи ще сирі — лишаємо стандартні
local no_ts_indent = { yaml = true, python = true, markdown = true, html = true }

local function can_build()
  if vim.fn.executable("tree-sitter") ~= 1 then return false end
  for _, cc in ipairs({ vim.env.CC or "", "cc", "gcc", "clang" }) do
    if cc ~= "" and vim.fn.executable(cc) == 1 then return true end
  end
  return false
end

return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    lazy = false,
    cond = vim.fn.has("nvim-0.12") == 1,
    build = function()
      if can_build() then vim.cmd("TSUpdate") end
    end,
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup({})

      -- Доставити відсутні парсери (асинхронно, не блокує редактор)
      if can_build() and #vim.api.nvim_list_uis() > 0 then
        local installed = {}
        for _, l in ipairs(ts.get_installed()) do installed[l] = true end
        local missing = vim.tbl_filter(function(l) return not installed[l] end, parsers)
        if #missing > 0 then ts.install(missing) end
      end

      -- Синхронне встановлення всіх парсерів (використовує install.sh у headless-режимі)
      vim.api.nvim_create_user_command("TSInstallMineSync", function()
        if not can_build() then
          print("treesitter: no tree-sitter CLI or C compiler, skipping parsers")
          return
        end
        ts.install(parsers):wait(15 * 60 * 1000)
        local have = {}
        for _, l in ipairs(ts.get_installed()) do have[l] = true end
        local missing = vim.tbl_filter(function(l) return not have[l] end, parsers)
        if #missing > 0 then
          io.stderr:write("treesitter: not installed: " .. table.concat(missing, ", ") .. "\n")
          vim.cmd("cquit 1")
        end
      end, { desc = "Install configured treesitter parsers (blocking)" })

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("user_treesitter", { clear = true }),
        callback = function(ev)
          if not pcall(vim.treesitter.start, ev.buf) then return end
          local ft = vim.bo[ev.buf].filetype
          if not no_ts_indent[ft] then
            vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
          vim.wo.foldmethod = "expr"
          vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.wo.foldlevel = 99
        end,
      })
    end,
  },
}
