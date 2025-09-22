local M = {}

-- Decision loop frequency (Hz)
M.HEARTBEAT_DECISION_HZ = 5

-- Tag placed on bot Models you want controlled
M.BOT_TAG = "AIBot"

-- Feature size used by FeatureEncoder (only relevant if you later swap to a real policy)
M.FEATURE_DIM = 4

return M
