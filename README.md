<p align="center">
  <h2 align="center">heirline.nvim</h2>
</p>
<p align="center">
  <img src="heirline.png" width="600" >
</p>
<p align="center">The ultimate Neovim Statusline for tinkerers</p>

## About

Heirline.nvim is a no-nonsense Neovim Statusline plugin designed around
recursive inheritance to be exceptionally **fast** and **versatile**.

Heirline **does not** provide any default statusline, in fact, heirline can be
thought of as a statusline API.

> **Why another statusline plugin?**

Heirline picks up from other popular customizable statusline plugins like
[galaxyline](https://github.com/NTBBloodbath/galaxyline.nvim) and
[feline](https://github.com/feline-nvim/feline.nvim) but removes all the
hard-coded bloat and offers you thousands times more freedom. But freedom has a
price: responsibility. I don't get to tell you what your statusline should do.
You're in charge! With Heirline, you have a framework to easily implement
whatever you can imagine, from simple to complex rules!

Heirline was deigned with these main features in mind:

- Active/inactive and buffer/filetype custom statuslines.
- Modularity: statusline components can be reutilised and will behave according to their position in the genealogical tree.
- Seamless surrounding and coloring of specific components.

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
require'heirline'.setup(statusline)
```

Calling `setup` will load your statusline. To learn how to write a StatusLine, see the [docs](cookbook.md).

### Donate
Buy me coffee and support my work ;)

<form action="https://www.paypal.com/donate" method="post" target="_top">
<input type="hidden" name="business" value="VNQPHGW4JEM3S" />
<input type="hidden" name="no_recurring" value="0" />
<input type="hidden" name="item_name" value="Buy me a coffee and support my work ;)" />
<input type="hidden" name="currency_code" value="EUR" />
<input type="image" src="https://www.paypalobjects.com/en_US/i/btn/btn_donate_LG.gif" border="0" name="submit" title="PayPal - The safer, easier way to pay online!" alt="Donate with PayPal button" />
<img alt="" border="0" src="https://www.paypal.com/en_IT/i/scr/pixel.gif" width="1" height="1" />
</form>

