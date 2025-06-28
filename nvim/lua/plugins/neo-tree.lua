return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    "MunifTanjim/nui.nvim",
    -- {"3rd/image.nvim", opts = {}}, -- Optional image support in preview window: See `# Preview Mode` for more information
  },
  lazy = false, -- neo-tree will lazily load itself
  ---@module "neo-tree"
  ---@type neotree.Config?
  opts = {
    commands = {
      copy_selector = function(state)
        local node = state.tree:get_node()
        local filepath = node:get_id()
        local modify = vim.fn.fnamemodify

        local vals = {
          ["file path"] = filepath,
          ["filename"] = node.name,
        }

        vim.ui.select(
          vim.tbl_keys(vals),
          { prompt = "Copy format:" },
          function(choice)
            if choice then
              local result = vals[choice]
              vim.fn.setreg("+", result)
              vim.notify("Copied: " .. result)
            end
          end
        )
      end,
    },
    window = {
      mappings = {
        ["Y"] = "copy_selector",
      },
    },
  },
}
