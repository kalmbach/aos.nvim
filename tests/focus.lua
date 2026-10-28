local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-focus; sleep 10' }

local aos = require('aos')
aos.setup {
  command = command,
}

local function reset()
  aos.hide()
  vim.cmd 'silent only'
  vim.cmd 'enew!'
end

-- hide returns to the window aos was opened from
reset()
vim.cmd 'vsplit'
local left = vim.api.nvim_get_current_win()
vim.cmd 'wincmd l'
local right = vim.api.nvim_get_current_win()
assert(left ~= right, 'layout setup failed')

vim.api.nvim_set_current_win(left)
aos.open()
local twin = vim.api.nvim_get_current_win()

vim.api.nvim_set_current_win(right)
vim.api.nvim_set_current_win(twin)
aos.hide()

local cur = vim.api.nvim_get_current_win()
assert(cur == left, 'hide went to ' .. cur .. ', expected ' .. left)

-- hide does not fail when the window aos was opened from is gone
reset()
vim.cmd 'vsplit'
left = vim.api.nvim_get_current_win()
aos.open()
local tbuf = vim.api.nvim_get_current_buf()

vim.api.nvim_win_close(left, true)
assert(not vim.api.nvim_win_is_valid(left), 'layout setup failed')
aos.hide()

cur = vim.api.nvim_get_current_win()
assert(vim.api.nvim_win_get_config(cur).relative == '', 'hide landed in a float')
assert(vim.api.nvim_win_get_buf(cur) ~= tbuf, 'hide left the terminal buffer showing')

-- hide after :only inside aos keeps the session
reset()
aos.open()
tbuf = vim.api.nvim_get_current_buf()
vim.cmd 'stopinsert'
vim.cmd 'only'
assert(#vim.api.nvim_list_wins() == 1, 'layout setup failed')

aos.hide()
cur = vim.api.nvim_get_current_win()
assert(not vim.wo[cur].winfixwidth, 'hide after :only left winfixwidth set')
assert(vim.api.nvim_win_get_buf(cur) ~= tbuf, 'hide after :only left the terminal buffer showing')
assert(vim.api.nvim_buf_is_valid(tbuf), 'hide after :only deleted the terminal session')

aos.open()
assert(vim.api.nvim_get_current_buf() == tbuf, 'open after :only started a new session')

-- :q inside aos keeps the session
reset()
aos.open()
tbuf = vim.api.nvim_get_current_buf()
vim.cmd 'stopinsert'
vim.cmd 'q'
assert(vim.api.nvim_buf_is_valid(tbuf), ':q deleted the terminal session')

aos.open()
assert(vim.api.nvim_get_current_buf() == tbuf, 'open after :q started a new session')

print 'aos.nvim focus test passed'
vim.cmd 'qa!'
