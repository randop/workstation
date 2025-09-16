return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      { "<leader>ff", false },
      { "<leader>fF", false },
      { "<leader>ff", LazyVim.pick("files", { root = false}), desc = "Find Files (cwd)" },
      { "<leader>fF", LazyVim.pick("files"), desc = "Find Files (Root Dir)" },
    },
  },
}
