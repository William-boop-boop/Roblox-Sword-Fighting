----------------------------------------------------------------
-- ServerStorage/AIPolicy/Utils.lua
----------------------------------------------------------------
local HttpService = game:GetService("HttpService")

local Utils = {}

Utils.EPS = 1e-8

function Utils.clamp(x, a, b)
	if x < a then return a end
	if x > b then return b end
	return x
end

function Utils.lerp(a, b, t)
	return a + (b - a) * t
end

local function rng01(rng)
	if rng and typeof(rng) == "Random" then
		return rng:NextNumber()
	else
		return math.random()
	end
end

-- Numerically stable softmax with temperature. Returns probs vector that sums to 1.
function Utils.softmax(logits, temperature)
	temperature = temperature or 1.0
	if temperature <= 0 then temperature = Utils.EPS end
	local maxv = -math.huge
	for i = 1, #logits do
		local v = logits[i] / temperature
		if v > maxv then maxv = v end
	end
	local sum = 0
	local exps = table.create(#logits, 0)
	for i = 1, #logits do
		local e = math.exp((logits[i] / temperature) - maxv)
		exps[i] = e
		sum += e
	end
	if sum < Utils.EPS then
		-- fallback to uniform if logits are all -inf or NaN
		local u = 1 / math.max(1, #logits)
		for i = 1, #logits do exps[i] = u end
		return exps
	end
	for i = 1, #logits do
		exps[i] = exps[i] / sum
	end
	return exps
end

-- Sample an index (0-based to match trainer) from probs. Optional RNG for determinism.
function Utils.sampleCategorical(probs, rng)
	local r = rng01(rng)
	local acc = 0
	for i = 1, #probs do
		acc += probs[i]
		if r <= acc then
			return i - 1
		end
	end
	return #probs - 1
end

function Utils.argmax(v)
	local bestI, bestV = 1, v[1]
	for i = 2, #v do
		if v[i] > bestV then bestV, bestI = v[i], i end
	end
	return bestI - 1, bestV -- 0-based index
end

-- Normalize vector x using mean and std arrays. Safeguards tiny std values.
function Utils.normalizeVec(x, mean, std)
	local y = table.create(#x)
	for i = 1, #x do
		local m = (mean and mean[i]) or 0.0
		local s = (std and std[i]) or 1.0
		if not s or s < 1e-6 then s = 1.0 end
		y[i] = (x[i] - m) / s
	end
	return y
end

-- JSON helpers
function Utils.jsonDecode(s)
	return HttpService:JSONDecode(s)
end
function Utils.jsonEncode(t)
	return HttpService:JSONEncode(t)
end

-- Time helpers
function Utils.nowMs()
	return os.clock() * 1000.0
end
function Utils.now()
	return os.clock()
end

return Utils