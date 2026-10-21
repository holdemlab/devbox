-- Leader має бути заданий ДО завантаження плагінів
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Іконки потребують Nerd Font у терміналі КЛІЄНТА (на твоєму ПК, не на сервері).
-- Вимкнути: export NVIM_NO_ICONS=1
vim.g.have_nerd_font = vim.env.NVIM_NO_ICONS == nil

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
