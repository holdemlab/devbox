-- Бутстрап lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local out = vim.fn.system({
    "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath,
  })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Failed to clone lazy.nvim:\n", "ErrorMsg" }, { out } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = { { import = "plugins" } },
  install = { colorscheme = { "catppuccin", "habamax" } },
  checker = { enabled = false }, -- без фонових перевірок оновлень (тихо на серверах)
  change_detection = { notify = false },
  ui = { border = "rounded", icons = vim.g.have_nerd_font and {} or {
    cmd = "⌘", config = "🛠", event = "📅", ft = "📂", init = "⚙", keys = "🗝",
    plugin = "🔌", runtime = "💻", require = "🌙", source = "📄", start = "🚀",
    task = "📌", lazy = "💤 ",
  } },
  performance = {
    rtp = {
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin", "netrwPlugin" },
    },
  },
})
