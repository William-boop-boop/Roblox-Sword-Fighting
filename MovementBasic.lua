local M = {}

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso")
end

function M.stop(agent)
	if not agent or not agent.humanoid or not agent.root then return end
	agent.humanoid:Move(Vector3.new())
	agent.humanoid:MoveTo(agent.root.Position)
end

function M.hop(agent)
	if agent and agent.humanoid then
		agent.humanoid.Jump = true
	end
end

function M.chase(agent, target)
	if not agent or not agent.humanoid or not agent.root or not target then return end
	local targetRoot = getRoot(target)
	if not targetRoot then return end
	local dist = (targetRoot.Position - agent.root.Position).Magnitude
	if dist < 3 then
		return M.stop(agent)
	end
	agent.humanoid:MoveTo(targetRoot.Position)
end

return M