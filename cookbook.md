# Cookbook.md

## Index

- [Main concepts](#main-concepts)
- [Component fields](#component-fields)
  - [The StatusLine life cycle](#the-statusline-life-cycle)
  - [StatusLine Base Methods and Attributes](#statusline-base-methods-and-attributes)
- [Builtin conditions and utilities](#builtin-conditions-and-utilities)
- [Recipes](#recipes)
  - [Getting started](#getting-started)
  - [Colors, colors, more colors!](#colors-colors-more-colors)
  - [Crash course: the ViMode](#crash-course-the-vimode)
  - [Crash course part II: FileName and friends](#crash-course-part-ii-filename-and-friends)
  - [FileType, FileEncoding and FileFormat](#filetype-filesize-fileencoding-and-fileformat)
  - [FileSize and FileLastModified](#filesize-and-filelastmodified)
  - [Cursor position: Ruler and ScrollBar ](#cursor-position-ruler-and-scrollbar)
  - [LSP](#lsp)
  - [Diagnostics](#diagnostics)
  - [Git](#git)
  - [Debugger](#debugger)
  - [Tests](#tests)
  - [Working Directory](#working-directory)
  - [Terminal Name](#terminal-name)
  - [Help FileName](#help-filename)
  - [Snippets Indicator](#snippets-indicator)
  - [Spell](#spell)
- [Flexible Components](#flexible-components) :new:
- [Putting it all together: Conditional Statuslines](#putting-it-all-together-conditional-statuslines)
  - [Lion's finesse](#lions-finesse)
  - [Winbar](#winbar) :new:
- [A classic: Change multiple background colors based on Vi Mode](#a-classic-change-multiple-background-colors-based-on-vi-mode)
- [Click it!](#click-it) :new:
- [Theming](#theming)

## Main concepts

In heirline, everything is a [`StatusLine`](lua/heirline/statusline.lua#L12)
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

local winbar = {{...}, {{...}, {...}}}

-- the winbar parameter is optional!
require'heirline'.setup(statusline, winbar)
```

Writing nested tables can be tiresome, so the best approach is to define simple
components and then assemble them. For example:

```lua
local Component1 = { ... }

local Sub1 = { ... }

local Component2 = { ... }

local statusline = {
    ...,
    {Component1, Sub1},
    Component2,
}

require'heirline'.setup(statusline)
```

After calling `require'heirline'.setup(statusline[, winbar])`, your `StatusLine` object
will be created, and you can find its handle at `require'heirline'.statusline`
(and `require'heirline'.winbar`).
Any modification to the object itself will reflect in real time on your statusline!

Note that no reference is shared between the table objects used as blueprints (the
ones you pass to `setup()`) and the final object, as all data is deep-copied.

## Component fields

So, what should be the content of a component table? Well it's fairly simple,
don't let the detailed description discourage you! Just keep one thing in mind:
whenever you see a function, know that the function is executed in the context
of the buffer and window the statusline belongs to. (The indices of the actual
buffer and window you're in are stored in the default vim global variables
`vim.g.actual_curbuf` and `vim.g.acutal_curwin`.)

Each component may contain _any_ of the following fields:

> Note that all functions described below are actual **_methods_** of the component
> itself, which can be accessed via the `self` parameter. Because of inheritance,
> children will look for unknown attributes within their own parent fields.

**Basic fields**:

- `provider`:
  - Type: `string|number` or `function(self) -> string|number|nil`
  - Description: This is the string that gets printed in the statusline. No
    escaping is performed, so it may contain sequences that have a special
    meaning within the statusline, such as `%f` (filename), `%p` (percentage
    through file), `%-05.10(` `%)` (to control text alignment and padding),
    etc. For more, see `:h 'statusline'`. To print an actual `%`, use `%%`.
- `hl`:
  - Type: `table|string` or `function(self) -> table|string|nil`.
    If `hl` is a string, it will be interpreted as the name of an already defined highlight group.
    If `hl` is a table, it may contain any of:
    - `fg`: The foreground color. Type: `string` to hex color code or vim
      standard color name (e.g.: `"#FFFFFF"`, `"red"`).
    - `bg`: The background color. Type: as above.
    - `sp`: The underline/undercurl color, if any. Type: as above.
    - Style fields supported by `synIDattrstyle()`: Example: `{ bold = true, underline = true }`
    - `force`: Control whether the parent's `hl` fields will override child's hl.
      Type: `bool`.
  - Description: `hl` controls the colors of what is printed by the component's
    `provider`, or by any of its descendants. At evaluation time, the `hl` of
    any component gets merged with the `hl` of its parent (whether it is a
    function or table), so that, when specified, the fields in the child `hl`
    will always take precedence unless `force` is `true`.
- `condition`:
  - Type: `function(self) -> any`
  - Description: This function controls whether the component should be
    evaluated or not. It is the first function to be executed at evaluation
    time. The _truthy_ of the return value is tested, so any value besides `nil`
    and `false` will evaluate to `true`. Of course, this will affect all of the
    component's progeny.
- `on_click`:
  - Type: `table` with the following fields:
    - `callback`: (vim/)lua function to be called on mouse click(s). The function
      has the signature `function(self, winid, minwid, nclicks, button)`
      (see `:h 'statusline'` description for `@`). If a `string` is provided,
      it is interpreted as the _raw_ function name (`v:lua.` is not prepended)
      of an already defined function accessible from vim global scope.
      Type: `function` or `string`.
    - `name`: the global name the function will be registered with.
      It is not required when `callback` is a `string`. Type: `string` or `function -> string`.
    - `update`: whether the function should be registered even if
      it already exists in the global namespace.
      This is useful for dynamically registering different callbacks.
      Omit this field if you are registering only one function.
      Type: `boolean` (optional).
  - Description: Specify a function to be called when clicking on the component (including its progeny);
    Lua functions are automatically registered in the global scope with the name provided
    by the `name` field. Arguments passed to the function are the same described
    for the `@` statusline field, with the addition of the component reference
    (`self`) as the first parameter and the current `window-ID` as the second parameter.
    The self parameter and `winid` are _not_ passed if `callback` is a `string`.
    By default, the callback is registered only once:
    the first time it's encountered during components evaluation.
    If `update` is `true`, the callback will be (re-)registered
    at each evaluation cycle. Note 1: be careful of the arguments passed to the callback,
    you may often prefer wrapping a 'third-party' functions rather than passing their
    reference as is. Note 2: the callback is **_not_** executed in the context
    of the window/buffer the component belongs to, but in the context of the
    _actual_ current window and buffer. Use `winid` parameter to retrieve
    information about the current buffer from a callback.
    Be careful when accessing `self` attributes that were set depending
    on the local buffer/window the component is displayed into from
    within the callback, as they are shared between all representation
    of the _same_ component.
    Please see the recipes to learn _how to propagate information about
    the window/buffer the clicked component belongs to_.
- `update`:
  - Type: `function(self) -> boolean` or `string` or `table<string>`.
  - Description: Control when the component should be updated or return a per-window
    cached value.
    If `update` is a function, the component will be updated whenever the function
    return value is `true`; else, a `string` or a `table` of strings will be
    interpreted as autocommand event names that should trigger the component evaluation.
- `{...}`:
  - Type: `list`
  - Description: The component progeny. Each item of the list is a component
    itself and may contain any of the basic and advanced fields.

**Advanced fields**

- `pick_child`:
  - Type: `table[int]`
  - Description: Specify which children and in which order they should be
    evaluated by indicating their indexes (eg: `{1, 3, 2}`). It makes most
    sense to modify this attribute from within `init` function using the `self`
    parameter to dynamically pick the children to evaluate.
- `init`:
  - Type: `function(self) -> any`
  - Description: This function is called whenever a component is evaluated
    (right after `condition` but before `hl` and `provider`), and can be used
    to modify the state of the component itself via the `self` parameter. For
    example, you can compute some values that will be accessed from other
    functions within the component genealogy (even "global" statusline
    variables).
- `after`:
  - Type: `function(self) -> any`
  - Description: This function is called after the component has evaluated all of its
    children and can be used to alter the state of the component before it returns
    the output string `self.stl`.
- `static`:
  - Type: `table`
  - Description: This is a container for static variables, that is, variables
    that are computed only once at component definition. This is useful to
    organize data that should be shared among children, like icons or
    dictionaries. Any keyword defined within this table can be accessed by the
    component and its children methods as a direct attribute using the `self`
    parameter. (eg: `static = { x = ... }` can be accessed as `self.x`
    somewhere else).
- `restrict`:
  - Type: `table[keyword = bool]`
  - Description: Set-like table to control which component fields can be
    inherited by the component's progeny. The supplied table gets merged with
    the defaults. By default, the following fields are private to the
    component: `pick_child`, `init`, `provider`, `condition` and `restrict`.
    Attention: modifying the defaults could dramatically affect the behavior of
    the component! (eg: `restrict = { my_private_var = true, provider = false }`)

### The StatusLine life cycle

There are two distinct phases in the life of a StatusLine object component: its
_creation_ (instantiation) and its _evaluation_. When creating the "blueprint"
tables, the user instructs the actual constructor on the attributes and methods
of the component. The fields `static` and `restrict` will have a meaning only
during the instantiation phase, while `condition`, `update`, `init`, `hl`,
`on_click`, `provider` and `pick_child` are evaluated (in this order) every time the statusline is
refreshed.

Confused yet? Don't worry, everything will come together in the [Recipes](#recipes) examples.

### StatusLine Base Methods and Attributes

You'll probably never need those, however, for completeness, it's worth
explaining the `StatusLine` object base methods and attributes:

- `new(self, child)`: This is the constructor that takes in the `child`
  "blueprint" and returns a new `StatusLine` object. This function is
  recursive, so if `child` has children, those will be instantiated as `child`
  subclasses. Also note that all tables in `child` are deep-copied in the
  returned object.
- `eval(self)`: Evaluates the `StatusLine` recursively to figure out, for every
  component and {sub{,sub{,sub{,...}}}} components what's their printable value
  and color. This function will execute `condition`, `init`, `hl` and
  `provider` and merges the object's evaluated `hl` with the parent's
  (depending on the value of its `hl.force`).
- `nonlocal(self, attr)`: Searches for the keyword `attr` in the parent's
  `__index`, ignoring any value defined for that keyword in the component
  itself (`self`). This is useful for children that want to look for their
  parent's attributes, ignoring what was passed to them by inheritance.
- `local_(self, attr)`: Return the value of `attr` only if it is defined for
  the component itself, do not look in the parent's metatables.
- `broadcast(self, func)`: Execute `func(component)` on every component of the
  statusline.
- `get(self, id)`: Get a handle of the component with the given `id`
- `id`: Table containing the indices required to index the component from the
  root.
- `{set,get}_win_attr(self, attr, default)`: Set or get a window-local
  component attribute. If the attribute is not defined, sets a `default` value.
- `stl`: the **last** output value of the component's evaluation.
- `winnr`: window number of the **last** window the component was evaluated into.

## Builtin conditions and utilities

While heirline does not provide any default component, it defines a few useful
test and utility functions to aid in writing components and their conditions.
These functions are accessible via `require'heirline.conditions'` and
`require'heirline.utils'`

**Built-in conditions**:

- `is_active()`: returns true if the statusline's window is the active window.
- `buffer_matches(patterns)`: Returns true whenever a buffer attribute
  (`filetype`,`buftype` or `bufname`) matches any of the lua patterns in the
  corresponding list.
  - `patterns`: table of the form `{filetype = {...}, buftype = {...}, bufname = {...}}` where each field is a list of lua patterns.
- `width_percent_below(N, threshold, is_winbar)`: returns true if `(N / current_window_width) <= threshold`
  (eg.: `width_percent_below(#mystring, 0.33)`). This function checks the value
  of `vim.o.laststatus` to determine the statusline draw space, if `is_winbar == true` only the current window width will be considered.
- `is_git_repo()`: returns true if the file is within a git repo (uses [gitsigns](https://github.com/lewis6991/gitsigns.nvim))
- `has_diagnostics()`: returns true if there is any diagnostic for the buffer.
- `lsp_attached():` returns true if an LSP is attached to the buffer.

**Utility functions**:

- `get_highlight(hl_name)`: returns a table of the attributes of the provided
  highlight name. The returned table contains the same fields as returned by
  `nvim_get_hl_by_name`. The returned table can be indexed using the following abbreviations:
  `fg` → `foreground`, `bg` → `background`, `sp` → `special`.
- `clone(component[, with])`: returns a new component which is a copy of the
  supplied one, updated with the fields in the optional `with` table.
- `surround(delimiters, color, component)`: returns a new component, which
  contains a copy of the supplied one, surrounded by the left and right
  delimiters given by the `delimiters` table.
  - `delimiters`: table of the form `{left_delimiter, right_delimiter}`.
    Because they are actually just providers, delimiters could also be
    functions!
  - `color`: `string|nil` or `function -> string|nil`. String should refer to
    RGB hex code or builtin color name. This color will be the foreground color
    of the delimiters and the background color of the component.
  - `component`: the component to be surrounded.
- `insert(parent, ...)`: return a copy of `parent` component where each `child`
  in `...` (variable arguments) is appended to its children (if any).
- `make_flexible_component(priority, ...)`: Returns a _flexible component_ with
  the given priority (`int`). This component will cycle between all the `components`
  passed as `...` arguments until they fit in the available space for the
  statusline. The components passed as variable arguments should evaluate to
  decreasing lengths. See [Flexible Components](#flexible-components) for more!
- `pick_child_on_condition(component)`: This function should be passed as the `init`
  field while defining a new component. It will dynamically set the `pick_child`
  field to the index of the first child whose condition evaluates to `true`.
  This is useful for branching conditional statuslines
  (see [Putting it all together: Conditional Statuslines](#putting-it-all-together-conditional-statuslines)).
- `count_chars(str)`: Returns the character length of `str`. Handles multibyte
  characters (icons) and statusline syntax like `%f`, `%3.10%(...%)`, etc.

## Recipes

### Getting started

Ideally, the following code snippets should go within a configuration file, say
`~/.config/nvim/lua/plugins/heirline.lua`, that can be required in your
`init.lua` (or from packer `config`) using `require'plugins.heirline'`.

Your configuration file will start like this:

```lua
local conditions = require("heirline.conditions")
local utils = require("heirline.utils")
```

### Colors, colors, more colors

You will probably want to define some colors. This is not required, you don't
even have to use them if you don't like it, but let's say you like colors.

Colors can be specified directly in components, but it is probably more
convenient to organize them in some kind of table. If you want your statusline
to blend nicely with your colorscheme, the utility function `get_highlight()`
is your friend. To create themes and have your colors updated on-demand, see
[Theming](#theming).

```lua
local colors = {
    red = utils.get_highlight("DiagnosticError").fg,
    green = utils.get_highlight("String").fg,
    blue = utils.get_highlight("Function").fg,
    gray = utils.get_highlight("NonText").fg,
    orange = utils.get_highlight("DiagnosticWarn").fg,
    purple = utils.get_highlight("Statement").fg,
    cyan = utils.get_highlight("Special").fg,
    diag = {
        warn = utils.get_highlight("DiagnosticWarn").fg,
        error = utils.get_highlight("DiagnosticError").fg,
        hint = utils.get_highlight("DiagnosticHint").fg,
        info = utils.get_highlight("DiagnosticInfo").fg,
    },
    git = {
        del = utils.get_highlight("diffDeleted").fg,
        add = utils.get_highlight("diffAdded").fg,
        change = utils.get_highlight("diffChanged").fg,
    },
}
```

Perhaps, your favorite colorscheme already provides a way to get the theme colors.

```lua
local colors = require'kanagawa.colors'.setup() -- wink
```

### Crash course: the ViMode

No statusline is worth its weight in _fanciness_ :star2: without an appropriate
mode indicator. So let's cook ours! Also, this snippet will introduce you to a
lot of heirline advanced capabilities.

```lua
local ViMode = {
    -- get vim current mode, this information will be required by the provider
    -- and the highlight functions, so we compute it only once per component
    -- evaluation and store it as a component attribute
    init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()
    end,
    -- Now we define some dictionaries to map the output of mode() to the
    -- corresponding string and color. We can put these into `static` to compute
    -- them at initialisation time.
    static = {
        mode_names = { -- change the strings if you like it vvvvverbose!
            n = "N",
            no = "N?",
            nov = "N?",
            noV = "N?",
            ["no\22"] = "N?",
            niI = "Ni",
            niR = "Nr",
            niV = "Nv",
            nt = "Nt",
            v = "V",
            vs = "Vs",
            V = "V_",
            Vs = "Vs",
            ["\22"] = "^V",
            ["\22s"] = "^V",
            s = "S",
            S = "S_",
            ["\19"] = "^S",
            i = "I",
            ic = "Ic",
            ix = "Ix",
            R = "R",
            Rc = "Rc",
            Rx = "Rx",
            Rv = "Rv",
            Rvc = "Rv",
            Rvx = "Rv",
            c = "C",
            cv = "Ex",
            r = "...",
            rm = "M",
            ["r?"] = "?",
            ["!"] = "!",
            t = "T",
        },
        mode_colors = {
            n = colors.red ,
            i = colors.green,
            v = colors.cyan,
            V =  colors.cyan,
            ["\22"] =  colors.cyan,
            c =  colors.orange,
            s =  colors.purple,
            S =  colors.purple,
            ["\19"] =  colors.purple,
            R =  colors.orange,
            r =  colors.orange,
            ["!"] =  colors.red,
            t =  colors.red,
        }
    },
    -- We can now access the value of mode() that, by now, would have been
    -- computed by `init()` and use it to index our strings dictionary.
    -- note how `static` fields become just regular attributes once the
    -- component is instantiated.
    -- To be extra meticulous, we can also add some vim statusline syntax to
    -- control the padding and make sure our string is always at least 2
    -- characters long. Plus a nice Icon.
    provider = function(self)
        return " %2("..self.mode_names[self.mode].."%)"
    end,
    -- Same goes for the highlight. Now the foreground will change according to the current mode.
    hl = function(self)
        local mode = self.mode:sub(1, 1) -- get only the first mode character
        return { fg = self.mode_colors[mode], bold = true, }
    end,
    -- Re-evaluate the component only on ModeChanged event!
    -- This is not required in any way, but it's there, and it's a small
    -- performance improvement.
    update = 'ModeChanged'
}
```

### Crash course part II: FileName and friends

Perhaps one of the most important components is the one that shows which file
you are editing. In this second recipe, we will revisit some heirline concepts
and explore new ways to assemble components. We will also learn a few useful
vim lua API functions. Because we are all crazy about icons, we'll require
[nvim-web-devicons](https://github.com/kyazdani42/nvim-web-devicons), but you
are absolutely free to omit that if you're not an icon person.

```lua

local FileNameBlock = {
    -- let's first set up some attributes needed by this component and it's children
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
    end,
}
-- We can now define some children separately and add them later

local FileIcon = {
    init = function(self)
        local filename = self.filename
        local extension = vim.fn.fnamemodify(filename, ":e")
        self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(filename, extension, { default = true })
    end,
    provider = function(self)
        return self.icon and (self.icon .. " ")
    end,
    hl = function(self)
        return { fg = self.icon_color }
    end
}

local FileName = {
    provider = function(self)
        -- first, trim the pattern relative to the current directory. For other
        -- options, see :h filename-modifers
        local filename = vim.fn.fnamemodify(self.filename, ":.")
        if filename == "" then return "[No Name]" end
        -- now, if the filename would occupy more than 1/4th of the available
        -- space, we trim the file path to its initials
        -- See Flexible Components section below for dynamic truncation
        if not conditions.width_percent_below(#filename, 0.25) then
            filename = vim.fn.pathshorten(filename)
        end
        return filename
    end,
    hl = { fg = utils.get_highlight("Directory").fg },
}

local FileFlags = {
    {
        provider = function() if vim.bo.modified then return "[+]" end end,
        hl = { fg = colors.green }

    }, {
        provider = function() if (not vim.bo.modifiable) or vim.bo.readonly then return "" end end,
        hl = { fg = colors.orange }
    }
}

-- Now, let's say that we want the filename color to change if the buffer is
-- modified. Of course, we could do that directly using the FileName.hl field,
-- but we'll see how easy it is to alter existing components using a "modifier"
-- component

local FileNameModifer = {
    hl = function()
        if vim.bo.modified then
            -- use `force` because we need to override the child's hl foreground
            return { fg = colors.cyan, bold = true, force=true }
        end
    end,
}

-- let's add the children to our FileNameBlock component
FileNameBlock = utils.insert(FileNameBlock,
    FileIcon,
    utils.insert(FileNameModifer, FileName), -- a new table where FileName is a child of FileNameModifier
    unpack(FileFlags), -- A small optimisation, since their parent does nothing
    { provider = '%<'} -- this means that the statusline is cut here when there's not enough space
)

```

## FileType, FileEncoding and FileFormat

These ones are pretty straightforward.

```lua
local FileType = {
    provider = function()
        return string.upper(vim.bo.filetype)
    end,
    hl = { fg = utils.get_highlight("Type").fg, bold = true },
}
```

```lua
local FileEncoding = {
    provider = function()
        local enc = (vim.bo.fenc ~= '' and vim.bo.fenc) or vim.o.enc -- :h 'enc'
        return enc ~= 'utf-8' and enc:upper()
    end
}
```

```lua
local FileFormat = {
    provider = function()
        local fmt = vim.bo.fileformat
        return fmt ~= 'unix' and fmt:upper()
    end
}
```

### FileSize and FileLastModified

Now let's get a little exotic!

```lua
local FileSize = {
    provider = function()
        -- stackoverflow, compute human readable file size
        local suffix = { 'b', 'k', 'M', 'G', 'T', 'P', 'E' }
        local fsize = vim.fn.getfsize(vim.api.nvim_buf_get_name(0))
        fsize = (fsize < 0 and 0) or fsize
        if fsize <= 0 then
            return "0"..suffix[1]
        end
        local i = math.floor((math.log(fsize) / math.log(1024)))
        return string.format("%.2g%s", fsize / math.pow(1024, i), suffix[i])
    end
}
```

```lua
local FileLastModified = {
    -- did you know? Vim is full of functions!
    provider = function()
        local ftime = vim.fn.getftime(vim.api.nvim_buf_gett_name(0))
        return (ftime > 0) and os.date("%c", ftime)
    end
}
```

### Cursor position: Ruler and ScrollBar

Here's some classics!

```lua
-- We're getting minimalists here!
local Ruler = {
    -- %l = current line number
    -- %L = number of lines in the buffer
    -- %c = column number
    -- %P = percentage through file of displayed window
    provider = "%7(%l/%3L%):%2c %P",
}
```

```lua
-- I take no credits for this! :lion:
local ScrollBar ={
    static = {
        sbar = { '▁', '▂', '▃', '▄', '▅', '▆', '▇', '█' }
        -- Another variant, because the more choice the better.
        -- sbar = { '🭶', '🭷', '🭸', '🭹', '🭺', '🭻' }
    },
    provider = function(self)
        local curr_line = vim.api.nvim_win_get_cursor(0)[1]
        local lines = vim.api.nvim_buf_line_count(0)
        local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
        return string.rep(self.sbar[i], 2)
    end,
    hl = { fg = colors.blue, bg = colors.bright_bg },
}
```

### LSP

Nice work! You made it ~~jumped right~~ to the main courses! The finest rice is
here.

```lua

local LSPActive = {
    condition = conditions.lsp_attached,
    update = {'LspAttach', 'LspDetach'},

    -- You can keep it simple,
    -- provider = " [LSP]",

    -- Or complicate things a bit and get the servers names
    provider  = function()
        local names = {}
        for i, server in pairs(vim.lsp.buf_get_clients(0)) do
            table.insert(names, server.name)
        end
        return " [" .. table.concat(names, " ") .. "]"
    end,
    hl = { fg = colors.green, bold = true },
}
```

[Lsp Status](https://github.com/nvim-lua/lsp-status.nvim)

```lua
-- I personally use it only to display progress messages!
-- See lsp-status/README.md for configuration options.

-- Note: check "j-hui/fidget.nvim" for a nice statusline-free alternative.
local LSPMessages = {
    provider = require("lsp-status").status,
    hl = { fg = colors.gray },
}
```

[Nvim Gps](https://github.com/SmiteshP/nvim-gps)

```lua
-- Awesome plugin
local Gps = {
    condition = require("nvim-gps").is_available,
    provider = require("nvim-gps").get_location,
    hl = { fg = colors.gray },
}
```

### Diagnostics

See how much you've messed up...

```lua
local Diagnostics = {

    condition = conditions.has_diagnostics,

    static = {
        error_icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text,
        warn_icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text,
        info_icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text,
        hint_icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text,
    },

    init = function(self)
        self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
        self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
        self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
        self.info = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
    end,

    update = { "DiagnosticChanged", "BuEnter" },

    {
        provider = "![",
    },
    {
        provider = function(self)
            -- 0 is just another output, we can decide to print it or not!
            return self.errors > 0 and (self.error_icon .. self.errors .. " ")
        end,
        hl = { fg = colors.diag.error },
    },
    {
        provider = function(self)
            return self.warnings > 0 and (self.warn_icon .. self.warnings .. " ")
        end,
        hl = { fg = colors.diag.warn },
    },
    {
        provider = function(self)
            return self.info > 0 and (self.info_icon .. self.info .. " ")
        end,
        hl = { fg = colors.diag.info },
    },
    {
        provider = function(self)
            return self.hints > 0 and (self.hint_icon .. self.hints)
        end,
        hl = { fg = colors.diag.hint },
    },
    {
        provider = "]",
    },
}
```

Let's say that you'd like to have only the diagnostic icon colored, not the
actual count. Just replace the children with something like this.

```lua
...
    {
        condition = function(self) return self.errors > 0 end,
        {
            provider = function(self) return self.error_icon end,
            hl = { fg = colors.diag.error },
        },
        {
            provider = function(self) return self.errors .. " " end,
        }
    },
...
```

Delimiters are subject to the Diagnostics component `condition`; if you'd like
them to be always visible, just wrap 'em around the component or use the `surround()`
utility!

```lua
Diagnostics = { { provider = "![" }, Diagnostics, { provider = "]" } }
-- or
Diagnostics = utils.surround({"![", "]"}, nil, Diagnostics)
```

### Git

For the ones who're not (too) afraid of changes! Uses
[gitsigns](https://github.com/lewis6991/gitsigns.nvim).

```lua
local Git = {
    condition = conditions.is_git_repo,

    init = function(self)
        self.status_dict = vim.b.gitsigns_status_dict
        self.has_changes = self.status_dict.added ~= 0 or self.status_dict.removed ~= 0 or self.status_dict.changed ~= 0
    end,

    hl = { fg = colors.orange },


    {   -- git branch name
        provider = function(self)
            return " " .. self.status_dict.head
        end,
        hl = { bold = true }
    },
    -- You could handle delimiters, icons and counts similar to Diagnostics
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = "("
    },
    {
        provider = function(self)
            local count = self.status_dict.added or 0
            return count > 0 and ("+" .. count)
        end,
        hl = { fg = colors.git.add },
    },
    {
        provider = function(self)
            local count = self.status_dict.removed or 0
            return count > 0 and ("-" .. count)
        end,
        hl = { fg = colors.git.del },
    },
    {
        provider = function(self)
            local count = self.status_dict.changed or 0
            return count > 0 and ("~" .. count)
        end,
        hl = { fg = colors.git.change },
    },
    {
        condition = function(self)
            return self.has_changes
        end,
        provider = ")",
    },
}
```

### Debugger

Display informations from [nvim-dap](https://github.com/mfussenegger/nvim-dap)!

```lua
local DAPMessages = {
    -- display the dap messages only on the debugged file
    condition = function()
        local session = require("dap").session()
        if session then
            local filename = vim.api.nvim_buf_get_name(0)
            if session.config then
                local progname = session.config.program
                return filename == progname
            end
        end
        return false
    end,
    provider = function()
        return " " .. require("dap").status()
    end,
    hl = { fg = utils.get_highlight('Debug').fg },
}
```

### Tests

This requires the great [ultest](https://github.com/rcarriga/vim-ultest).

```lua
local UltTest = {
    condition = function()
        return vim .api.nvim_call_function("ultest#is_test_file", {}) ~= 0
    end,
    static = {
        passed_icon = vim.fn.sign_getdefined("test_pass")[1].text,
        failed_icon = vim.fn.sign_getdefined("test_fail")[1].text,
        passed_hl = { fg = utils.get_highlight("UltestPass").fg },
        failed_hl = { fg = utils.get_highlight("UltestFail").fg },
    },
    init = function(self)
        self.status = vim.api.nvim_call_function("ultest#status", {})
    end,

    -- again, if you'd like icons and numbers to be colored differently,
    -- just split the component in two
    {
        provider = function(self)
            return self.passed_icon .. self.status.passed .. " "
        end,
        hl = function(self)
            return self.passed_hl
        end,
    },
    {
        provider = function(self)
            return self.failed_icon .. self.status.failed .. " "
        end,
        hl = function(self)
            return self.failed_hl
        end,
    },
    {
        provider = function(self)
            return "of " .. self.status.tests - 1
        end,
    },
}
```

### Working Directory

Always know your global or local working directory. This component, together
with FileName, will provide the full path to the edited file.

```lua
local WorkDir = {
    provider = function()
        local icon = (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. " "
        local cwd = vim.fn.getcwd(0)
        cwd = vim.fn.fnamemodify(cwd, ":~")
        if not conditions.width_percent_below(#cwd, 0.25) then
            cwd = vim.fn.pathshorten(cwd)
        end
        local trail = cwd:sub(-1) == '/' and '' or "/"
        return icon .. cwd  .. trail
    end,
    hl = { fg = colors.blue, bold = true },
}
```

### Terminal Name

Special handling of the built-in terminal bufname. See [conditional
statuslines](#conditional-statuslines) below to see an example of
dedicated statusline for terminals!

```lua
local TerminalName = {
    -- we could add a condition to check that buftype == 'terminal'
    -- or we could do that later (see #conditional-statuslines below)
    provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
        return " " .. tname
    end,
    hl = { fg = colors.blue, bold = true },
}
```

### Help FileName

See the name of the helpfile you're viewing.

```lua
local HelpFileName = {
    condition = function()
        return vim.bo.filetype == "help"
    end,
    provider = function()
        local filename = vim.api.nvim_buf_get_name(0)
        return vim.fn.fnamemodify(filename, ":t")
    end,
    hl = { fg = colors.blue },
}
```

### Snippets Indicator

This requires [ultisnips](https://github.com/SirVer/ultisnips), but the same
logic could be applied to many other snippet plugins! Get an indicator of when
you're inside a snippet and can jump to the previous and/or forward tag.

```lua
local Snippets = {
    -- check that we are in insert or select mode
    condition = function()
        return vim.tbl_contains({'s', 'i'}, vim.fn.mode())
    end,
    provider = function()
        local forward = (vim.fn["UltiSnips#CanJumpForwards"]() == 1) and "" or ""
        local backward = (vim.fn["UltiSnips#CanJumpBackwards"]() == 1) and " " or ""
        return backward .. forward
    end,
    hl = { fg = "red", bold = true },
}
```

### Spell

Add indicator when spell is set!

```lua
local Spell = {
    condition = function()
        return vim.wo.spell
    end,
    provider = 'SPELL ',
    hl = { bold = true, fg = colors.orange}
}
```

## Flexible Components

Yes, Heirline has flexible components! And, like any other component, they
can be nested and are context-aware!

Flexible components are components that will adjust their output depending on
the visible space for that window statusline.

Setting them up is as easy as calling `utils.make_flexible_component(priority, ...)`
replacing the variable `...` with a series of components that will evaluate to
decreasing lengths.

The `priority` will determine the order at which multiple flexible components will be
expanded or contracted:

- higher priority: last to contract, first to expand
- lower priority: first to contract, last to expand
- same priority: will contract or expand simultaneously

Flexible components can be nested at will, however, when doing so, the
`priority` of the nested components will be ignored and only the
**_outermost_** priority will be used to determine the order of
expansion/contraction. If you'd like nested components to have different
priorities, make sure there is enough difference between the priorities of the
outermost ("_root_") flexible components (at least `1 + (1 for each level of nesting)`),
unless you are after some very complicated behavior.

You don't need to do the math though, you can just use large numbers! If
nesting seems complex, it is because it is! Remember that you can suit most of
your needs without nesting flexible components.

Here's a **_wild_** example:

```lua
local a = { provider = string.rep("A", 40) }
local b = { provider = string.rep("B", 30) }
local c = { provider = string.rep("C", 20) }
local d = { provider = string.rep("D", 10) }
local e = { provider = string.rep("E", 8) }
local f = { provider = string.rep("F", 4) }

local nest_madness = {
    utils.make_flexible_component(1,
        a,
        utils.make_flexible_component(nil, -- nested components priority is ignored!
            b,
            utils.make_flexible_component(nil, c, d),
            e
        ),
        f
    ),
    { provider = "%=" },
    utils.make_flexible_component(4, -- 1 + 1 * 2 levels of nesting
        a,
        utils.make_flexible_component(nil,
            b,
            utils.make_flexible_component(nil, c, d),
            e
        ),
        f
    ),
}
require("heirline").setup(nest_madness)
```

And now some more useful examples!

**Flexible WorkDir** compare to [Working Directory](#working-directory)

```lua
local WorkDir = {
    provider = function(self)
        self.icon = (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. " "
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~")
    end,
    hl = { fg = colors.blue, bold = true },

    utils.make_flexible_component(1, {
        -- evaluates to the full-lenth path
        provider = function(self)
            local trail = self.cwd:sub(-1) == "/" and "" or "/"
            return self.icon .. self.cwd .. trail .." "
        end,
    }, {
        -- evaluates to the shortened path
        provider = function(self)
            local cwd = vim.fn.pathshorten(self.cwd)
            local trail = self.cwd:sub(-1) == "/" and "" or "/"
            return self.icon .. cwd .. trail .. " "
        end,
    }, {
        -- evaluates to "", hiding the component
        provider = "",
    }),
}
```

**Flexible FileName** Use this in the same context of
[Crash course part II: FileName and friends](#crash-course-part-ii-filename-and-friends)

```lua
local FileName = {
    init = function(self)
        self.lfilename = vim.fn.fnamemodify(self.filename, ":.")
        if self.lfilename == "" then self.lfilename = "[No Name]" end
    end,
    hl = { fg = utils.get_highlight("Directory").fg },

    utils.make_flexible_component(2, {
        provider = function(self)
            return self.lfilename
        end,
    }, {
        provider = function(self)
            return vim.fn.pathshorten(self.lfilename)
        end,
    }),
}
```

**Flexible Gps** _a.k.a._ make it disappear

```lua
local Gps = utils.make_flexible_component(3, Gps, { provider = "" })
```

## Putting it all together: Conditional Statuslines

With heirline you can setup custom statuslines depending on some condition.
Let's say you'd like to have something like this:

- a default statusline to be shown whenever you edit a regular file,
- a statusline for regular inactive buffers
- a statusline for special buffers, like the quickfix, helpfiles, nvim-tree, or other windowed plugins.
- a dedicated statuslines for terminals.

Because there's no actual distinction between a statusline and any of its
components, we can just use the `condition` field to affect a whole series of
components (our statusline).

Let's first define some trivial components to readily create aligned sections
and spacing where we want.

```lua
local Align = { provider = "%=" }
local Space = { provider = " " }
```

Assembling your favorite components and doing last-minute adjustments is easy!

```lua

ViMode = utils.surround({ "", "" }, colors.bright_bg, { ViMode, Snippets })

local DefaultStatusline = {
    ViMode, Space, FileName, Space, Git, Space, Diagnostics, Align,
    Gps, DAPMessages, Align,
    LSPActive, Space, LSPMessages, Space, UltTest, Space, FileType, Space, Ruler, Space, ScrollBar
}
```

**Pro-tip**: Always end a short statusline with `%=` (the Align component) to
fill the whole statusline with the same color!

```lua
local InactiveStatusline = {
    condition = function()
        return not conditions.is_active()
    end,

    FileType, Space, FileName, Align,
}
```

```lua
local SpecialStatusline = {
    condition = function()
        return conditions.buffer_matches({
            buftype = { "nofile", "prompt", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        })
    end,

    FileType, Space, HelpFileName, Align
}
```

```lua
local TerminalStatusline = {

    condition = function()
        return conditions.buffer_matches({ buftype = { "terminal" } })
    end,

    hl = { bg = colors.dark_red },

    -- Quickly add a condition to the ViMode to only show it when buffer is active!
    { condition = conditions.is_active, ViMode, Space }, FileType, Space, TerminalName, Align,
}

```

That's it! We now sparkle a bit of conditional default colors to affect all the
statuslines at once and set the flag `pick_child` via
`utils.pick_child_on_condition` to stop the evaluation at the first component
whose condition evaluates to `true`!

Note that no condition equals to `true`, so make sure that all your statuslines
but the last one have a condition set at their top-level.

**IMPORTANT**: Statuslines conditions are evaluated sequentially, so make sure
that their order makes sense! Ideally, you should order them from stricter to
looser conditions. You can always write the `init` function yourself and
leverage the `pick_child` table to have full control. See the implementation
of [`utils.pick_child_on_condition`](lua/heirline/utils.lua#L236) to have a
sense of what's going on.

```lua
local StatusLines = {

    hl = function()
        if conditions.is_active() then
            return {
                fg = utils.get_highlight("StatusLine").fg,
                bg = utils.get_highlight("StatusLine").bg
            }
        else
            return {
                fg = utils.get_highlight("StatusLineNC").fg,
                bg = utils.get_highlight("StatusLineNC").bg
            }
        end
    end,

    init = utils.pick_child_on_condition,

    SpecialStatusline, TerminalStatusline, InactiveStatusline, DefaultStatusline,
}
```

Just a bunch of nested tables with trivial fields, yet, such complex behavior!

You have learned how to define components avoiding a lot of redundancy, how you
can reutilize components, group them and tweak them easily. **_You are ready to
build your own dream StatusLine(s)!_**

```lua
require("heirline").setup(StatusLines)
-- we're done.
```

### Lion's finesse

If you want extra fine control over buftype/filetype/bufname and active/inactive
buffers, you can use the following style to define your statusline:

- First, buftype/filetype/bufname are matched against the buffer the
  statusline is displayed into to choose an appropriate branch of the genealogical
  tree.
- Then, only one component will be picked depending on if the window of the
  statusline is the current one or not.

```lua
local FelineStyle = {

    -- stop at child where buftype/filetype/bufname matches
    init = utils.pick_child_on_condition,

    {   -- Identify the buftype/filetype/bufname first
        condtion = function()
            return conditions.buffer_matches({...})
        end,

        -- Evaluate only the "active" or "inactive" child
        init = utils.pick_child_on_condition,

        {   -- If it's the current window, display some components
            condition = conditions.is_active
            {...} --
        },
        {   -- Otherwise, display some other components
            {...} --
        }
    },
    {   -- this block can be exactly as the one above for a different kind of
        -- buffer
        ...
    }
}
```

### Winbar

Everything we talked about for the statusline can be seamlessly applied
to the new Neovim `winbar`!

```lua
local WinBars = {
    init = utils.pick_child_on_condition,
    {   -- Hide the winbar for special buffers
        condition = function()
            return conditions.buffer_matches({
                buftype = { "nofile", "prompt", "help", "quickfix" },
                filetype = { "^git.*", "fugitive" },
            })
        end,
        provider = "",
    },
    {   -- A special winbar for terminals
        condition = function()
            return conditions.buffer_matches({ buftype = { "terminal" } })
        end,
        utils.surround({ "", "" }, colors.dark_red, {
            FileType,
            Space,
            TerminalName,
        }),
    },
    {   -- An inactive winbar for regular files
        condition = function()
            return not conditions.is_active()
        end,
        utils.surround({ "", "" }, colors.bright_bg, { hl = { fg = "gray", force = true }, FileNameBlock }),
    },
    -- A winbar for regular files
    utils.surround({ "", "" }, colors.bright_bg, FileNameBlock),
}

require("heirline").setup(StatusLines, WinBars)
```

## A classic: Change multiple background colors based on Vi Mode.

You may feel nostalgic about the good ol' Airline Style, where multiple
sections used to change background color based on the current mode.
Fear not! We can conveniently do that by making the mode-dominant color
visible to all components in one go.

```lua
local StatusLines = {

    hl = function()
        if conditions.is_active() then
            return {
                fg = utils.get_highlight("StatusLine").fg,
                bg = utils.get_highlight("StatusLine").bg,
            }
        else
            return {
                fg = utils.get_highlight("StatusLineNC").fg,
                bg = utils.get_highlight("StatusLineNC").bg,
            }
        end
    end,

    static = {
        mode_colors = {
            n = colors.red,
            i = colors.green,
            v = colors.cyan,
            V = colors.cyan,
            ["\22"] = colors.cyan,
            c = colors.orange,
            s = colors.purple,
            S = colors.purple,
            ["\19"] = colors.purple,
            R = colors.orange,
            r = colors.orange,
            ["!"] = colors.red,
            t = colors.green,
        },
        mode_color = function(self)
            local mode = conditions.is_active() and vim.fn.mode() or "n"
            return self.mode_colors[mode]
        end,
    },
}
```

Now the ViMode simply becomes:

```lua
local ViMode = {
    static = {
        mode_names = { ... }
    },
    provider = function(self)
        return " %2(" .. self.mode_names[vim.fn.mode(1)] .. "%)"
    end,
    hl = function(self)
        local color = self:mode_color() -- here!
        return { fg = color, bold = true }
    end,
}
```

And you can go crazy surrounding all the blocks you want with a little help from `utils.surround`.

```lua
utils.surround({ "", "" }, function(self) return self:mode_color() end, {Ruler, hl = {fg = 'black'}} ),
-- we are surrounding the component and adjusting the foreground in one go!
```

## Click it!

You can specify a function callbkack to be executed when clicking the component!
Here are some examples referring to the abovementioned components:

**Diagnostics on_click**

```lua
local Diagnostics = {

    on_click = {
        callback = function()
            require("trouble").toggle({ mode = "document_diagnostics" })
            -- or
            -- vim.diagnostic.setqflist()
        end,
        name = "heirline_diagnostics",
    },
    ...
}
```

**Git on_click**

```lua
local Git = {
    on_click = {
        callback = function()
            -- If you want to use Fugitive:
            -- vim.cmd("G")

            -- If you prefer Lazygit
            -- use vim.defer_fn() if the callback requires
            -- opening of a floating window
            -- (this also applies to telescope)
            vim.defer_fn(function()
                vim.cmd("Lazygit")
            end, 100)
        end,
        name = "heirline_git",
    },
    ...
}
```

**Window Close button**: Let the callback know from which window it was clicked from!

The following is the recommended way of achieving that:

```lua
on_click = {
    callback = function(_, winid)
        -- winid is the window id of the window the component was clicked from
    end,
    -- A dynamic name + update are required whenever
    -- we need to register a closure for each instance of the
    -- component displayed in the current tab.
    name = function(self)
        return "heirline_button_name" .. self.winnr
    end,
    update = true,
}
```

```lua
local CloseButton = {
    condition = function(self)
        return not vim.bo.modified
    end,
    -- a small performance improvement:
    -- re register the component callback only on layout/buffer changes.
    update = {'WinNew', 'WinClosed', 'BufEnter'},
    { provider = " " },
    {
        provider = "",
        hl = { fg = "gray" },
        on_click = {
            callback = function(_, winid)
                vim.api.nvim_win_close(winid, true)
            end,
            name = function(self)
                return "heirline_close_button_" .. self.winnr
            end,
            update = true,
        },
    },
}

-- Use it anywhere!
local WinBarFileName = utils.surround({ "", "" }, colors.bright_bg, {
    hl = function()
        if not conditions.is_active() then
            return { fg = "gray", force = true }
        end
    end,
    FileNameBlock,
    Space,
    CloseButton,
})
```

**Debugger on_click**: step-over, step-into, next, previous, stop buttons

```lua
--    coming soon!
```

## Theming

You can change the colors of the statusline automatically whenever you change
your colorscheme. To do so, just setup a `ColorScheme` event autocommand that
will reset heirline highlights and re-source your config!

You can achieve that in two ways:

1. Wrapping the generation of the statusline blueprints (components) into a function

```lua
-- beginning of your heirline config file
local M = {}
function M.setup()

... -- wrap everything into a function

require("heirline").setup(StatusLines)
end

-- setup the autocommand
vim.cmd[[
augroup heirline
    autocmd!
    autocmd ColorScheme * lua require'heirline'.reset_highlights(); require'plugins.heirline'.setup()
augroup END
]]

M.setup() -- call setup when the file is required the first time
return M

-- end of your heirline config file
```

2. Using `:luafile` to reload your config.

```lua
-- beginning of your heirline config file, no need to wrap anything

...

vim.cmd[[
augroup heirline
    autocmd!
    autocmd ColorScheme * lua require'heirline'.reset_highlights(); vim.cmd('luafile <path-to-this-file>')
augroup END
]]

require("heirline").setup(statuslines)

-- end of your heirline config file
```

<p align="center">
  <h2 align="center">Fin. :spoon:</h2>
</p>

<p align="center">Config for heirline.nvim took 0.000786ms</p>

<p align="center">
  <img width="1156" alt="heirline_statusline" src="https://user-images.githubusercontent.com/36300441/149607860-4d2ac414-e0d4-48bf-991e-6ef3022a1e79.png">
</p>
