local Plugin = {}
Plugin.NotifyBad = { 255,0,0 }
Plugin.NotifyGood = { 0,255,0 }
Plugin.NotifyEqual = { 0, 150, 255 }

Plugin.Conflicts = {
	DisableThem = {
		"jointeam"
	}
}

function Plugin:SetupDataTable()
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team1", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team2", 0)
	self:AddDTVar("float", "maxdiff", 0)
	self:AddDTVar("boolean", "antistack", true)
	self:AddDTVar("boolean", "inform", true)
end

function Plugin:GetCanJoinTeam(team, skill)
	skill = math.max(skill * -100, skill) -- For bots

	local team1 = self.dt.team1
	local team2 = self.dt.team2

	local team1n = team1 + skill
	local team2n = team2 + skill

	local reldiff1 = 2^math.abs(math.log(team1n / team2, 2))
	local reldiff2 = 2^math.abs(math.log(team1 / team2n, 2))

	return
		not self.antistack or
		math.max(reldiff1, reldiff2) < self.dt.maxdiff or
		(team == 1) == (reldiff1 < reldiff2),
		reldiff1, reldiff2, team1n, team2n
end

Shine:RegisterExtension("localhive", Plugin)
