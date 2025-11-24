# Setup

To run the plugin (inside ./refact-plug, which is not ./refact-plug/lua/refact-plug), do

```nvim -c "set rtp+=."```

To run the plugin function ```hello()```, do

```:lua require('refact-plug').hello()```

Alternatively, you can do all in one command:

```nvim -c "set rtp+=. | lua require('refact-plug').hello()"```

# Testing

You can open a file to test it on the go. To test RenameVar refactoring, do the following:
- Run `nvim -c "set rtp+=. | lua require('refact-plug').setup()" test.cpp`
- Now nvim should be opened (with no error warnings), with a cpp file
- Run the nvim command `:RenameVar x y`, and see the renaming happening.

# How to implement a new refactoring

Write relevant code on ```./lua/refact-plug/init.lua```. Follow the example of the Rename Variable refactoring. To create a new refactoring, two steps are needed.

1) Create a lua function implementing it (ex: M.rename_variable)
2) Create a vim command so that the user can call the function (in M.setup)

I have created a new file for refactorings, `./lua/refact-plug/refactorings.lua`. Implement refactorings there, and after create a new user command in `init.lua.setup()`.

The main sources of help will be
- nvim help docs. For example: `:help treesitter.get_parser()`
- there are some ytb videos on how to write a lua plugin
- chat gpt?

# Troubleshooting:

If the plugin does not seem to work... 

After entering vim with set rtp, check if the `.` folder appears on 

```:echo &rtp```

If it dosent, try changing the command from `.` to `./`:

```nvim -c "set rtp+=/.```

---

# DOCS

### RenameVar

```:RenameVar {source} {target}```

Renames a variable from {source} to {target} within the current buffer using
Tree-sitter. This command is restricted only to variables, ignoring comments or strings.

Arguments: 
```
    {source}    The current name of the variable (identifier) to be renamed.
    {target}    The new name for the variable.
```

Example (Renames all instances of identifier 'cnt' to 'counter')
```
    :RenameVar cnt counter
```
### ExtractMethod

```:'<,'>ExtractMethod {method_name}```

Extracts the visually selected lines of code into a new `void` method named {method_name}.
The selection is replaced by a function call, and the new method definition is inserted
automatically (usually before the current function or at the end of the file).

Arguments:
```
    {method_name}   The name of the new function to be created containing the selected code.
```

Example (Selects a 'for' loop and extracts it to a function named 'process_data')
```
    :'<,'>ExtractMethod process_data
```

### InlineMethod

```:InlineMethod {method_name}```

Replaces all occurrences of calls to {method_name} with the method's actual body logic.
It performs argument substitution (mapping call arguments to function parameters) and
deletes the original function definition after inlining.

Arguments:
```
    {method_name}   The name of the existing function to be inlined.
```

Example (Inlines the 'helper_calc' function into all places it is called)
```
    :InlineMethod helper_calc
```

### EncapsulateField

```:EncapsulateField```

Encapsulates the C++ field (attribute) currently under the cursor. It generates standard
public Getter and Setter methods and moves the field itself to the `private` section of the
class/struct. If `public` or `private` sections do not exist, they are created automatically.

Arguments:
```
    None            (This command acts on the line currently under the cursor).
```

Example (With cursor positioned on 'int age;', generates getAge/setAge and privatizes 'age')
```
    :EncapsulateField
```
