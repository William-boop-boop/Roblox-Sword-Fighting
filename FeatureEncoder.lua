local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")
local Config = require(pkg:WaitForChild("Config"))

local M = {}

-- If you compute dynamic size elsewhere, replace this body to return that number
function M.outputSize()
	return tonumber(Config.FEATURE_DIM) or 0
end

return M