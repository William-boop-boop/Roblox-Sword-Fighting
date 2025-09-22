-- ServerStorage/AIPolicy/ActionDispatcher
local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local ActionMapper = require(pkg:WaitForChild("ActionMapper"))
local AgentIndex   = require(pkg:WaitForChild("AgentIndex"))
local Move         = require(pkg:WaitForChild("MovementBasic"))

local M = {}

local function pickEnemyOrTarget(agent)
	local target = select(1, AgentIndex.pickEnemy(agent))
	if target then return target end
	return select(1, AgentIndex.pickTarget(agent))
end

-- Call with a function(agent) -> idx, name
function M.dispatchAll(actionSelector, dt)
	local actions = ActionMapper.actions()
	for _, agent in ipairs(AgentIndex.listAgents()) do
		local idx, name = actionSelector(agent)
		name = name or actions[idx] or "Idle"

		if name == "Idle" then
			Move.stop(agent)
		elseif name == "Chase" then
			local target = pickEnemyOrTarget(agent)
			Move.chase(agent, target)
		elseif name == "Hop" then
			Move.hop(agent)
		else
			-- Unknown action, be safe
			Move.stop(agent)
		end
	end
end

return M
