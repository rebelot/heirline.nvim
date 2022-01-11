# Cookbook.md

## Index

- [Main concepts](#main-concepts)
- [Component fields](#component-fields)
- [Builtin conditions and utilities](#builtin-conditions-and-utilities)
- [Recipes](#recipes)
  - [Getting started](#getting-started)
  - [Colors, colors, more colors](#colors-colors-more-colors)
  - [ViMode](#vimode)
  - [FileName, FileType, FileModified, and firends](#filename-filetype-filemodified-and-firends)
  - [Ruler](#ruler)
  - [FileSize](#filesize)
  - [LSP](#lsp)
  - [Diagnostics](#diagnostics)
  - [Git](#git)
  - [Debugger](#debugger)
  - [Tests](#tests)
  - [Working Directory](#working-directory)
  - [Terminal Name](#terminal-name)
  - [Helpfile Name](#helpfil-name)
  - [Snippets Indicator](#snippets-indicator)
  - [Conditional Statuslines](#conditional-statuslines)
- [Putting it all together](#putting-it-all-together)

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
don't let the detailed description discourage you! Just keep one thing in mind:
whenever you see a function, know that the function is executed in the context
of the buffer and window the statusline belongs to. (The indices of the actual
buffer and window you're in are stored in the default vim global variables
`vim.g.actual_curbuf` and `vim.g.acutal_curwin`.)

> Note that all functions described below are actual methods of the component
> itself, which can be accessed via the `self` parameter. Because of inheritance,
> children will look for unknown keywords within their own parent fields.

Each component may contain _any_ of the following fields:

**Basic fields**:

- `provider`:
  - Type: `string` or `function(self) -> string|nil`
  - Description: This is the string that gets printed in the statusline. No
    escaping is performed, so it may contain sequences that have a special
    meaning within the statusline, such as `%f` (filename), `%p` (percentage
    through file), `%-05.10(` `%)` (to control text alignment and padding),
    etc. For more, see `:h 'statusline'`. To print an actual `%`, use `%%`.
- `hl`:
  - Type: `table` or `function(self) -> table`. The table may contain any of:
    - `fg`: The foreground color. Type: `string` to hex color code or vim
      builtin color name (eg.: `"#FFFFFF"`, `"red"`).
    - `bg`: The background color. Type: as above.
    - `guisp`: The underline/undercurl color, if any. Type: as above.
    - `style`: Any of the supported comma-separated highlight styles:
      `italic`, `bold`, `underline`, `undercurl`, `reverse`, `nocombine` or
      `none`. (eg.: `"bold,italic"`)
  - Description: `hl` controls the colors of what is printed by the
    component's `provider`, or by any of its descendants. At evaluation time,
    whenever a `child` inherits its parent's `hl` (whether a function or
    table), this gets updated with the child's `hl`, so that, when specified,
    the fields in the child `hl` will always take precedence.
- `condition`:
  - Type: `function(self) -> any`
  - Description: This function controls whether the component should be
    evaluated or not. The truth of the return value is tested, so any value
    besides `nil` and `false` will evaluate to true. Of course, this will
    affect all of the component's progeny.
- `{...}`:
  - Type: `list`
  - Description: The component progeny. Each item of the list is a component
    itself and may contain any of the basic and advanced fields.

**Advanced fields**

- `stop_at_first`:
  - Type: `bool`
  - Description: If a component has any child, their evaluation will stop at
    the first child in the succession line who does not return an empty
    string. This field is not inherited by the component's progeny. Use this
    in combination with children conditions to create buffer-specific
    statuslines! (Or do whatever you can think of!)
- `init`:
  - Type: `function(self) -> any`
  - Description: This function is called whenever a component is evaluated
    and can be used to modify the state of the component itself via the
    `self` parameter. For example, you can compute some values that will be
    accessed from other functions within the component genealogy.
- `static`:
  - Type: `table`
  - Description: This is a container for static variables, that is, variables
    that are known when you define the component. This is useful to organize
    data that should be shared among children, like icons or dictionaries.
    Any keyword defined within this table can be accessed by the component
    and its children as a direct attribute using the `self` parameter passed
    to the functions described here. (eg: `static = { x = ... }` can be
    accessed as `self.x` somewhere else).
- `restrict`:
  - Type: `table[keyword = bool]`
  - Description: Set-like table to control which component fields can be
    accessed by the component's progeny. The supplied table gets merged with
    the defaults. By default, the following fields are private to the
    component: `stop_at_first`, `init`, `provider`, `condition` and
    `restrict`. Attention: modifying the defaults could dramatically affect
    the behavior of the component!
    (eg: `restrict = { my_private_var = true, provider = false }`)

Confused yet? Don't worry, everything will come together in the [Recipes](#recipes) examples.

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
- `width_percent_below(N, threshold)`: returns true if `(N / current_window_width) <= threshold`
  (eg.: `width_percent_below(#mystring, 0.33)`)
- `is_git_repo()`: returns true if the file is within a git repo (uses [gitsigns]())
- `has_diagnostics()`: returns true if there is any diagnostic for the buffer.
- `lsp_attached():` returns true if an LSP is attached to the buffer.

**Utility functions**:

- `get_highlight(hl_name)`: returns a table of the attributes of the provided
  highlight name. The returned table contains the same `hl` fields described
  above.
- `clone(component[, with])`: returns a new component which is a copy of the
  supplied one, updated with the fields in the optional `with` table.
- `surround(delimiters, color, component)`: returns a new component, which
  contains a copy of the supplied one, surrounded by the left and right
  delimiters supplied by the `delimiters` table. This action will override the
  `bg` field of the component `hl`.
  - `delimiters`: table of the form `{left_delimiter, right_delimiter}`.
    Because these are actually just providers, delimiters could also be
    functions!
  - `color`: `nil` or `string` of color hex code or builtin color name. This
    color will be the foreground color of the delimiters and the background
    color of the component.
  - `component`: the component to be surrounded.

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

If you want your statusline to blend nicely with your colorscheme, the utility
function `get_highlight()` is your friend.

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

Perhaps, your favourite colorscheme already provides a way to get the theme colors.

```lua
local colors = require'kanagawa.colors'.setup() -- wink
```

### ViMode

No statusline is worth its weight in _fancyness_ :star2: without an appropriate
mode indicator. So let's write ours! Also, this snippet will show you a lot of
heirline advanced capabilities.

```lua
local ViMode = {
    -- get vim current mode, this information will be required by the provider
    -- and the highlight, so we compute it only once per component evaluation
    -- and store it as a component attribute
    init = function(self)
        self.mode = vim.fn.mode(1) -- :h mode()
    end,
    -- Now we define some dictionaries to map the output of mode() to the
    -- corresponding string and color. We can put these into `static` to compute
    -- them at initialisation time.
    static = {
        mode_names = {
            n = "N", no = "N?", nov = "N?", noV = "N?", ["no"] = "N?", niI =
            "Ni", niR = "Nr", niV = "Nv", nt = "Nt", v = "V", vs = "Vs", V =
            "V_", Vs = "Vs", [""] = "^V", ["s"] = "^V", s = "S", S = "S_",
            [""] = "^S", i = "I", ic = "Ic", ix = "Ix", R = "R", Rc = "Rc",
            Rx = "Rx", Rv = "Rv", Rvc = "Rv", Rvx = "Rv", c = "C", cv = "Ex", r
            = "...", rm = "M", ["r?"] = "?", ["!"] = "!", t = "T",
        },
        mode_colors = {
            n = colors.red ,
            i = colors.green,
            v = colors.cyan,
            V =  colors.cyan,
            [""] =  colors.cyan, -- this is an actual ^V, type <C-v><C-v> in insert mode
            c =  colors.orange,
            s =  colors.purple,
            S =  colors.purple,
            [""] =  colors.purple, -- this is an actual ^S, type <C-v><C-s> in insert mode
            R =  colors.orange,
            r =  colors.orange,
            ["!"] =  colors.red,
            t =  colors.red,
        }
    },
    -- We can now access the value of mode() that, by now, would have been
    -- computed by `init()` and use it to index our strings dictionary.
    -- note how `static` fields become regular attributes once the component is
    -- instantiated.
    -- To be extra meticulous, we can also add some vim statusline syntax to
    -- control the padding and make sure our string is always at least 2
    -- characters long
    provider = function(self)
        return "%-2("..self.mode_names[self.mode].."%)"
    end,
    -- Same goes for the highlight. Now the foreground will change according to the current mode.
    hl = function(self)
        local mode = self.mode:sub(1, 1) -- get only the first mode character
        return {
            fg = self.mode_colors[mode],
            style = "bold",
        }
    end,
}
```

### FileName, FileType, FileModified, and firends

```lua
local FileName = {
    init = function(self)
        self.filename = vim.api.nvim_buf_get_name(0)
        self.extension = vim.fn.fnamemodify(self.filename, ":e")
    end,
    -- the following component will be the file icon!
    {
        init = function(self)
            self.icon, self.icon_color = require("nvim-web-devicons").get_icon_color(
                self.filename,
                self.extension,
                { default = true }
            )
        end,
        provider = function(self)
            return self.icon and (self.icon .. " ")
        end,
        hl = function(self)
            return { fg = self.icon_color, link = false }
        end,
    },
    -- this is the actual file name, relative to the current directory
    {
        provider = function(self)
            return vim.fn.fnamemodify(self.filename, ":.")
        end,
        hl = { fg = utils.get_highlight("Directory").fg },
    },
    -- this is the default modified [+] or readonly [-] state
    {
        provider = function()
            return "%m"
        end,
        hl = { fg = utils.get_highlight("String").fg },
    },
}

local FileType = {
    provider = function()
        return string.upper(vim.bo.filetype)
    end,
    hl = { fg = utils.get_highlight("Type").fg },
}
```

### Ruler

```lua
local Ruler = {
    provider = "%(%l/%3L%):%2c",
}
```

### FileSize

wip

### LSP

```lua

local LSPActive = {
    condition = function()
        return next(vim.lsp.buf_get_clients(0)) ~= nil
    end,
    provider = " [LSP]",
    hl = { fg = colors.green, style = "bold" },
}

local LSPMessages = {
    provider = function()
        local status = require("lsp-status").status()
        if status ~= " " then
            return status
        end
    end,
    hl = { fg = colors.gray },
}

local Gps = {
    condition = function()
        return require("nvim-gps").is_available()
    end,

    provider = function()
        return require("nvim-gps").get_location()
    end,
    hl = { fg = colors.gray },
}
```

### Diagnostics

```lua
local Diagnostics = {

    condition = function()
        return #vim.diagnostic.get(0) > 0
    end,

    {
        provider = "![",
    },
    {
        provider = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
            local icon = vim.fn.sign_getdefined("DiagnosticSignError")[1].text
            return count > 0 and (icon .. count .. " ")
        end,
        hl = { fg = colors.diag.error },
    },
    {
        provider = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
            local icon = vim.fn.sign_getdefined("DiagnosticSignWarn")[1].text
            return count > 0 and (icon .. count .. " ")
        end,
        hl = { fg = colors.diag.warn },
    },
    {
        provider = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
            local icon = vim.fn.sign_getdefined("DiagnosticSignInfo")[1].text
            return count > 0 and (icon .. count .. " ")
        end,
        hl = { fg = colors.diag.info },
    },
    {
        provider = function()
            local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
            local icon = vim.fn.sign_getdefined("DiagnosticSignHint")[1].text
            return count > 0 and (icon .. count)
        end,
        hl = { fg = colors.diag.hint },
    },
    {
        provider = "]",
    },
}
```

### Git

```lua
local Git = {
    condition = function()
        return vim.b.gitsigns_status_dict or vim.b.gitsigns_head
    end,

    init = function(self)
        self.dict = vim.b.gitsigns_status_dict
    end,

    hl = { fg = utils.get_highlight("WarningMsg").fg },

    {
        provider = function(self)
            return " " .. self.dict.head .. "("
        end,
    },
    {
        provider = function(self)
            local count = self.dict.added or 0
            return count > 0 and ("+" .. count)
        end,
        hl = { fg = colors.git.add },
    },
    {
        provider = function(self)
            local count = self.dict.removed or 0
            return count > 0 and ("-" .. count)
        end,
        hl = { fg = colors.git.del },
    },
    {
        provider = function(self)
            local count = self.dict.changed or 0
            return count > 0 and ("~" .. count)
        end,
        hl = { fg = colors.git.change },
    },
    {
        provider = ")",
    },
}
```

### Debugger

```lua
local DAPMessages = {
    condition = function()
        local session = require("dap").session()
        if session then
            local filename = vim.api.nvim_buf_get_name(0)
            if session.config then
                local progname = session.config.program
                return filename == progname
            end
        end
    end,
    provider = function()
        return " " .. require("dap").status()
    end,
    hl = { fg = "red" },
}
```

### Tests

```lua
local UltTest = {
    condition = function()
        return vim.api.nvim_call_function("ultest#is_test_file", {}) ~= 0
    end,
    init = function(self)
        self.passed_icon = vim.fn.sign_getdefined("test_pass")[1].text
        self.failed_icon = vim.fn.sign_getdefined("test_fail")[1].text
        self.passed_hl = { fg = utils.get_highlight("UltestPass").fg }
        self.failed_hl = { fg = utils.get_highlight("UltestFail").fg }
        self.status = vim.api.nvim_call_function("ultest#status", {})
    end,
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

```lua
local WorkDir = {
    provider = function()
        local icon = (vim.fn.haslocaldir(0) == 1 and "l" or "g") .. " " .. " "
        local cwd = vim.fn.getcwd(0)
        cwd = vim.fn.fnamemodify(cwd, ":~")
        cwd = vim.fn.pathshorten(cwd)
        return icon .. cwd .. "/"
    end,
    hl = { fg = colors.blue },
}
```

### Terminal Name

```lua
local TerminalName = {
    provider = function()
        local tname, _ = vim.api.nvim_buf_get_name(0):gsub(".*:", "")
        return " " .. tname
    end,
    hl = { fg = colors.blue, style = "bold" },
}
```

### Helpfile Name

```lua
local HelpFilename = {
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

```lua
local Snippets = {
    provider = function()
        local fwd = ""
        local bwd = ""
        if vim.fn["UltiSnips#CanJumpForwards"]() == 1 then fwd = "" end
        if vim.fn["UltiSnips#CanJumpBackwards"]() == 1 then bwd = " " end
        return vim.tbl_contains({ "s", "i" }, vim.fn.mode()) and (bwd .. fwd) or ""
    end,
    hl = { fg = "red", syle = "bold" },
}
```

## Putting it all together

```lua

local DefaultStl = {
    -- hl = { bg = "blue" },
    utils.surround({ "", "" }, utils.get_highlight("NonText").fg, { ViMode, Snippets })
    {provider = ' '},
    FileName,
    {provider = ' '},
    {provider = '%<'},
    Git,
    {provider = ' '},
    Diagnostics,
    {provider = '%='},

    Gps,
    {provider = ' '},
    DAPMessages,
    {provider = '%='},

    LSPActive,
    {provider = ' '},
    LSPMessages,
    {provider = ' '},
    UltTest,
    {provider = ' '},
    FileType,
    {provider = ' '},
    Ruler,
}

local SpecialStl = {
    condition = function()
        return conditions.buffer_matches({
            buftype = { "nofile", "help", "quickfix" },
            filetype = { "^git.*", "fugitive" },
        })
    end,
    FileType,
    {provider = ' '},
    HelpFilename,
}

local TerminalStl = {
    condition = function()
        return conditions.buffer_matches({ buftype = { "terminal" } })
    end,
    hl = { bg = utils.get_highlight("DiffDelete").bg },
    {
        condition = conditions.is_active,
        ViMode,
    },
    {provider = ' '},
    FileType,
    {provider = ' '},
    TerminalName,
}

local InactiveStl = {
    condition = function()
        return not conditions.is_active()
    end,
    FileType,
    {provider = ' '},
    FileName,
}

local statuslines = {
    stop = true,
    SpecialStl,
    TerminalStl,
    InactiveStl,
    DefaultStl,
}

require("heirline").setup(statuslines)
-- we're done.
```
