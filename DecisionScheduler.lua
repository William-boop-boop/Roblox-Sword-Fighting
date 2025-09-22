local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "DecisionScheduler is server only")

local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local PolicyRuntime    = require(pkg:WaitForChild("PolicyRuntime"))
local ParityMiddleware = require(pkg:WaitForChild("ParityMiddleware"))
local PolicyActor      = require(pkg:WaitForChild("PolicyActor"))
local ActionDispatcher = require(pkg:WaitForChild("ActionDispatcher"))

local M = {}
local _started = false

function M.start()
	if _started then return end
	local ok, err = pcall(PolicyRuntime.init)
	if not ok then
		warn("[DecisionScheduler] PolicyRuntime.init failed: " .. tostring(err))
		return
	end

	if type(ParityMiddleware.start) == "function" then
		ParityMiddleware.start()
	end

	RunService.Heartbeat:Connect(function(dt)
		if PolicyRuntime.isReady and PolicyRuntime.isReady() then
			ActionDispatcher.dispatchAll(function(agent)
				return PolicyActor.nextAction(agent)
			end, dt)
		end
	end)

	_started = true
end

return M
