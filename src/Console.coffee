
###
  
  Console: A Minecraft: Pocket Edition mod for debugging other ModPE scripts
  github.com/mackthehobbit/Console
  version 1.0

###

# reference to BL script manager for reloading and scope manipulation
ScriptManager = net.zhuoweizhang.mcpelauncher.ScriptManager
scripts = ScriptManager.scripts

# utility methods
error = (string) -> ChatColor.RED + string + ChatColor.WHITE
warning = (string) -> ChatColor.YELLOW + string + ChatColor.WHITE
positive = (string) -> ChatColor.GREEN + string + ChatColor.WHITE
scriptNotFound = (string) -> error("Script not found: " + string)

# current debugged script name
currentScript = undefined

# return full script name matching selector
getModNameFuzzy = (selector) ->
  for i in [0...scripts.size()]
    name = scripts.get(i).name
    if name.startsWith selector
      return name
  return undefined

# return the scope for the specified script
getScope = (script) ->
  for i in [0...scripts.size()]
    scriptState = scripts.get(i)
    # hack since java String isnt javascript string, and 'is' is strict
    if scriptState.name.equals(script)
      return scriptState.scope
  return undefined

# evaluate javascript expression in the current script
evalInScript = (expr) ->
  # error if no current script
  if not currentScript?
    return error "Not currently debugging."
  scope = getScope(currentScript)
  # error if scope cannot be found
  return scriptNotFound(currentScript) unless scope?
  # wrap eval statement with the scope
  func = new Function("with(this) { return eval(" + expr + ") }");
  return func.call(scope);

newLevel = ->
  clientMessage positive "Console is loaded."

# check for javascript request in chat
chatHook = (string) ->
  if string[0] is '>'
    preventDefault()
    clientMessage '<- ' + evalInScript(string[1..])

# hook for when the script is used to reload itself
onDebugReload = (oldScope) ->
  currentScript = oldScope.currentScript

# check for commands in chat
procCmd = (string) ->
  args = string.split(" ")

  if args[0] is "debug" or args[0] is "db"
    selector = args[1..]?.join(" ")
    if not selector?.length
      currentScript = undefined
      clientMessage "Stopped all debugging."
    else
      # match remaining arguments for script name
      name = getModNameFuzzy(selector)
      if name?
        clientMessage "Now debugging: " + positive name
        clientMessage "Type '> [expression] to eval javascript."
        currentScript = name
      else
        clientMessage error "No script matching " + selector
        currentScript = undefined

  if args[0] is "reload" or args[0] is "rl"
    # error if not debugging
    if not currentScript?
      clientMessage error "Not currently debugging."
    # save old scope for onDebugReload hook
    oldScope = getScope(currentScript)
    # re-import with BL methods
    f = ScriptManager.getScriptFile(currentScript)
    if ScriptManager.reimportIfPossible(f)
      ScriptManager.reloadScript(f)
      clientMessage positive("Reloaded " + currentScript)
      newScope = getScope(currentScript)
      # call hook with old scope if it exists and is a function
      if newScope.onDebugReload?
        clientMessage positive "Calling reload hook"
        newScope.onDebugReload?(oldScope)
      else
        clientMessage warning "Script does not have a reload hook."
    # error if unable to re-import
    else
      clientMessage error("Could not reload " + currentScript)

  if args[0] is "scripts"
    # list count and script names
  	clientMessage positive(scripts.size()) + " scripts active:"
  	for i in [0...scripts.size()]
  		clientMessage scripts.get(i).name
