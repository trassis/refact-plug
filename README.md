## Setup

To run the plugin, do

```nvim -c "set rtp+=.```

To run the plugin function ```hello()```, do

```:lua require('refact-plug').hello()```

Alternatively, you can do all in one command:

```nvim -c "set rtp+=. | lua require('refact-plug').hello()```

---

## Troubleshooting:

after entering vim with set rtp, check if the `.` folder appears on 

```:echo &rtp```

If it dosent, try changing the command from `.` to `./`:

```nvim -c "set rtp+=/.```

--- 

## TODO list

We need to implement 5 refactorings. The easiest ones to do maybe are:

- [ ] Method extraction
- [ ] Method inlining
- [x] Renaming of variables :white-check-mark
- [ ] Encapsulate Atribute (from public to private get and set)

Another option is to also implement indentification of code smells

- [ ] Tambem indentificar alguns code smells?
- [ ] cod duplicado
- [ ] metodos longos
- [ ] classes grandes
- [ ] metodos com mts parametros

---

## DOCS

#### Rename Variable

```:RenameVar <source> <target>```

