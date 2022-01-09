# Cookbook.md

## Index
* [Main concepts](#main-concepts)
* [Component fields](#component-fields)
* [Builtin conditions](#builtin-conditions)
* [Utilities](#utilities)
* [Recipes](#recipes)
    * [ViMode](#vimode)
    * [FileName, FileType, FileModified, and firends](#filename)
    * [Ruler](#ruler)
    * [FileSize](#filesize)
    * [LSP](#lsp)
    * [Git](#git)
    * [Diagnostics](#diagnostics)
    * [Debugger](#debugger)
    * [Tests](#tests)
    * [Conditional Statuslines](#conditional-statuslines)
* [Putting it all together](#putting-it-all-together)

## Main concepts

In heirline, everything is a [`StatusLine`](lua/heirline/statusline.lua#31)
object. There is no distinction in the way one defines the final statusline
from any of its components.

You don't need to explicitly create a `StatusLine` object, the `setup` function
will handle that. What you should do, is to create a lua table that will serve as
a blueprint for the creation of such objects.

That's it, your statusline(s) are just some nested tables.

The nested tables will be referred to as `components`. Components may contain
other components, each of which may contain others. A component within another
component is called a `child`, and will inherit the fields of its `parent`.
When a child inherits its parent fields, these get updated with the child's
fields of the same kind. There is no limit in how many components can be nested
into each other.

```lua
local statusline = {
{...}, {...}, {..., {...}, {...}, {..., {...}, {..., {...}}}}
}
require'heirline'.setup(statusline)
```

##
