# simple-cli

Building Ruby CLIs with easy.

## Philosophy

Building a command line could be much easier than what ruby provides with its standard library. In general, between the invocation of a tool from the command line and the actual running of whatever code the user intends to run really should disappear.

Ideally a developer would only have to build the implementation of whatever logic should be provided by the tool; everything else - parsing arguments, calling the tool's implementation, printing help - should happen automatically.

This is roughly what sinmple-sql provides. 

## On versions

`simple-cli` is still on a 0.x.x version, and, generally, a 0.x.y version is not compatible with a 0.x+1.y version.

These are the follow

- The 0.2.x versions are tracked in the [`stable`](https://github.com/radiospiel/simple-cli/tree/stable) branch
- The 0.3.x versions are tracked in the [`master`](https://github.com/radiospiel/simple-cli/tree/stable) branch

## Basic features

- build command line features in a number of modules;
- public methods in these modules provide a subcommand for the CLI;
- `"_"` in the method name are being mapped to `":"` in the CLI;
- CLI provides a help subcommand. help texts are derived from the methods over a subcommand implementation:
  - The first line determines the "short help" message, to be included in the `$CMD help` command list;
  - The remaining lines determines the full help message, to be included in the `$CMD help subcommand` message.
  
## Example

