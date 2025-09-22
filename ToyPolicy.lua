local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local Weights        = require(pkg:WaitForChild("PolicyWeights"))
local ActionMapper   = require(pkg:WaitForChild("ActionMapper"))
local FeatureEncoder = require(pkg:WaitForChild("FeatureEncoder"))
local AgentIndex     = require(pkg:WaitForChild("AgentIndex"))

local M = {}
local ctr = {} -- per-agent tie-break cycle

-- --- math helpers ---
local function clamp(x, lo, hi) if x < lo then return lo elseif x > hi then return hi else return x end end
local function relu(x) return x > 0 and x or 0 end
local function apply_activation(v, kind)
	kind = (kind or "relu"):lower()
	if kind == "relu" then
		for i=1,#v do v[i] = relu(v[i]) end
	elseif kind == "tanh" then
		for i=1,#v do
			local e1 = math.exp(clamp(v[i], -20, 20))
			local e2 = 1 / e1
			v[i] = (e1 - e2) / (e1 + e2)
		end
	elseif kind == "sigmoid" then
		for i=1,#v do v[i] = 1 / (1 + math.exp(-clamp(v[i], -20, 20))) end
	end
	return v
end

local function matvec(W, x, b)
	local outN = #W
	local out = table.create(outN, 0)
	for i=1, outN do
		local row, s = W[i], (b and (b[i] or 0) or 0)
		for j=1, #row do s += (row[j] or 0) * (x[j] or 0) end
		out[i] = s
	end
	return out
end

-- --- model/layers ---
local model = Weights or {}
local layers = model.policy_mlp or {}
local globalAct = (model.activation or "ReLU"):lower()
local feature_dim = tonumber(model.feature_dim) or 0

local function forward(feat)
	local x = feat
	for li=1, #layers do
		local L = layers[li]
		x = matvec(L.weight, x, L.bias)
		if li < #layers then apply_activation(x, globalAct) end
	end
	return x
end

-- --- features ---
local function buildFeatures(agentId)
	local agentModel
	for _, a in ipairs(AgentIndex.listAgents()) do
		if a.id == agentId then agentModel = a.model break end
	end

	local f
	if type(FeatureEncoder.encode) == "function" then
		local ok, res = pcall(function() return FeatureEncoder.encode(agentModel or agentId) end)
		if ok and type(res) == "table" then f = res end
	elseif type(FeatureEncoder.encodeById) == "function" then
		local ok, res = pcall(function() return FeatureEncoder.encodeById(agentId) end)
		if ok and type(res) == "table" then f = res end
	end
	f = f or table.create(feature_dim, 0)

	-- pad/trim
	local n = #f
	if feature_dim > 0 then
		if n < feature_dim then for i=n+1, feature_dim do f[i] = 0 end
		elseif n > feature_dim then for i=n, feature_dim+1, -1 do f[i] = nil end end
	end
	return f
end

-- reduce any-length vector to exactly K buckets by summing modulo
local function compressToK(v, k)
	if k <= 0 then return v end
	if #v == k then return v end
	local out = table.create(k, 0)
	for i=1,#v do
		local b = ((i-1) % k) + 1
		out[b] += v[i] or 0
	end
	return out
end

local function all_equal(v)
	for i=2,#v do if v[i] ~= v[1] then return false end end
	return true
end

function M.nextAction(agentId)
	agentId = agentId or "default"
	local actions = ActionMapper.actions()
	local k = #actions

	-- 1) run model (may be empty, returns features)
	local logits = forward(buildFeatures(agentId))

	-- 2) force logits to match action count
	logits = compressToK(logits, k)

	-- 3) tie-breaker: if all same (e.g., zeros), cycle actions per agent
	if #logits == 0 or all_equal(logits) then
		ctr[agentId] = (ctr[agentId] or 0) % math.max(1, k) + 1
		local i = ctr[agentId]
		return i, actions[i] or ("Action_"..i)
	end

	-- 4) greedy pick
	local bestIdx, bestVal = 1, -math.huge
	for i=1, #logits do
		local v = logits[i] or -math.huge
		if v > bestVal then bestVal, bestIdx = v, i end
	end
	return bestIdx, actions[bestIdx] or ("Action_"..bestIdx)
end

function M.qValues(agentId)
	local actions = ActionMapper.actions()
	return compressToK(forward(buildFeatures(agentId)), #actions)
end

return M
