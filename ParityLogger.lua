local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "ParityLogger is server only")

local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local PolicyRuntime = require(pkg:WaitForChild("PolicyRuntime"))
local FeatureEncoder = require(pkg:WaitForChild("FeatureEncoder"))
local ActionMapper   = require(pkg:WaitForChild("ActionMapper"))

local M = {}

local function safe_call(mod, fname)
	local f = mod and mod[fname]
	if type(f) == "function" then
		local ok, res = pcall(f, mod)
		if ok then return res end
	end
	return nil
end

local function readPolicyInfo()
	local featDim = safe_call(FeatureEncoder, "outputSize") or tonumber(FeatureEncoder.outputSize) or 0
	local actCnt  = safe_call(ActionMapper, "count") or tonumber(ActionMapper.count) or 0

	local rows, cols = 0, 0
	if type(PolicyRuntime.getQ) == "function" then
		local _, r, c = PolicyRuntime.getQ()
		rows, cols = tonumber(r) or 0, tonumber(c) or 0
	end

	return {
		featDim = featDim,
		actCnt = actCnt,
		rows = rows,
		cols = cols,
		qSize = rows * cols
	}
end

function M.start()
	-- optional one-shot banner
	local info = readPolicyInfo()
	print(string.format("[Parity] features=%d actions=%d Q=%dx%d", info.featDim, info.actCnt, info.rows, info.cols))
end

function M.logFrame(frame)
	local info = readPolicyInfo()
	print(string.format("[Parity] frame=%d | features=%d actions=%d Q=%dx%d", frame or 0, info.featDim, info.actCnt, info.rows, info.cols))
end

return M