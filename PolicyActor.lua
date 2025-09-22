local ServerStorage = game:GetService("ServerStorage")
local pkg = ServerStorage:WaitForChild("AIPolicy")

local PolicyLoader   = require(pkg:WaitForChild("PolicyLoader"))
local ActionMapper   = require(pkg:WaitForChild("ActionMapper"))
local FeatureEncoder = require(pkg:WaitForChild("FeatureEncoder"))

local M = {}
local _policy
local _fallbackCtr = {}

local function relu(v)
	for i=1,#v do v[i] = (v[i] or 0) > 0 and v[i] or 0 end
end

local function matvec(weight, bias, x)
	local out = table.create(#weight, 0)
	for i = 1, #weight do
		local row = weight[i]
		local s = (bias and bias[i]) or 0
		for j = 1, #x do s += (row[j] or 0) * (x[j] or 0) end
		out[i] = s
	end
	return out
end

local function argmax(t)
        local k, best = 1, -math.huge
        for i=1,#t do
                local v = t[i] or -math.huge
                if v > best then best, k = v, i end
        end
        return k
end

local function allEqual(t)
        if #t <= 1 then return true end
        local first = t[1]
        for i = 2, #t do
                if t[i] ~= first then return false end
        end
        return true
end

local function fallbackAction(agent)
        local actions = ActionMapper.actions() or {}
        if #actions == 0 then return 1, "Idle" end

        -- Prefer an explicit "Chase" action so bots move by default.
        local chaseIdx
        for i, name in ipairs(actions) do
                if name == "Chase" then
                        chaseIdx = i
                        break
                end
        end

        if chaseIdx then
                return chaseIdx, actions[chaseIdx]
        end

        -- Otherwise cycle through the available actions per-agent.
        local agentKey = agent and (agent.id or agent)
        local n = math.max(1, #actions)
        _fallbackCtr[agentKey] = ((_fallbackCtr[agentKey] or 0) % n) + 1
        local idx = _fallbackCtr[agentKey]
        return idx, actions[idx] or "Idle"
end

local function getFeatures(agent, want)
        -- Prefer FeatureEncoder.encode(agent, want) if present; else zeros.
        if type(FeatureEncoder.encode) == "function" then
                local ok, feat = pcall(FeatureEncoder.encode, agent, want)
                if ok and type(feat) == "table" and #feat == want then return feat end
	end
	local z = table.create(want, 0)
	return z
end

local function forward(feat)
	_policy = _policy or PolicyLoader.load()
	local x = table.create(#feat); for i=1,#feat do x[i] = tonumber(feat[i]) or 0 end
	for li, layer in ipairs(_policy.policy_mlp) do
		x = matvec(layer.weight, layer.bias, x)
		if li < #_policy.policy_mlp then relu(x) end
	end
	return x
end

-- Accepts the full agent table (id/model/humanoid/root)
function M.nextAction(agent)
        _policy = _policy or PolicyLoader.load()
        local feat = getFeatures(agent, _policy.feature_dim)
        local logits = forward(feat)
        if #logits == 0 or allEqual(logits) then
                return fallbackAction(agent)
        end
        local idx = argmax(logits)
        local name = (ActionMapper.actions() or {})[idx]
        return idx, name
end

return M
