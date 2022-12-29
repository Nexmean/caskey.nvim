# caskey.nvim
Declarative **cas**cade **key** mappings configuration

## ✨ Features
- Define all your keymaps as simple lua tables
- Group keymaps the way you think about them
- Modular, declarative way to define keymaps
- It's as easy to define buffer local keymaps as global
- [Which-key](https://github.com/folke/which-key.nvim) integration out of the box

## 📦 Installation

[lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  "Nexmean/caskey.nvim",
  dependencies = {
    "folke/which-key", -- optional, only if you want which-key integration
  },
}
```

[packer.nvim](https://github.com/wbthomason/packer.nvim)
```lua
use {
  "Nexmean/caskey.nvim",
  requires = {
    "folke/which-key", -- optional, only if you want which-key integration
  },
}
```

## ⚙️ Configuration

Define your keymaps:
```lua
-- user/mappings.lua
return {
  -- options are inherits so you can define most regular at the top of keymaps config
  mode = {"n", "v"},

  -- Simple keymap with `caskey.cmd` helper and mode override
  ["<Esc>"] = {act = caskey.cmd "noh", desc = "no highlight", mode = "n"},

  -- group keymaps to reuse options or just for config structuring
  {
    mode = {"i", "t", "c"},

    {
      ["<C-a>"] = {act = "<Home>"  , desc = "Beginning of line"},
      ["<C-e>"] = {act = "<End>"   , desc = "End of line"},
      ["<C-f>"] = {act = "<Right>" , desc = "Move forward"},
      ["<C-b>"] = {act = "<Left>"  , desc = "Move back"},
      -- override options
      ["<C-d>"] = {act = "<Delete>", desc = "Delete next character", mode = {"i", "c"}},
    },
  },

  -- structure your keymaps as a tree and define which-key prefixes
  ["<leader>t"] = {
    name = "tabs",

    n = {act = caskey.cmd "tabnew"                            , desc = "new tab"},
    x = {act = caskey.cmd "tabclose"                          , desc = "close tab"},
    t = {act = caskey.cmd "Telescope telescope-tabs list_tabs", desc = "list tabs"},
  },

  -- define buffer local keymaps
  ["q"] = {
    act = caskey.cmd "close",
    desc = "close window",
    buf_local = {
      caskey.ft "Outline",
      caskey.bt {"quickfix", "help"},
      -- that is equivalent to:
      {
        event = "FileType",
        pattern = "Outline",
      },
      {
        event = "BufWinEnter",
        condition = function ()
          return vim.tbl_contains({"quickfix", "help"}, vim.o.buftype)
        end
      }
    },
  },

  -- extend mode or buffer local configuration
  {
    mode = "n",
    buf_local = {{"LspAttach"}},
    ["gd"] = {act = caskey.cmd "Telescope lsp_definitions", desc = "lsp definition"},
    ["<C-s>"] = {
      act = caskey.cmd "SymbolsOutline",
      desc = "toggle outline",
      mode_extend = "v",
      buf_local_extend = {caskey.ft "Outline"},
    },
  }
}
```

And then setup them with caskey:
```lua
require("caskey").setup(require("user.mappings"))
-- or if you want which-key integration:
require("caskey.wk").setup(require("user.mappings"))
```
