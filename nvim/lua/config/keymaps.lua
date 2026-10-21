local map = vim.keymap.set

-- Загальне
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "Clear search highlight" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>w<CR><Esc>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>confirm qa<CR>", { desc = "Quit all" })
map("n", "<leader>w", "<cmd>w<CR>", { desc = "Save" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- Рух по візуальних рядках при wrap
map({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
map({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Вікна: <C-h/j/k/l> обробляє vim-tmux-navigator (спільно з tmux)
map("n", "<leader>-", "<C-w>s", { desc = "Split below" })
map("n", "<leader>|", "<C-w>v", { desc = "Split right" })
map("n", "<C-Up>", "<cmd>resize +2<CR>", { desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<CR>", { desc = "Decrease height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<CR>", { desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<CR>", { desc = "Increase width" })

-- Буфери
map("n", "<S-h>", "<cmd>bprevious<CR>", { desc = "Prev buffer" })
map("n", "<S-l>", "<cmd>bnext<CR>", { desc = "Next buffer" })
map("n", "<leader>bd", function()
  local buf = vim.api.nvim_get_current_buf()
  vim.cmd("bprevious")
  pcall(vim.cmd, "confirm bdelete " .. buf)
end, { desc = "Delete buffer" })

-- Переміщення рядків
map("n", "<A-j>", "<cmd>m .+1<CR>==", { desc = "Move line down" })
map("n", "<A-k>", "<cmd>m .-2<CR>==", { desc = "Move line up" })
map("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selection down", silent = true })
map("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selection up", silent = true })

-- Відступи без втрати виділення
map("v", "<", "<gv")
map("v", ">", ">gv")

-- Вставка без перезапису регістру
map("x", "<leader>p", [["_dP]], { desc = "Paste without yank" })

-- Діагностика
map("n", "<leader>cd", vim.diagnostic.open_float, { desc = "Line diagnostics" })
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, { desc = "Next diagnostic" })
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, { desc = "Prev diagnostic" })
map("n", "<leader>xq", vim.diagnostic.setloclist, { desc = "Diagnostics → loclist" })

-- Плагін-менеджери
map("n", "<leader>L", "<cmd>Lazy<CR>", { desc = "Lazy (plugins)" })
map("n", "<leader>M", "<cmd>Mason<CR>", { desc = "Mason (LSP/tools)" })
