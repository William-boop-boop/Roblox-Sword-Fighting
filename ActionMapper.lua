-- ServerStorage/AIPolicy/ActionMapper  (ModuleScript)
local M = {}

-- Keep this list tiny and obvious while we debug
M._actions = {"Idle","Chase","Slash","Hop"}

function M.count()
	return #M._actions
end

function M.actions()
	return M._actions
end

-- optional, lets you hot-swap later if you want
function M.setActions(list)
	assert(type(list)=="table" and #list>0, "setActions expects a nonempty array")
	M._actions = table.clone(list)
end

return M
