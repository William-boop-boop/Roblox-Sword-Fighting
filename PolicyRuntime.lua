local RunService = game:GetService("RunService")
assert(RunService:IsServer(), "PolicyRuntime is server only")

local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local FeatureEncoder = require(pkg:WaitForChild("FeatureEncoder"))
local ActionMapper   = require(pkg:WaitForChild("ActionMapper"))

local M = {}

local function numberOrDie(name, x)
	local n = tonumber(x)
	assert(n and n > 0, ("Expected positive number for %s, got %s"):format(name, tostring(x)))
	return n
end

local function fill(n, m, val)
	n = numberOrDie("rows n", n)
	m = numberOrDie("cols m", m)
	local t = table.create(n * m, val or 0)
	return t, n, m
end

function M.init()
	local featDim = type(FeatureEncoder.outputSize) == "function" and FeatureEncoder.outputSize() or FeatureEncoder.outputSize
	local actCnt  = type(ActionMapper.count) == "function" and ActionMapper.count() or ActionMapper.count

	M.Q, M.rows, M.cols = fill(featDim, actCnt, 0)
	return true
end

function M.getQ()
	assert(M.Q, "PolicyRuntime.init() not called")
	return M.Q, M.rows, M.cols
end

function M.isReady()
	return M.Q ~= nil and M.rows ~= nil and M.cols ~= nil
end

return M