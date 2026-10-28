if vim.g.loaded_aos_nvim then return end
vim.g.loaded_aos_nvim = true

local actions = {
  open = true,
  hide = true,
  toggle = true,
}

vim.api.nvim_create_user_command('Aos', function(opts)
  local action = opts.args ~= '' and opts.args or 'open'
  if not actions[action] then
    vim.notify('aos.nvim: unknown action: ' .. action, vim.log.levels.ERROR)
    return
  end

  require('aos')[action]()
end, {
  nargs = '?',
  complete = function()
    return { 'open', 'hide', 'toggle' }
  end,
  desc = 'Open, hide or toggle the agent on the side terminal',
})
