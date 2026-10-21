local aug = vim.api.nvim_create_augroup("user_config", { clear = true })
local au = vim.api.nvim_create_autocmd

-- Підсвітити скопійоване
au("TextYankPost", {
  group = aug,
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Повернутися на останню позицію курсора у файлі
au("BufReadPost", {
  group = aug,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].filetype ~= "gitcommit" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Вирівняти спліти при зміні розміру терміналу / tmux-панелі
au("VimResized", { group = aug, command = "tabdo wincmd =" })

-- Відступи 4 пробіли / таби для окремих мов
au("FileType", {
  group = aug,
  pattern = { "python", "dockerfile" },
  callback = function() vim.opt_local.shiftwidth = 4; vim.opt_local.tabstop = 4; vim.opt_local.softtabstop = 4 end,
})
au("FileType", {
  group = aug,
  pattern = { "go", "make" },
  callback = function() vim.opt_local.expandtab = false; vim.opt_local.shiftwidth = 4; vim.opt_local.tabstop = 4 end,
})

-- Перенос рядків для тексту
au("FileType", {
  group = aug,
  pattern = { "markdown", "gitcommit", "text" },
  callback = function() vim.opt_local.wrap = true; vim.opt_local.spell = false end,
})

-- Закривати службові вікна клавішею q
au("FileType", {
  group = aug,
  pattern = { "help", "qf", "lspinfo", "checkhealth", "man", "notify" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = ev.buf, silent = true })
  end,
})

-- Типові серверні файли
vim.filetype.add({
  filename = {
    ["docker-compose.yml"] = "yaml.docker-compose",
    ["docker-compose.yaml"] = "yaml.docker-compose",
    ["compose.yml"] = "yaml.docker-compose",
    ["compose.yaml"] = "yaml.docker-compose",
  },
  pattern = {
    [".*/%.env%..*"] = "sh",
    [".*%.env"] = "sh",
    [".*/nginx/.*%.conf"] = "nginx",
    [".*/systemd/.*%.service"] = "systemd",
  },
})
