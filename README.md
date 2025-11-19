To run the plugin, do

```nvim -c "set rtp+=.```

(if this does not work, try `nvim -c "set rtp+=.`)

and on nvim, run

```:lua require("refact-plug").hello()```

Alternatively, you can do all in one command:

```nvim -c "set rtp+=. | lua require("refact-plug").hello()```
