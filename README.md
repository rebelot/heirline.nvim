<p align="center">
  <h2 align="center">heirline.nvim</h2>
</p>
<p align="center">
  <img src="heirline.png" width="600" >
</p>
<p align="center">The ultimate Neovim Statusline for tinkerers</p>

## About

Heirline.nvim is a no-nonsense Neovim Statusline/Winbar plugin designed around
recursive inheritance to be exceptionally **fast** and **versatile**.

Heirline **does not** provide any default statusline, in fact, heirline can be
thought of as a statusline API.

> **Why another statusline plugin?**

Heirline picks up from other popular customizable statusline plugins like
[galaxyline](https://github.com/NTBBloodbath/galaxyline.nvim) and
[feline](https://github.com/feline-nvim/feline.nvim) but removes all the
hard-coded guides and offers you thousands times more freedom. But freedom has a
price: responsibility. I don't get to tell you what your statusline should do.
You're in charge! With Heirline, you have a framework to easily implement
whatever you can imagine, from simple to complex rules!

## Features:

- **Conditionals**: Build custom active/inactive and buftype/filetype/bufname statuslines or single components.
- **Highlight propagation**: Seamlessly surround components within separators and/or set the (dynamic) coloring of a bunch of components at once.
- **Modularity**: Statusline components can be reutilized/rearranged and will behave according to their position in the genealogical tree.
- **Update triggers**: Re-evaluate components only when some condition is met or specific autocommand events are fired.
- **Clickable**: Write pure lua callbacks to be executed when clicking a component.
- **Dynamic resizing**: Specify how components should resize depending on available space.
- **Full control**: You have hooks to fully control the statusline evaluation cycle.

Heirline is _not_ for everyone, heirline is for people who like tailoring their own tools (and also like lua):

- **No** default statusline is provided
- You **must** write your own statusline

But don't you worry! Along with the inheritance comes [THE FEATUREFUL COOKBOOK](cookbook.md) 📖
of a distant relative. Your dream 🪄 statusline is a
copypaste away!

## Installation

Use your favorite plugin manager

```lua
use "rebelot/heirline.nvim"
```

## Setup

No defaults, no options, no-nonsense. You choose.

```lua
local statusline = {...}
local winbar = {...}
require'heirline'.setup(statusline, winbar)
```

Calling `setup` will load your statusline. To learn how to write a StatusLine, see the [docs](cookbook.md).

### Donate

Buy me coffee and support my work ;)

[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/donate/?business=VNQPHGW4JEM3S&no_recurring=0&item_name=Buy+me+coffee+and+support+my+work+%3B%29&currency_code=EUR)
