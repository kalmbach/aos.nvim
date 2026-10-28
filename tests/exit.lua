local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-exit; sleep 0.2' }

local aos = require('aos')
aos.setup {
  command = command,
  window = {
    side = 'left',
    width = 0.35,
  },
}

local function reset()
  aos.hide()
  vim.cmd 'silent tabonly'
  vim.cmd 'silent only'
  vim.cmd 'enew!'
end

vim.o.columns = 200
vim.cmd 'tabnew | tabonly'

local ok
local win
local aos_buf
local aos_win
local cur_win

-- exits while visible
reset()
vim.cmd 'vsplit'
win = vim.api.nvim_get_current_win()

aos.open()
aos_buf = vim.api.nvim_get_current_buf()
aos_win = vim.api.nvim_get_current_win()

ok = vim.wait(1000, function()
  return not vim.api.nvim_buf_is_valid(aos_buf)
end, 10)
assert(ok, 'visible aos buffer did not go away')
assert(not vim.api.nvim_win_is_valid(aos_win), 'window was not removed on exit')

cur_win = vim.api.nvim_get_current_win()
assert(cur_win == win, 'focus did not go back to the code window on exit')
assert(vim.api.nvim_win_get_config(cur_win).relative == '', 'exit landed in a float')

aos.open()
assert(vim.wait(1000, function() return vim.bo.buftype == 'terminal' end), 'terminal did not start after exit while visible')
assert(vim.api.nvim_get_current_buf() ~= aos_buf, 'open again did not create a new buffer after exit while visible')

-- exits while hidden
reset()
aos.open()
aos_buf = vim.api.nvim_get_current_buf()
aos.hide()

ok = vim.wait(1000, function()
  return not vim.api.nvim_buf_is_valid(aos_buf)
end, 10)
assert(ok, 'hidden aos buffer did not go away')

aos.open()
assert(vim.wait(1000, function() return vim.bo.buftype == 'terminal' end), 'terminal did not start after exit while hidden')
assert(vim.api.nvim_get_current_buf() ~= aos_buf, 'open again did not create a new buffer after exit while hidden')

-- exits while aos is the only window
reset()
aos.open()
aos_buf = vim.api.nvim_get_current_buf()

vim.cmd 'stopinsert'
vim.cmd 'only'

ok = vim.wait(1000, function()
  return not vim.api.nvim_buf_is_valid(aos_buf)
end, 10)
assert(ok, 'aos buffer did not go away after :only')

cur_win = vim.api.nvim_get_current_win()
assert(#vim.api.nvim_list_wins() == 1, ':only left more than one window')
assert(not vim.wo[cur_win].winfixwidth, 'agent exit after :only left winfixwidth set')
assert(vim.bo.buftype ~= 'terminal', 'the remaining window still shows a terminal')

-- exit while aos is visible in two tabs, one as the last window
reset()
aos.open()
aos_buf = vim.api.nvim_get_current_buf()
vim.cmd 'wincmd p'
vim.cmd 'tabnew'
local tab2 = vim.api.nvim_get_current_tabpage()
aos.open()
vim.cmd 'stopinsert'
vim.cmd 'only'
vim.cmd 'tabnew'

ok = vim.wait(1000, function()
  return not vim.api.nvim_buf_is_valid(aos_buf)
end, 10)
assert(ok, 'aos buffer was not closed')
assert(vim.api.nvim_tabpage_is_valid(tab2), 'agent exit closed the tab where aos was the only window')
for _, w in ipairs(vim.api.nvim_list_wins()) do
  local b = vim.api.nvim_win_get_buf(w)
  local t = vim.api.nvim_win_get_tabpage(w)
  assert(vim.bo[b].buftype ~= 'terminal', 'window ' .. w .. ' in tab ' .. t .. ' still shows a terminal')
end

print('aos.nvim exit test passed')
vim.cmd 'qa!'
