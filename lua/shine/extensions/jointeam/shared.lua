local Plugin = {}
Plugin.NotifyBad = { 255,0,0 }
Plugin.NotifyGood = { 0,255,0 }
Plugin.NotifyEqual = { 0, 150, 255 }

function Plugin:SetupDataTable()
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team1", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team2", 0)
	self:AddDTVar("float", "maxdiff", 0)
	self:AddDTVar("boolean", "antistack", true)
	self:AddDTVar("boolean", "inform", true)
end

function Plugin:GetCanJoinTeam(team, skill)
	return true
end

Shine:RegisterExtension("jointeam", Plugin)
