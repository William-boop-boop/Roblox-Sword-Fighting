local CollectionService = game:GetService("CollectionService")

local M = {}

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso")
end

local function validBot(model)
	if not model or not model.Parent then return false end
	local hum = model:FindFirstChildOfClass("Humanoid")
	local root = getRoot(model)
	return hum ~= nil and root ~= nil and CollectionService:HasTag(model, "AIBot")
end

function M.listAgents()
	local out, seen = {}, {}
	local function add(model)
		if not model or seen[model] then return end
		if validBot(model) then
			local hum = model:FindFirstChildOfClass("Humanoid")
			local root = getRoot(model)
			local id = model:GetAttribute("AgentId") or model.Name
			table.insert(out, {id = id, model = model, humanoid = hum, root = root})
			seen[model] = true
		end
	end

	-- Tagged bots are the source of truth
	for _, m in ipairs(CollectionService:GetTagged("AIBot")) do add(m) end

	-- Fallback helpers (keep your current names working)
	for _, name in ipairs({"BotA","BotB","Bot_A","Bot_B"}) do add(workspace:FindFirstChild(name)) end
	for _, m in ipairs(workspace:GetChildren()) do
		if typeof(m) == "Instance" and m:IsA("Model") and m.Name:match("^Bot") then add(m) end
	end

	return out
end

-- NEW: only return the nearest **other bot**
function M.pickEnemy(agent)
	local aPos = agent.root.Position
	local best, bestd
	for _,other in ipairs(M.listAgents()) do
		if other.model ~= agent.model then
			local d = (other.root.Position - aPos).Magnitude
			if not bestd or d < bestd then best, bestd = other.model, d end
		end
	end
	return best, bestd or math.huge
end

return M