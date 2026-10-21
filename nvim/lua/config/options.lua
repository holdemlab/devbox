local opt = vim.opt

opt.number = true
opt.relativenumber = true
opt.mouse = "a"
opt.showmode = false -- режим показує lualine
opt.termguicolors = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.wrap = false
opt.breakindent = true
opt.linebreak = true

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.shiftround = true

opt.ignorecase = true
opt.smartcase = true
opt.inccommand = "split" -- живий прев'ю для :s
opt.hlsearch = true

opt.splitright = true
opt.splitbelow = true

opt.undofile = true
opt.swapfile = false
opt.updatetime = 250
opt.timeoutlen = 400
opt.confirm = true

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
opt.fillchars = { eob = " " }
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12
opt.laststatus = 3 -- одна статусна лінія на все вікно
opt.winborder = "rounded"

-- Буфер обміну.
-- Через SSH (і в tmux) копіюємо через OSC 52: текст потрапляє в буфер
-- обміну твого локального терміналу. Вставка — з внутрішнього регістру
-- (читання OSC 52 більшість терміналів не підтримує або блокує).
vim.schedule(function()
  if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
    local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
    if ok then
      local function paste()
        return { vim.split(vim.fn.getreg('"'), "\n"), vim.fn.getregtype('"') }
      end
      vim.g.clipboard = {
        name = "OSC 52",
        copy = { ["+"] = osc52.copy("+"), ["*"] = osc52.copy("*") },
        paste = { ["+"] = paste, ["*"] = paste },
      }
    end
  end
  opt.clipboard = "unnamedplus"
end)

-- Діагностика LSP
vim.diagnostic.config({
  severity_sort = true,
  underline = { severity = vim.diagnostic.severity.ERROR },
  virtual_text = { spacing = 2, source = "if_many" },
  float = { border = "rounded", source = "if_many" },
  signs = vim.g.have_nerd_font and {
    text = {
      [vim.diagnostic.severity.ERROR] = "󰅚 ",
      [vim.diagnostic.severity.WARN] = "󰀪 ",
      [vim.diagnostic.severity.INFO] = "󰋽 ",
      [vim.diagnostic.severity.HINT] = "󰌶 ",
    },
  } or {},
})
