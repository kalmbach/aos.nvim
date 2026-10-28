local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

local command = vim.env.AOS_NVIM_TEST_REAL and { 'claude' }
  or { vim.o.shell, '-c', 'printf aos.nvim-pin; sleep 10' }

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
  vim.cmd 'silent only'
  vim.cmd 'enew!'
end

vim.o.columns = 200

local aos_win
local aos_pos
local aos_width
local win
local win_pos
local win_width
local expected_width
local ok

-- check aos is pinned to the left side
aos.open()
aos_win = vim.api.nvim_get_current_win()
expected_width = math.floor(vim.o.columns * 0.35)

vim.cmd 'wincmd p'
vim.cmd 'topleft vsplit'

win = vim.api.nvim_get_current_win()

ok = vim.wait(1000, function()
  return vim.fn.win_screenpos(aos_win)[2] == 1
end, 10)
assert(ok, 'aos window never moved to the left')

win_pos = vim.fn.win_screenpos(win)[2]
aos_pos = vim.fn.win_screenpos(aos_win)[2]
aos_width = vim.api.nvim_win_get_width(aos_win)
assert(vim.api.nvim_get_current_win() == win, 'aos stole the focus after the split')
assert(aos_pos == 1, 'aos did not move to the leftmost column')
assert(aos_width == expected_width, 'aos changed its configured width')
assert(win_pos == aos_pos + expected_width + 1, 'new split is not directly right of aos')

-- check aos is pinned to the right side
reset()
aos.setup {
  command = command,
  window = {
    side = 'right',
    width = 0.35,
  },
}

aos.open()
aos_win = vim.api.nvim_get_current_win()

vim.cmd 'wincmd p'
vim.cmd 'botright vsplit'

win = vim.api.nvim_get_current_win()

ok = vim.wait(1000, function()
  return vim.fn.win_screenpos(aos_win)[2] + expected_width - 1 == vim.o.columns
end, 10)
assert(ok, 'aos window never moved to the right')

win_pos = vim.fn.win_screenpos(win)[2]
win_width = vim.api.nvim_win_get_width(win)
aos_pos = vim.fn.win_screenpos(aos_win)[2]
aos_width = vim.api.nvim_win_get_width(aos_win)
assert(vim.api.nvim_get_current_win() == win, 'aos stole the focus after the split')
assert(aos_pos + expected_width - 1 == vim.o.columns, 'aos did not move to the rightmost column')
assert(aos_width == expected_width, 'aos changed its configured width')
assert(win_pos + win_width + 1 == aos_pos, 'new split is not directly left of aos')

-- check aos doesn't move or resize after split
reset()
aos.open()
aos_win = vim.api.nvim_get_current_win()
aos_pos = vim.fn.win_screenpos(aos_win)[2]
aos_width = vim.api.nvim_win_get_width(aos_win)

vim.cmd 'wincmd p'
vim.cmd 'vsplit'
vim.wait(50)

assert(vim.fn.win_screenpos(aos_win)[2] == aos_pos, 'aos changed position after split')
assert(vim.api.nvim_win_get_width(aos_win) == aos_width, 'aos changed width after split')

print('aos.nvim pin test passed')
vim.cmd 'qa!'
