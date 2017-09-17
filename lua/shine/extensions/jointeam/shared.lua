local Plugin = {}
Plugin.NotifyBad = { 255,0,0 }
Plugin.NotifyGood = { 0,255,0 }
Plugin.NotifyEqual = { 0, 150, 255 }

function Plugin:SetupDataTable()
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team1", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team2", 0)
	self:AddDTVar("float",   "maxprob", 0)
	self:AddDTVar("boolean", "antistack", true)
	self:AddDTVar("boolean", "inform", true)
	self:AddDTVar("boolean", "acceptable", true)
end

function Plugin:CalculateProbability(team1, team2, playercount)
	return 1 / (1 + math.exp(
		(team2 - team1) / (playercount * 100)
	))
end

Shine:RegisterExtension("jointeam", Plugin)
