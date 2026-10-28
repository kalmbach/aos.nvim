local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

assert(vim.fn.exists ':Aos' == 2, ':Aos was not registered')

local aos = require('aos')
aos.setup {
  command = { 'aos-no-such-binary' },
}

local calls = {}
local original = vim.notify
vim.notify = function(msg, level, _)
  table.insert(calls, { msg = msg, level = level })
end

local before = #vim.api.nvim_list_wins()
local attempt = function(n)
  aos.open()
  assert(#vim.api.nvim_list_wins() == before, 'a window was left open')

  for _, w in ipairs(vim.api.nvim_list_wins()) do
    local b = vim.api.nvim_win_get_buf(w)
    assert(vim.bo[b].buftype ~= 'terminal', 'a terminal window is still showing')
  end

  assert(#calls == n, 'expected ' .. n .. ' notification(s), got ' .. #calls)
  assert(calls[n].level == vim.log.levels.ERROR, 'notification was not ERROR level')
end

attempt(1)
attempt(2)

vim.notify = original
print 'aos.nvim missing command test passed'
vim.cmd 'qa!'
