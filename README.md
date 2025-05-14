# fish-compbase
compbase is a Fish shell tool for managing dynamic completions.

You can use this tool to dynamically add completion items, then utilize them in your completion scripts.

# Dependencies
- sqlite3

# Usage
The `compbase` has three subcommands: `topic`, `item`, `conf`.

`topic` is a namespace for completion items. Use topics to manage completion suggestions for command options.
`item` represents individual completion entries.
`conf` stores configuration settings.

# Demo
## Adding Items to compbase
In your Fish shell function, you can add items to any topic (which will be created automatically). Example:
```fish
open "https://github.com/$repo"
if functions -q compbase
    compbase item -t gho -a -D "https://github.com/$repo" "$repo"
end
```

## Using Completions in Complete Declarations
In your completion scripts, source items using `compbase item -t gho -o`. Example:
```fish
complete gho -f
if functions -q compbase
    complete gho -a "(compbase item -t gho -l)"
end
```
