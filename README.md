<p align="center">
  <h2 align="center">heirline.nvim</h2>
</p>
<p align="center">The ultimate Neovim Statusline for tinkerers</p>

## About

Heirline.nvim is a no-nonsense Neovim Statusline plugin designed around
recursive inheritance to be exceptionally **fast** and **versatile**.

Heirline **does not** provide any default statusline, in fact, heirline can be
thought of as a statusline API.

    > **Why another statusline plugin?**

Heirline picks up from other popular customizable statusline plugins like
[galaxyline]() and [feline]() but removes all the hard-coded bloat and offers
you thousands times more freedom. But freedom has a price: responsibility. I
don't get to tell you what your statusline should do. You're in charge! With
Heirline, you have a framework to easily implement whatever you can imagine,
from simple to complex rules!

Heirline was deigned with two main features in mind:
* You can easily set up different statuslines for any kind of buffer
* You can reutilize components that will behave according to their position in the genealogical tree.

Heirline is _not_ for everyone, heirline is for people who like tailoring their own tools (and also like lua):
* **No** default statusline is provided 
* You **must** write your own statusline

But don't you worry! Along with the inheritance comes [THE FEATUREFUL COOKBOOK](cookbook.md) 📖
of a distant relative. Your dream 🪄statusline is a
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
require'heirline'.setup(statusline)
```
