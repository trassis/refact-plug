# Refact-Plug

refact-plug is a Neovim plugin built in Lua that uses Tree-sitter to execute precise, automated code refactorings. It provides essential commands for structural code manipulation, enhancing maintenance efficiency.

# Instalation

Install with your favorite plugin manager, such as lazy.nvim:
```
{
    "trassis/refact-plug",
    config = function()
        require("refact-plug").setup()
    end,
}
```

# Documentation

## Refactoring 

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

## Code Smells (Passive Warnings)

The following features do not require a command to run. They automatically analyze the code in the current buffer and display warnings (underlined text) to indicate potential code smells.

### Long Line

Highlights lines of code that exceed the configured maximum character limit (80 characters).

**Behavior:**
The entire line (or the segment exceeding the limit) is underlined to indicate that it affects readability and requires horizontal scrolling.

**Example:**
```cpp
// This line will be underlined if it exceeds the column limit:
int result = extremely_long_function_name_that_does_not_fit_in_screen(param1, param2, param3, ...);
```
### Duplicate code

Detects identical blocks of code appearing in multiple locations within the file or project, violating the DRY (Don't Repeat Yourself) principle.

**Behavior:**
The duplicated lines or blocks are underlined. Hovering over the warning usually indicates that this logic exists elsewhere.

### Large classes

Identifies classes or structs that have become too complex, containing an excessive number of methods, attributes, or lines of code. This often indicates a "God Object" anti-pattern.

**Behavior:**
The entire line (or the segment exceeding the limit) is underlined to indicate that it affects readability and requires horizontal scrolling.

### Methods with many parameters

Flags function or method definitions that require a large number of arguments. This suggests that the method might be doing too much or that the parameters should be encapsulated into a specific object or struct.

**Behavior:**
The function signature (specifically the parameter list) is underlined if the count exceeds a predefined threshold (5 paramaters).
