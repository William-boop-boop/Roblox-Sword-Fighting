local CollectionService = game:GetService("CollectionService")

local M = {}
M.Range = 4
M.Damage = 5

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso")
end

function M.attack(agent, target)
	if not agent or not agent.root or not target then return end
	if not CollectionService:HasTag(target, "AIBot") then return end -- ignore players

	local tr = getRoot(target)
	local th = target:FindFirstChildOfClass("Humanoid")
	if tr and th then
		local d = (tr.Position - agent.root.Position).Magnitude
		if d <= M.Range then
			th:TakeDamage(M.Damage)
			print("[Sword] hit", target.Name)
		end
	end
end

return M