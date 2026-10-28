local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-tabs; sleep 10' }

local aos = require('aos')
aos.setup {
  command = command,
  window = {
    side = 'left',
    width = 0.35,
  },
}

local aos_buf
local aos_win
local first_tab
local second_tab
local second_win

vim.cmd 'tabnew | tabonly'
first_tab = vim.api.nvim_get_current_tabpage()

-- toggle in a second tab open aos there
aos.open()
aos_buf = vim.api.nvim_get_current_buf()
aos_win = vim.api.nvim_get_current_win()

vim.cmd 'stopinsert'
vim.cmd 'wincmd p'

vim.cmd 'tabnew'
second_tab = vim.api.nvim_get_current_tabpage()
aos.toggle()

assert(vim.api.nvim_get_current_tabpage() == second_tab, 'current tab changed after toggling the agent')
assert(vim.api.nvim_get_current_buf() == aos_buf, 'toggle in second tab did not show the agent buffer')
assert(vim.api.nvim_win_is_valid(aos_win), 'agent win is not valid anymore after toggling in second tab')

-- hide removes agent from every tab
aos.hide()
assert(vim.api.nvim_get_current_tabpage() == second_tab, 'current tab changed after hiding the agent')
assert(vim.api.nvim_buf_is_valid(aos_buf), 'agent buffer is not valid after hiding')
assert(#vim.fn.win_findbuf(aos_buf) == 0, 'agent buffer is still shown in a window')

-- resize while hidden in this tab
vim.o.columns = 150
vim.v.errmsg = ''
vim.api.nvim_exec_autocmds('VimResized', {})
assert(vim.v.errmsg == '', 'VimResized error:' .. vim.v.errmsg)

aos.open()
second_win = vim.api.nvim_get_current_win()
assert(vim.api.nvim_win_get_width(second_win) == math.floor(vim.o.columns * 0.35), 'agent did not resize')

-- prev window across tabs
vim.cmd 'wincmd p'
vim.cmd 'tabprevious'
aos.hide()
assert(vim.api.nvim_get_current_tabpage() == first_tab, 'did not stay in same tab after hiding')

print('aos.nvim tabs test passed')
vim.cmd 'qa!'
