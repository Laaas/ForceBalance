--The plugin table registered in shared.lua is passed in as the global "Plugin".
local Plugin = Plugin
local Shine  = Shine

Log "Loading server.lua!"

Plugin.HasConfig = true
Plugin.ConfigName = "JoinTeam.json"
Plugin.DefaultConfig = {
	InformPlayer = true,
	ForcePlayer = true,
	MaxWinProbability = 0.6,
	AnythingBetterIsAcceptable = false
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	Log "Loaded jointeam on server!"
	self.dt.maxprob    = math.abs(self.Config.MaxWinProbability - 0.5)
	self.dt.inform	   = self.Config.InformPlayer
	self.dt.antistack  = self.Config.ForcePlayer
	self.dt.acceptable = self.Config.AnythingBetterIsAcceptable

	self.Enabled = true
	return true
end

function Plugin:JoinTeam(gamerules, player, team, force, shineforce)
	if self.dt.antistack and not shineforce and (team == 1 or team == 2) then
		skill = player:GetPlayerSkill()
		skill = math.max(skill * -100, skill) -- For bots

		local team1 = self.dt.team1
		local team2 = self.dt.team2

		local team1_n = team1 + skill
		local team2_n = team2 + skill

		local playercount = 1
		local teaminfos = GetEntities "TeamInfo"
		for _, info in ipairs(teaminfos) do
			if info:GetTeamNumber() == 1 or info:GetTeamNumber() == 2 then
				playercount = playercount + info:GetPlayerCount()
			end
		end

		local p1 = math.abs(self:CalculateProbability(team1_n, team2,	playercount) - 0.5)
		local p2 = math.abs(self:CalculateProbability(team1,   team2_n, playercount) - 0.5)

		local maxprob = self.dt.maxprob
		if self.dt.acceptable then
			maxprob = math.max(maxprob, math.abs(
				self:CalculateProbability(team1, team2, playercount - 1)
			- 0.5))
		end

		local enabled, enforceteamsizes = Shine:IsExtensionEnabled "enforceteamsizes"
		local other_team = team == 1 and 2 or 1

		if
			p1 < maxprob and
			p2 < maxprob or
			(p1 < p2) == (team == 1) or
			enabled and (
				enforceteamsizes:GetNumPlayers(gamerules:GetTeam(other_team)) >= enforceteamsizes.Config.Teams[other_team].MaxPlayers
			)
		then
			self.NotifyPrefixColour = self.NotifyGood
			self:NotifyTranslated(Player, "OK_CHOICE")
			return
		else
			self.NotifyPrefixColour = self.NotifyBad
			self:NotifyTranslated(Player, "ERROR_1")
			return false
		end
	end
end

function Plugin:UpdateSkill()
	local t = {self, skill = 0}
	local closure = function(player)
		local skill = player:GetPlayerSkill()
		skill = math.max(skill * -100, skill)
		t.skill = t.skill + skill
	end
	GetGamerules().team1:ForEachPlayer(closure)
	self.dt.team1 = t.skill
	t.skill = 0
	GetGamerules().team2:ForEachPlayer(closure)
	self.dt.team2 = t.skill
end

function Plugin:PostJoinTeam()
	return self:UpdateSkill()
end

function Plugin:ClientDisconnect()
	return self:UpdateSkill()
end
