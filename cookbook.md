# Cookbook.md

## Index
* [Main concepts](#main-concepts)
* [Component fields](#component-fields)
* [Builtin conditions and utilities](#builtin-conditions-and-utilities)
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

In heirline, everything is a [`StatusLine`](lua/heirline/statusline.lua#L31)
object. There is no distinction in the way one defines the final statusline
from any of its components.

You don't need to explicitly create a `StatusLine` object, the `setup` function
will handle that. What you should do, is to create a lua table that will serve as
a blueprint for the creation of such objects.

That's it, your statusline(s) are just some nested tables.

The nested tables will be referred to as `components`. Components may contain
other components, each of which may contain others. A component within another
component is called a `child`, and will inherit the fields of its `parent`.
There is no limit in how many components can be nested into each other.

```lua
local statusline = {
{...}, {...}, {..., {...}, {...}, {..., {...}, {..., {...}}}}
}
require'heirline'.setup(statusline)
```

Writing nested tables can be tiresome, so the best approach is to define simple
components and then assemble those.

```lua
local Component1 = {
    ...
}

local Component2 = {
    ...
}

local statusline = {
    ..., 
    Component1,
    Component2,
}
```

## Component fields

So, what should be the content of a component table? Well it's fairly simple,
don't get discouraged by the detailed description! Just keep one thing in mind:
whenever you see a function, know that the function is executed in the context
of the buffer and window the statusline belongs to. (The indices of the actual
buffer and window you're in are stored in the default vim global variables
`vim.g.actual_curbuf` and `vim.g.acutal_curwin`.)

Note that all functions described below are actual methods of the component
itself, which can be accessed via the `self` parameter. Because of inheritance,
Children will look for unknown keys within their own parent fields.

Each component may contain _any_ of the following fields: 
* `provider`:
    * Type: `string` or `function(self) -> string|nil`
    * Description: This is the string that gets printed in the statusline. No
      escaping is performed, so it may contain sequences that have a special
      meaning within the statusline, such as `%f` (filename), `%p` (percentage
      through file), `%-05.10(` `%)` (to control text alignment and padding),
      etc. For more, see `:h 'statusline'`. To print an actual `%`, use `%%`.
* `hl`:
    * Type: `table` or `function(self) -> table`. The table may contain any of:
        * `fg`: The foreground color. Type: `string` to hex color code or vim
          builtin color name (eg.: `"#FFFFFF"`, `"red"`).
        * `bg`: The background color. Type: as above.
        * `guisp`: The underline/undercurl color, if any. Type: as above.
        * `style`: Any of the supported comma-separated highlight styles:
          `italic`, `bold`, `underline`, `undercurl`, `reverse`, `nocombine` or
          `none`. (eg.: `"bold,italic"`)
    * Description: `hl` controls the colors of what is printed by the
      component's `provider`, or by any of its descendants. Whenever a `child`
      inherits its parent's `hl` (whether a function or table), this gets
      updated with the child's `hl`, so that, when specified, the fields in the
      child `hl` will always take precedence.
* `condition`:
    * Type: `function(self) -> any`
    * Description: This function controls whether the component should be
      evaluated or not. The truth of the return value is tested, so any value
      besides `nil` and `false` will evaluate to true. Of course, this will
      affect all of the component's progeny.
* `init`:
    * Type: `function(self) -> any`
    * Description: This function is called whenever a component is evaluated
      and can be used to modify the state of the component itself, like
      creating some variable(s) that will be shared among the component's
      heirs, or even modify other fields like `provider` and `hl`.
* `block`:
    * Type: `bool`
    * Description: If a component has any child, their evaluation will stop at
      the first child in the succession line who does not return an empty
      string. This field is not inherited by the component's progeny. Use this
      in combination with children conditions to create buffer-specific
      statuslines! (Or do whatever you can think of!)
* `{...}`:
    * Type: `list`
    * Description: The component progeny. Each item of the list is a component
      itself and may contain any of the above fields.

Confused yet? Don't worry, everything will come together in the [Recipes](#recipes) examples.

## Builtin conditions and utilities

While heirline does not provide any default component, it defines a few useful
test and utility functions to aid in writing components and their conditions.
These functions are accessible via `require'heirline.conditions` and
`require'heirline.utils'`

**Built-in conditions**: 
* `is_active()`: returns true if the statusline's window is the active window.
* `buffer_matches(patterns)`: Returns true whenever a buffer attribute
  (`filetype`,`buftype` or `bufname`) matches any of the lua patterns in the
  corresponding list.
    * `patterns`: table of the form `{filetype = {...}, buftype = {...}, bufname = {...}}`
    where each field is a list of lua patterns.
* `width_percent_below(N, threshold)`: returns true if `(N / current_window_width) <= threshold`.)
* `is_git_repo()`: returns true if the file is within a git repo (uses [gitsigns]())
* `has_diagnostics()`: returns true if there is any diagnostic for the buffer.
* `lsp_attavhed():` returns true if an LSP is attached to the buffer.

**Utility functions**: 
* `get_highlight(hl_name)`: returns a table of the attributes of the provided
  highlight name. The returned table contains the `hl` fields described above.
* `clone(component, with)`: returns a new component which is a copy of the
  supplied one, updated with the fields in the `with` table.
* `surround(delimiters, color, component)`: returns a new component, which
  contains a copy of the supplied one, surrounded by the left and right
  delimiters supplied by the `delimiters` table.
  * `delimiters`: table of the form `{"right_delimiter", "left_delimiter}`
  * `color`: string of color hex code or builtin color name. This color will be
    the foreground color of the delimiters and the background color of the
    component.
  * `component`: the component to be surrounded.

## Recipes

