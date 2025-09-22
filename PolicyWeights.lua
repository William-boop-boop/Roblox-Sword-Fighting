-- Minimal, valid weights (zeros) just to prove load/shape is correct.
-- Replace with real numbers later; structure is what matters.
local function zeros(r,c)
	local t = table.create(r)
	for i=1,r do t[i] = table.create(c, 0) end
	return t
end

local FEATURE_DIM  = 36
local NUM_ACTIONS  = 4
local HIDDEN       = 16

return {
	feature_dim = FEATURE_DIM,
	num_actions = NUM_ACTIONS,
	activation  = "ReLU",
	policy_mlp  = {
		{ weight = zeros(HIDDEN, FEATURE_DIM), bias = table.create(HIDDEN, 0) },
		{ weight = zeros(NUM_ACTIONS, HIDDEN), bias = table.create(NUM_ACTIONS, 0) },
	},
}
