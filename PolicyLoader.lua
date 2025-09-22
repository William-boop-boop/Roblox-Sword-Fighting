local HttpService = game:GetService("HttpService")
local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local M = {}
local _cached

local function fromStringValue()
	local assets = pkg:FindFirstChild("Assets")
	local sv = assets and assets:FindFirstChild("PolicyJSON")
	if sv and sv:IsA("StringValue") and sv.Value ~= "" then
		local ok, data = pcall(HttpService.JSONDecode, HttpService, sv.Value)
		if ok and type(data) == "table" then return data end
	end
end

local function fromModule()
	local mod = pkg:FindFirstChild("PolicyWeights")
	if mod and mod:IsA("ModuleScript") then
		local ok, data = pcall(require, mod)
		if ok and type(data) == "table" then return data end
	end
end

local function validate(t)
	assert(type(t) == "table", "[PolicyLoader] policy is not a table")
	assert(type(t.feature_dim) == "number" and t.feature_dim > 0, "[PolicyLoader] feature_dim missing/bad")
	assert(type(t.num_actions) == "number" and t.num_actions > 0, "[PolicyLoader] num_actions missing/bad")
	assert(type(t.policy_mlp) == "table" and #t.policy_mlp >= 2, "[PolicyLoader] policy_mlp missing/bad")
	return t
end

function M.load()
	if _cached then return _cached end
	local t = fromStringValue() or fromModule()
	assert(t, "[PolicyLoader] No policy found. Add StringValue 'AIPolicy/Assets/PolicyJSON' (JSON) or ModuleScript 'AIPolicy/PolicyWeights' (returns table).")
	_cached = validate(t)
	return _cached
end

return M
