local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

assert(vim.fn.exists ':Aos' == 2, ':Aos was not registered')

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-split; sleep 10' }

local aos = require('aos')
aos.setup {
  command = command,
  window = {
    side = 'left',
    width = 0.35,
  },
}

vim.o.columns = 200
vim.cmd 'tabnew | tabonly'
aos.open()
assert(vim.wait(1000, function() return vim.bo.buftype == 'terminal' end), 'terminal did not start')

local win = vim.api.nvim_get_current_win()
assert(vim.api.nvim_win_get_config(win).relative == '', 'aos did not open in a left editor split')
assert(vim.fn.win_screenpos(win)[2] == 1, 'aos did not open in the leftmost column')
assert(vim.api.nvim_win_get_width(win) == math.floor(vim.o.columns * 0.35), 'aos did not take the 35% of the editor')
assert(vim.wo[win].winfixwidth == true, 'aos did not open with a fixed width on the left')

vim.o.columns = 150
vim.api.nvim_exec_autocmds('VimResized', {})
assert(vim.api.nvim_win_get_width(win) == math.floor(vim.o.columns * 0.35), 'aos did not take the 35% of the editor on resize')

aos.hide()
aos.setup {
  command = command,
  window = {
    side = 'right',
    width = 0.35,
  },
}

aos.open()
win = vim.api.nvim_get_current_win()
local width = vim.api.nvim_win_get_width(win)
assert(vim.api.nvim_win_get_config(win).relative == '', 'aos did not open in a right editor split')
assert(vim.fn.win_screenpos(win)[2] + width - 1 == vim.o.columns, 'aos did not open in the rightmost column')
assert(vim.api.nvim_win_get_width(win) == math.floor(vim.o.columns * 0.35), 'aos did not take the 35% of the editor')
assert(vim.wo[win].winfixwidth == true, 'aos did not open with a fixed width on the right')

print('aos.nvim split test passed')
vim.cmd 'qa!'
