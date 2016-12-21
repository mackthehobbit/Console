# Console
Console is a Minecraft: Pocket Edition mod for debugging other ModPE scripts and executing JavaScript in-game.

Currently, the two main features are:

- Execute/evaluate JavaScript statements in the context of any mod. For example, to check the values of global variables in your own script.
- Live-reload scripts while the game is running. This can be performed while in a world, and a hook is supported to notify scripts when they have been reloaded. Variables may be preserved across a reload.

## In-Game usage
Chat commands are as follows:

- `/scripts`: List all available script filenames. Useful to see what the exact filename of each script is.
- `/debug [Script filename]` or `/db`: Start debugging the named script. Note that the given name only needs to match the start of the filename, so `Console.js` is matched by `Console` or just `C`. However, if multiple script names match, one of them is selected arbitrarily. To stop debugging, simply omit the name.
- `/reload` or `/rl`: Reload the currently-debugged script. See Live-Reloading below.

Additionally, once a script to debug has been selected, JavaScript may be evaluated in the chat by preceding a chat message with the `>` character. This is performed in the context of the current script, so global variables and functions belonging to the script are accessible by name. The value of an expression entered is returned in chat.

For example, `>10+10` will return `<- 20` while `> Player.addItemInventory(1, 1, 0)` executes the corresponding statement. You could also examine a global variable in your script or modify it, such as `> position += 2`.

In this way, the chat behaves like a JavaScript *Console*.

## Live-Reloading
Live-reloading is supported by Console. To use this feature, first enable "Reimport modified scripts" in BlockLauncher, then import your script from the device's local storage. When the imported file is modified, BlockLauncher would normally reimport it upon starting up, but this can be done in-game by selecting it for debugging and then using the `/reload` command (or its alias, `/rl`).

As a side effect of a script reload, all global variables etc. are cleared from your script. However, Console gives you an opportunity to copy over values from the old state of the script by the use of its own hook. If your script contains a function named `onDebugReload`, Console will call it immediately after reloading and pass the old state of the script as the first argument.

For example, Console's own `onDebugReload` hook saves the global `currentScript` variable across a reload. The JavaScript equivalent is the following:

```javascript
function onDebugReload(oldScope) {
    currentScript = oldScope.currentScript;
}
```
However, you aren't restricted to just copying over variables. You may want to call your own initialisation functions such as `newLevel` since the event for those hooks have effectively been missed.

## Example Workflow
Console is most useful for modders who develop on a PC and deploy to a physical device. An example workflow (the same used by Console itself) is:

1. Deploy and start debugging the script under development.
2. Make changes to mod script/package on PC and deploy (to the existing location) using ADB or another tool.
3. Execute `/reload`. The `onDebugReload` method is called in the script and variables are copied to the new state of the script.
4. Test features, then go to 2.

## Building
Console is written in Coffeescript. To compile to JavaScript, use a Coffeescript compiler. The `--bare` option *must* be used to ensure that ModPE hooks are accessible at the top level scope. As Console is currently built on Windows, a script `make.cmd` is provided to watch the source directory for changes and compile into Console.js. For non-windows systems, the compile command is the same.

## Planned Features
- Allow global variables to be copied automatically. This process would need information regarding which variables need to be copied over and which should be taken from the new script (such as constants modified in the source code). 
- Automate live-reloading by watching for filesystem changes.
- Allow watch expressions to be added, either in-game or in source code. These would be updated every tick, or at specified points/function calls?
- Add support for 'breakpoints' that could be set at any point in code, or by attaching them to functions when in-game. When reached, the debugged script would block until a command is given in-game so variables could be examined. This may not be possible depending on BL's thread model.
