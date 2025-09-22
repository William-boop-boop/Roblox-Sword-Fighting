local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "PolicyRuntime must run on the server")

local ServerStorage = game:GetService("ServerStorage")
local pkg = assert(ServerStorage:FindFirstChild("AIPolicy"), "Missing folder ServerStorage.AIPolicy")

local mod = pkg:FindFirstChild("DecisionScheduler")
assert(mod and mod:IsA("ModuleScript"), "Missing ModuleScript ServerStorage.AIPolicy.DecisionScheduler")

local Scheduler = require(mod)
if Scheduler.start then
	Scheduler.start()
end
