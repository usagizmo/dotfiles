-- キーマップの統一管理

-- 基本的なキーマップ
vim.keymap.set("i", "jk", "<Esc>")

-- Insert モードでの Emacs 風カーソル移動
vim.keymap.set("i", "<C-a>", "<Home>", { desc = "Move to beginning of line" })
vim.keymap.set("i", "<C-e>", "<End>", { desc = "Move to end of line" })
vim.keymap.set("i", "<C-f>", "<Right>", { desc = "Move forward" })
vim.keymap.set("i", "<C-b>", "<Left>", { desc = "Move backward" })
vim.keymap.set("i", "<C-n>", "<Down>", { desc = "Move down" })
vim.keymap.set("i", "<C-p>", "<Up>", { desc = "Move up" })
vim.keymap.set("i", "<C-d>", "<Del>", { desc = "Delete character" })
vim.keymap.set("i", "<C-h>", "<BS>", { desc = "Backspace" })
vim.keymap.set("i", "<C-k>", "<C-o>D", { desc = "Kill line" })

-- Neo-tree
vim.keymap.set("n", "<leader>o", "<cmd>Neotree focus<cr>", { desc = "NeoTree" })

-- Telescope
vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
vim.keymap.set("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
vim.keymap.set("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
vim.keymap.set("n", "<leader>fc", "<cmd>Telescope commands<cr>", { desc = "Commands" })
