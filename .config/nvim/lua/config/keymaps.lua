-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Open netrw in current working directory
vim.keymap.set("n", "<leader>we", function()
  vim.cmd("Explore " .. vim.fn.getcwd())
end, { desc = "Explorer (netrw) in CWD" })
