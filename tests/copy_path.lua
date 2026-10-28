local root = vim.fn.fnamemodify(debug.getinfo(1, 'S').source:sub(2), ':p:h:h')
vim.opt.runtimepath:prepend(root)
vim.cmd 'runtime plugin/aos.lua'

local aos = require('aos')
aos.setup {
  keymaps = {
    copy_path = false,
    copy_path_with_position = false,
  },
}

assert(vim.fn.maparg('gp', 'n') == '', 'copy_path_with_position=false left gp mapped')
assert(vim.fn.maparg('gP', 'n') == '', 'copy_path=false left gP mapped')

aos.setup {}
assert(vim.fn.maparg('<leader>a', 'n') ~= '', 'default toggle keymap was not installed')
assert(vim.fn.maparg('gp', 'n') ~= '', 'default gp keymap was not installed')
assert(vim.fn.maparg('gP', 'n') ~= '', 'default gP keymap was not installed')

local path = vim.fn.tempname() .. '.lua'
vim.fn.writefile({ 'aaaa', 'bbbb', 'cccc', 'dddd' }, path)
vim.cmd.edit(vim.fn.fnameescape(path))

local abs = vim.fn.fnamemodify(path, ':p')
vim.api.nvim_win_set_cursor(0, { 2, 2 })

assert(aos.copy_path() == abs, 'copy_path did not return the absolute path')
assert(
  aos.copy_path_with_position() == string.format('%s:L2:C3', abs),
  'cursor position format was wrong'
)

vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd 'normal! v'
vim.api.nvim_win_set_cursor(0, { 2, 3 })
assert(
  aos.copy_path_with_position() == string.format('%s:L2:C1-C4', abs),
  'character visual format was wrong'
)
vim.cmd 'normal! \27'

vim.api.nvim_win_set_cursor(0, { 4, 0 })
vim.cmd 'normal! v'
vim.api.nvim_win_set_cursor(0, { 1, 1 })
assert(
  aos.copy_path_with_position() == string.format('%s:L1:C2-L4:C1', abs),
  'reversed visual range was not normalized'
)
vim.cmd 'normal! \27'

vim.api.nvim_win_set_cursor(0, { 2, 0 })
vim.cmd 'normal! Vj'
assert(
  aos.copy_path_with_position() == string.format('%s:L2-L3', abs),
  'linewise visual format was wrong'
)
vim.cmd 'normal! \27'

print 'aos.nvim copy_path test passed'
vim.cmd 'qa!'
