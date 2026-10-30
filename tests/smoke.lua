local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

assert(vim.fn.exists ':Aos' == 2, ':Aos was not registered')

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-smoke; sleep 10' }

local aos = require('aos')
aos.setup {
  command = command,
}

vim.cmd 'Aos open'
assert(vim.wait(1000, function() return vim.bo.buftype == 'terminal' end), 'terminal did not start')

local buf = vim.api.nvim_get_current_buf()
local win = vim.api.nvim_get_current_win()
assert(vim.api.nvim_win_get_config(win).relative == '', 'aos did not open in an editor split')
assert(vim.fn.maparg('<M-a>', 'n') ~= '', 'toggle keymap was not installed')
assert(vim.fn.maparg('gp', 'n') ~= '', 'gp keymap was not installed')
assert(vim.fn.maparg('gp', 'x') ~= '', 'gp visual keymap was not installed')
assert(vim.fn.maparg('gP', 'n') ~= '', 'gP keymap was not installed')
assert(vim.fn.maparg('<M-a>', 'n') ~= '', 'hide keymap was not installed')
assert(vim.fn.maparg('<M-a>', 't') ~= '', 'hide terminal keymap was not installed')

vim.cmd 'Aos hide'
assert(not vim.api.nvim_win_is_valid(win), 'hide left the split open')
assert(vim.api.nvim_buf_is_valid(buf), 'hide deleted the terminal session')

vim.cmd 'Aos open'
assert(vim.api.nvim_get_current_buf() == buf, 'open did not reuse the terminal session')
local reopened_win = vim.api.nvim_get_current_win()

vim.cmd 'Aos toggle'
assert(not vim.api.nvim_win_is_valid(reopened_win), 'toggle did not hide the split')
assert(vim.api.nvim_buf_is_valid(buf), 'toggle deleted the terminal session')

vim.api.nvim_buf_delete(buf, { force = true })
print 'aos.nvim smoke test passed'
vim.cmd 'qa!'
