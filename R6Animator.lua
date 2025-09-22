-- Server-side animator for R6 bots. Looks in ServerStorage/AIPolicy/Assets/R6Animations
-- Accepts Animation objects named with ANY of these (case-insensitive):
--   idle/Idle, walk/Walk/run/Run, jump/Jump, fall/Fall
local ServerStorage = game:GetService("ServerStorage")

local M = {}

local function animFolder()
	local pkg = ServerStorage:FindFirstChild("AIPolicy")
	local assets = pkg and pkg:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("R6Animations")
end

local function findAnim(af, names)
	if not af then return nil end
	for _,n in ipairs(names) do
		local a = af:FindFirstChild(n) or af:FindFirstChild(n:lower()) or af:FindFirstChild(n:upper())
		if a then return a end
	end
end

local function getRoot(model)
	return model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart or model:FindFirstChild("Torso")
end

function M.attach(model)
	if not model or not model.Parent then return end
	local hum = model:FindFirstChildOfClass("Humanoid"); if not hum then return end
	if hum.RigType ~= Enum.HumanoidRigType.R6 then return end -- only R6

	local animator = hum:FindFirstChild("Animator") or Instance.new("Animator", hum)

	local af = animFolder()
	local clips = {
		idle = findAnim(af, {"idle","Idle"}),
		walk = findAnim(af, {"walk","Walk","run","Run"}),
		jump = findAnim(af, {"jump","Jump"}),
		fall = findAnim(af, {"fall","Fall"}),
	}
	local tracks = {}
	for k,anim in pairs(clips) do
		if anim and anim:IsA("Animation") and anim.AnimationId ~= "" then
			tracks[k] = animator:LoadAnimation(anim)
			tracks[k].Priority = Enum.AnimationPriority.Movement
		end
	end

	-- simple state wiring
	hum.Running:Connect(function(speed)
		if tracks.walk and speed > 0.5 then
			if tracks.idle and tracks.idle.IsPlaying then tracks.idle:Stop(0.15) end
			if not tracks.walk.IsPlaying then tracks.walk:Play(0.15) end
			tracks.walk:AdjustSpeed(math.clamp(speed/14, 0.6, 1.6))
		else
			if tracks.walk and tracks.walk.IsPlaying then tracks.walk:Stop(0.2) end
			if tracks.idle and not tracks.idle.IsPlaying then tracks.idle:Play(0.2) end
		end
	end)

	hum.Jumping:Connect(function(active)
		if active and tracks.jump then tracks.jump:Play(0.05) end
	end)
	hum.FreeFalling:Connect(function(active)
		if active and tracks.fall then tracks.fall:Play(0.05) end
	end)

	-- kick off idle at start if present
	if tracks.idle and not tracks.idle.IsPlaying then tracks.idle:Play(0.2) end
end

return M