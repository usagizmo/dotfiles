-- Neovim基本設定

-- 行番号を表示
vim.opt.number = true

-- fishシェルでaliasを使用可能にする
vim.opt.shell = "/opt/homebrew/bin/fish"

-- システムクリップボードと連携（yでコピー、pでペースト）
vim.opt.clipboard = "unnamedplus"

-- 背景色を #1a1b1b に統一（colorscheme 適用後も維持）
vim.opt.termguicolors = true
local function apply_background()
  for _, name in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn" }) do
    vim.api.nvim_set_hl(0, name, { bg = "#1a1b1b" })
  end
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("custom_background", { clear = true }),
  callback = apply_background,
})
apply_background()

