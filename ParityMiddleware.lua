local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "ParityMiddleware is server only")

local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local ParityLogger = require(pkg:WaitForChild("ParityLogger"))

local M = {}

function M.start()
	if type(ParityLogger.start) == "function" then
		ParityLogger.start()
	end

	local acc, frame = 0, 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc >= 1 then
			acc = 0
			frame += 1
			if type(ParityLogger.logFrame) == "function" then
				ParityLogger.logFrame(frame)
			end
		end
	end)
end

return M