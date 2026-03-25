return {
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function(_, opts)
      opts.sections.lualine_z = {
        function()
          return " " .. vim.fn.getcwd()
        end,
      }
    end,
  },
}
