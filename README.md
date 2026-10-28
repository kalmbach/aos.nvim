# aos.nvim

[![Tests](https://github.com/kalmbach/aos.nvim/actions/workflows/test.yml/badge.svg)](https://github.com/kalmbach/aos.nvim/actions/workflows/test.yml)

**Agent on the side.** A small Neovim plugin that runs one coding agent
(`claude` by default) in a terminal split pinned to the far left or right
edge of the screen, you can open and close the split as many times you want,
the agent keeps running in the background.

```
┌──────────┬────────┬──────────────────────┐
│          │        │                      │
│   aos    │  tree  │        buffer        │
│ (agent)  │        │                      │
│          │        │                      │
└──────────┴────────┴──────────────────────┘
```

## aos.nvim and omp.nvim

aos.nvim is a fork of [omp.nvim](https://github.com/james-yap/omp.nvim)
by James Yap and does much of the same, a persistent agent terminal, a
toggle key, and keymaps that copy file paths and positions to paste into
the agent. The difference is the window. omp.nvim shows the agent in a
**floating window** over your code, while aos.nvim gives it a **side
split** that sits next to your code.

If a floating window is what you want, use
[omp.nvim](https://github.com/james-yap/omp.nvim).

## Requirements

- Neovim 0.11 or newer
- The agent command available on `PATH` (`claude` by default)

## Installation

### `vim.pack`

```lua
vim.pack.add { 'https://github.com/kalmbach/aos.nvim' }

require('aos').setup()
```

### lazy.nvim

```lua
{
  'kalmbach/aos.nvim',
  config = function()
    require('aos').setup()
  end,
}
```

## Configuration

`setup()` takes a table that is merged with the defaults. These are the
defaults:

```lua
require('aos').setup {
  command = { 'claude' },
  keymaps = {
    toggle = '<leader>a',
    hide = '<C-q>',
    copy_path = 'gP',
    copy_path_with_position = 'gp',
  },
  window = {
    side = 'left', -- 'left' or 'right'
    width = 0.35,  -- fraction of the editor width
  },
}
```

- `command` is the agent to run, as a list (command plus arguments). It
  starts in Neovim's current working directory.
- `window.width` is a fraction of `columns`. The split in the current tab is
  resized when Neovim is resized.
- `COLORFGBG` is set from the `background` option, so the agent's colors
  match a light or dark theme.
- Set any keymap to `false` to disable it.

## Default keymaps

| Keys | Mode | What it does |
| --- | --- | --- |
| `<leader>a` | normal | Toggle the agent in the current tab |
| `<C-q>` | normal and terminal, buffer-local | Hide the agent without stopping it |
| `gp` | normal, visual | Copy the absolute file path plus cursor position or visual range to the clipboard (`+` register) |
| `gP` | normal | Copy only the absolute file path to the clipboard |
| `<C-\><C-n>` | terminal | Leave terminal mode (Neovim builtin, see `:help terminal-input`) |

`gp` and `gP` override Vim's built-in put-and-leave-cursor-after mappings.

Clipboard strings use this format so you can paste them into the agent:

- Cursor: `/abs/path/file.lua:L12:C4`
- Linewise visual (`V`): `/abs/path/file.lua:L3-L10`
- Character visual, one line: `/abs/path/file.lua:L12:C4-C20`
- Character or block visual, many lines: `/abs/path/file.lua:L3:C1-L10:C8`

## Behavior

- **One agent per Neovim.** All tabs share the same agent session.
  Toggling in a tab shows the agent there. Hiding removes it from every
  tab.
- **Hiding keeps the agent running.** So do `:q` and `:only` inside the
  agent window: the next toggle shows the same session. If the agent was
  the last window in a tab, it is swapped for an empty buffer instead of
  closing the tab.
- **When the agent exits**, its windows go away in every tab, and the
  next toggle starts a fresh session.
- **If the command is missing** from `PATH`, you get an error
  notification and nothing is left behind. The next toggle tries again.
- **Hiding returns to the window you came from**, as long as it is still
  in the current tab.

## Commands

```vim
:Aos          " Open the agent (same as :Aos open)
:Aos open     " Open or focus it
:Aos hide     " Hide it without stopping the agent
:Aos toggle   " Toggle it in the current tab
```

## Lua API

```lua
local aos = require 'aos'

aos.open()
aos.hide()
aos.toggle()
aos.copy_path()                 -- absolute path
aos.copy_path_with_position()   -- path plus :L / :C range
```

## Using it with vim-tmux-navigator

[vim-tmux-navigator](https://github.com/christoomey/vim-tmux-navigator)
moves between Neovim windows and tmux panes with `<C-h/j/k/l>`. Inside
the agent terminal these keys go to the agent, so you can't navigate out
of it without leaving terminal mode first.

vim-tmux-navigator does add terminal-mode mappings when it runs inside
tmux, but they are written for Vim's terminal. They type `<C-w>:` and
the command name as keys, and in a Neovim terminal those keys are sent
to the job. The result is the agent receiving text like
`TmuxNavigateRight` in its prompt.

The fix is to map the keys in terminal mode to `<Cmd>`, which runs the
command directly without sending anything to the agent. The mappings have
to be set after vim-tmux-navigator's plugin file has run, or its own
mappings replace yours. With lazy.nvim, the `config` function runs at
the right time:

```lua
{
  'christoomey/vim-tmux-navigator',
  config = function()
    vim.keymap.set('t', '<C-h>', '<Cmd>TmuxNavigateLeft<CR>')
    vim.keymap.set('t', '<C-j>', '<Cmd>TmuxNavigateDown<CR>')
    vim.keymap.set('t', '<C-k>', '<Cmd>TmuxNavigateUp<CR>')
    vim.keymap.set('t', '<C-l>', '<Cmd>TmuxNavigateRight<CR>')
  end,
}
```

If you'd rather define every mapping yourself, set
`vim.g.tmux_navigator_no_mappings = 1` before the plugin loads, and map
the normal-mode keys as well.

Two things to know:

- These keys no longer reach the agent. If you use `<C-l>` to clear the
  screen or `<C-h>` as backspace there, pick other keys.
- Coming back to the agent window puts you in normal mode. Press `i` to
  type to the agent again.

Run `:verbose tmap <C-h>` to check which mapping is active and where it
was set.

## Testing

The tests run in headless Neovim with no user config:

```sh
make test                                     # all tests
nvim --headless -u NONE -l tests/tabs.lua     # one test
```

The tests that start an agent use a fake one (`sleep`). Set
`AOS_NVIM_TEST_REAL=1` to run them against a real `claude`. CI runs `make test` on Neovim stable and
nightly for every push to `main` and every pull request.

## License

MIT. See [LICENSE](LICENSE). Based on omp.nvim, copyright James Yap.
