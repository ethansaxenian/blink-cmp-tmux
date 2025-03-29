# blink-cmp-tmux

A simple tmux completion source for [blink.cmp](https://github.com/Saghen/blink.cmp)

# Setup

```lua
{
  "saghen/blink.cmp",
  dependencies = { "ethansaxenian/blink-cmp-tmux" },
  opts = {
    sources = {
      default = { "tmux" },
      providers = {
        tmux = {
          name = "tmux",
          module = "blink-cmp-tmux",
          --- @type blink-cmp-tmux.Opts
          opts = {
            panes = "window", -- "session", "server"
            full_history = false,
          },
        },
      },
    },
  },
}
```
