## Setup

To run the plugin, do

```nvim -c "set rtp+=.```

To run the plugin function ```hello()```, do

```:lua require('refact-plug').hello()```

Alternatively, you can do all in one command:

```nvim -c "set rtp+=. | lua require('refact-plug').hello()```

We write the relevant code on ```./lua/refact-plug/init.lua```. Follow the example of the Rename Variable refactoring. To create a new refactoring, two steps are needed.

1) Create a lua function implementing it (ex: M.rename_variable)
2) Create a vim command so that the user can call the function (in M.setup)

The main sources of help will be
- nvim help docs. For example: `:help treesitter.get_parser()`
- there are some ytb videos on how to write a lua plugin
- chat gpt?

---

## Troubleshooting:

after entering vim with set rtp, check if the `.` folder appears on 

```:echo &rtp```

If it dosent, try changing the command from `.` to `./`:

```nvim -c "set rtp+=/.```

--- 

## TODO list

In the specification, we said that we would implement 5 refactorings. The easier ones seems to be:

- [ ] Method extraction
- [ ] Method inlining
- [x] Renaming of variables
- [ ] Encapsulate Atribute (from public to private get and set)
- [ ] ??? We need another one ???

Another option is to also implement indentification and warning of code smells

- [ ] cod duplicado
- [ ] metodos longos
- [ ] classes grandes
- [ ] metodos com mts parametros

---

## DOCS

*RenameVar*

```:RenameVar {source} {target}```

Renames a variable from {source} to {target} within the current buffer using
Tree-sitter. This command is restricted only to variables, ignoring comments or strings.

Arguments: 
    {source}    The current name of the variable (identifier) to be renamed.
    {target}    The new name for the variable.

Example: 
    ```:RenameVar cnt counter```
    " Renames all instances of identifier 'cnt' to 'counter'
