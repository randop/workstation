vim.opt.clipboard = "unnamedplus"

-- Enabling project specific config files
vim.o.exrc = true
vim.o.secure = true

-- ssh clipboard passthrough
-- requires vim.ui.clipboard.osc52 that is built into Neovim 0.10+
if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  vim.opt.clipboard = "" -- don't force unnamed/unnamedplus over OSC 52

  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      ["+"] = require("vim.ui.clipboard.osc52").paste("+"),
      ["*"] = require("vim.ui.clipboard.osc52").paste("*"),
    },
  }
end

-- Explicit mappings so you're not relying on 'unnamedplus'
-- (avoids tripping kitty's paste-permission popup on every internal yank)
vim.keymap.set({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
vim.keymap.set("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
