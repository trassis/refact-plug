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

# TODO list

In the specification, we said that we would implement 5 refactorings. The easier ones seems to be:

- [x] Method extraction
- [ ] Method inlining
- [x] Renaming of variables
- [ ] Encapsulate Atribute (from public to private get and set)
- [ ] ??? We need another one ???

Another option is to also implement indentification and warning of code smells

- [x] large lines
- [ ] cod duplicado
- [ ] metodos longos
- [ ] classes grandes
- [ ] metodos com mts parametros

Notes

- Method extraction can be made better. We can identify declarations that become invalid after extraction, and insert them as parameters.

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
