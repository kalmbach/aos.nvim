local M = {}

local defaults = {
  command = { 'claude' },
  keymaps = {
    toggle = '<M-a>',
    copy_path = 'gP',
    copy_path_with_position = 'gp',
  },
  window = {
    side = 'left',
    width = 0.35,
  },
}

local config = vim.deepcopy(defaults)
local state = {
  buf = nil,
  view = nil,
  terminal_normal = false,
  prev_win = nil,
}

local function agent_buf()
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    return state.buf
  end
end

local function agent_win()
  if not agent_buf() then return end
  for _, w in ipairs(vim.fn.win_findbuf(state.buf)) do
    if vim.api.nvim_win_get_tabpage(w) == vim.api.nvim_get_current_tabpage() then
      return w
    end
  end
end

local function restore_state()
  if state.terminal_normal then
    if state.view then vim.fn.winrestview(state.view) end
  else
    vim.cmd 'startinsert'
  end
end

local function clear_state()
  M.hide()
  if agent_buf() then vim.api.nvim_buf_delete(state.buf, { force = true }) end
  state.buf = nil
  state.view = nil
  state.terminal_normal = false
end

local function split_width()
  return math.floor(vim.o.columns * config.window.width)
end

vim.api.nvim_create_autocmd('VimResized', {
  callback = function()
    local win = agent_win()
    if not win then return end

    vim.api.nvim_win_set_width(win, split_width())
  end,
  desc = 'Resize aos side terminal',
})

local function path_with_position()
  local path = vim.fn.expand '%:p'
  local mode = vim.fn.mode()

  if mode == 'v' or mode == 'V' or mode == '\22' then
    local start_pos = vim.fn.getpos 'v'
    local end_pos = vim.fn.getpos '.'
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]

    -- Normalize so the start position precedes the end position.
    if start_row > end_row or (start_row == end_row and start_col > end_col) then
      start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
    end

    if mode == 'V' then
      return string.format('%s:L%d-L%d', path, start_row, end_row)
    elseif start_row == end_row then
      return string.format('%s:L%d:C%d-C%d', path, start_row, start_col, end_col)
    end
    return string.format('%s:L%d:C%d-L%d:C%d', path, start_row, start_col, end_row, end_col)
  end

  local cursor = vim.fn.getpos '.'
  return string.format('%s:L%d:C%d', path, cursor[2], cursor[3])
end

local function open_split(buf)
  local win = vim.api.nvim_open_win(buf, true, {
    split = config.window.side,
    win = -1,
    width = split_width(),
  })

  vim.wo[win][0].winfixwidth = true
  vim.wo[win][0].number = false
  vim.wo[win][0].relativenumber = false
  vim.wo[win][0].signcolumn = 'no'

  return win
end

local function split_count(tab)
  local n = 0
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(tab)) do
    if vim.api.nvim_win_get_config(w).relative == '' then
      n = n + 1
    end
  end
  return n
end

local function release(win)
  local empty = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_win_set_buf(win, empty)

  vim.api.nvim_win_call(win, function()
    vim.cmd 'setlocal winfixwidth< number< relativenumber< signcolumn<'
  end)
end

local function at_edge(win)
  local column = vim.fn.win_screenpos(win)[2]
  if config.window.side == 'left' then
    return column == 1
  else
    local width = vim.api.nvim_win_get_width(win)
    return column + width - 1 == vim.o.columns
  end
end

local function pin_to_edge()
  local win = agent_win()

  if not win then return end
  if at_edge(win) then return end

  vim.api.nvim_win_call(win, function()
    if config.window.side == 'left' then
      vim.cmd 'wincmd H'
    else
      vim.cmd 'wincmd L'
    end
  end)

  vim.api.nvim_win_set_width(win, split_width())
end

local function close_all()
  if not agent_buf() then return end

  for _, w in ipairs(vim.fn.win_findbuf(agent_buf())) do
    if split_count(vim.api.nvim_win_get_tabpage(w)) == 1 then
      release(w)
    else
      vim.api.nvim_win_close(w, true)
    end
  end
end

function M.hide()
  if vim.api.nvim_get_current_win() == agent_win() then
    state.terminal_normal = vim.api.nvim_get_mode().mode ~= 't'
    state.view = state.terminal_normal and vim.fn.winsaveview() or nil
  end

  close_all()

  if state.prev_win and vim.api.nvim_win_is_valid(state.prev_win) then
    if vim.api.nvim_win_get_tabpage(state.prev_win) == vim.api.nvim_get_current_tabpage() then
      vim.api.nvim_set_current_win(state.prev_win)
    end
  end

  state.prev_win = nil
end

function M.copy_path_with_position()
  local result = path_with_position()
  vim.fn.setreg('+', result)
  vim.notify('Copied path+position to clipboard', vim.log.levels.INFO)
  return result
end

function M.copy_path()
  local path = vim.fn.expand '%:p'
  vim.fn.setreg('+', path)
  vim.notify('Copied file path to clipboard', vim.log.levels.INFO)
  return path
end

function M.open()
  local win = agent_win()
  if win ~= vim.api.nvim_get_current_win() then
    state.prev_win = vim.api.nvim_get_current_win()
  end

  if win then
    vim.api.nvim_set_current_win(win)
    vim.cmd 'startinsert'
    return
  end

  if agent_buf() then
    open_split(state.buf)
    restore_state()
    return
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = 'hide'
  open_split(state.buf)

  local colorfgbg = vim.o.background == 'light' and '0;15' or '15;0'
  local buf = state.buf
  local ok, job = pcall(vim.fn.jobstart, config.command, {
    term = true,
    cwd = vim.fn.getcwd(),
    env = {
      COLORFGBG = colorfgbg,
    },
    on_exit = function()
      vim.schedule(function()
        if state.buf == buf then clear_state() end
      end)
    end,
  })

  if not ok then
    clear_state()
    vim.notify('aos.nvim: failed to start ' .. config.command[1] .. ': ' .. job, vim.log.levels.ERROR)
    return
  end

  if job <= 0 then
    clear_state()
    vim.notify('aos.nvim: failed to start ' .. config.command[1], vim.log.levels.ERROR)
    return
  end

  vim.cmd 'startinsert'
end

function M.toggle()
  if agent_win() then
    M.hide()
  else
    M.open()
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', vim.deepcopy(defaults), opts or {})

  if config.keymaps.toggle then
    vim.keymap.set('n', config.keymaps.toggle, M.toggle, {
      desc = 'Agent side terminal',
    })
    vim.keymap.set('t', config.keymaps.toggle, M.toggle, {
      desc = 'Agent side terminal'
    })
  end

  if config.keymaps.copy_path then
    vim.keymap.set('n', config.keymaps.copy_path, M.copy_path, {
      desc = 'Copy current file path',
    })
  end

  if config.keymaps.copy_path_with_position then
    vim.keymap.set({ 'n', 'x' }, config.keymaps.copy_path_with_position, M.copy_path_with_position, {
      desc = 'Copy file path with range or position',
    })
  end

  local group = vim.api.nvim_create_augroup('Aos', { clear = true })
  vim.api.nvim_create_autocmd('WinNew', {
    group = group,
    callback = function()
      if vim.api.nvim_win_get_config(0).relative ~= '' then return end
      vim.schedule(pin_to_edge)
    end,
    desc = 'Keep the agent terminal at the edge',
  })
end

return M
