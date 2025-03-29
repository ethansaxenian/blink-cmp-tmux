--- @module 'blink.cmp'

--- @class blink-cmp-tmux.Opts
--- @field panes? 'window'|'session'|'server'
--- @field full_history? boolean

--- @type blink-cmp-tmux.Opts
local default_opts = {
  panes = "window",
  full_history = false,
}

--- @class TmuxSource : blink.cmp.Source, blink-cmp-tmux.Opts
local M = {}

--- @param opts blink-cmp-tmux.Opts
function M.new(opts)
  --- @type blink-cmp-tmux.Opts
  local config = vim.tbl_deep_extend("force", default_opts, opts or {})

  vim.validate({
    panes = { config.panes, "string" },
    full_history = { config.full_history, "boolean" },
  })

  return setmetatable(config, { __index = M })
end

function M:enabled()
  return vim.fn.executable("tmux") == 1 and vim.env.TMUX ~= nil
end

--- @return string[]
function M:list_panes()
  local cmd = { "tmux", "list-panes", "-F", "#{pane_id}" }
  if self.panes == "session" then
    table.insert(cmd, "-s")
  elseif self.panes == "server" then
    table.insert(cmd, "-a")
  end
  local res = vim.system(cmd):wait()

  local panes = {}
  for pane_id in string.gmatch(res.stdout, "[^\n]+") do
    if pane_id ~= vim.env.TMUX_PANE then
      table.insert(panes, pane_id)
    end
  end
  return panes
end

--- @param pane_id string
--- @return string
function M:capture_pane(pane_id)
  local cmd = { "tmux", "capture-pane", "-pJ", "-t", pane_id }
  if self.full_history then
    table.insert(cmd, "-S")
    table.insert(cmd, "-")
  end
  local res = vim.system(cmd, { text = true }):wait()
  return res.stdout or ""
end

function M:get_completions(_, callback)
  local all_words = {}
  for _, pane in ipairs(self:list_panes()) do
    local pane_contents = self:capture_pane(pane)
    for word in string.gmatch(pane_contents, "%a+") do
      if not all_words[word] then
        all_words[word] = true
      end
    end
  end

  local items = {}
  --- @type lsp.CompletionItem[]
  for word, _ in pairs(all_words) do
    --- @type lsp.CompletionItem
    local item = {
      label = word,
      kind = require("blink.cmp.types").CompletionItemKind.Text,
      insertTextFormat = vim.lsp.protocol.InsertTextFormat.PlainText,
    }
    table.insert(items, item)
  end

  callback({
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  })

  return function() end
end

return M
