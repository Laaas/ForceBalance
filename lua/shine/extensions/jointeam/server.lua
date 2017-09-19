--The plugin table registered in shared.lua is passed in as the global "Plugin".
local Plugin = Plugin
local Shine  = Shine

Plugin.HasConfig = true
Plugin.ConfigName = "JoinTeam.json"
Plugin.DefaultConfig = {
	InformPlayer = true,
	ForcePlayer = true,
	MaxWinProbability = 0.6,
	AnythingBetterIsAcceptable = false,
	UseMapBalance = true,
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	self.dt.maxprob    = math.abs(self.Config.MaxWinProbability - 0.5)
	self.dt.inform	   = self.Config.InformPlayer
	self.dt.antistack  = self.Config.ForcePlayer
	self.dt.acceptable = self.Config.AnythingBetterIsAcceptable

	self:BindCommand("sh_jointeam_info", "JoinTeamInfo", function(client)
		Shine:Notify(client, "PM", "JoinTeam", ("maxprob: %s\ninform: %s\nantistack: %s\nacceptable: %s\nmapbalance: %s"):format(self.dt.maxprob, self.dt.inform, self.dt.antistack, self.dt.acceptable, self.dt.mapbalance))
	end):Help "Show JoinTeam info"

	local old = JoinRandomTeam
	function JoinRandomTeam(player)
		if not self.Enabled then
			return old(player)
		end

		local teama, teamb
		if math.random(2) == 1 then
			teama, teamb = 1, 2
		else
			teama, teamb = 2, 1
		end

		local gamerules = GetGamerules()
		local success = gamerules:JoinTeam(player, teama)
		if not success then
			success = gamerules:JoinTeam(player, teamb)
		end
		return success
	end
	self.Enabled = true
	return true
end

function Plugin:MapPostLoad()
	if not self.Config.UseMapBalance then return end

	local has_wonitor, wonitor = Shine:IsExtensionEnabled "wonitor"
	if has_wonitor then
		local url = wonitor.Config.WonitorURL
		url = url:sub(1, -#"update.php"-1) .. "query.php?data=teamWins&numPlayers_gt=6&map_is=" .. Shared.GetMapName() .. "&version_ge=" .. (Shared.GetBuildNumber() - 5)
		Shared.SendHTTPRequest(url, "POST", function(response)
			response = json.decode(response)
			Log("%s: %s", url, response)
			local a = response[1].team1Wins
			local b = response[1].team2Wins
			local mapbalance = a / (a + b)
			self.dt.mapbalance = math.log(mapbalance / (1 - mapbalance))
		end)
	end
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
			p1 < maxprob and p2 < maxprob or
			math.abs(p1 - p2) < 0.001     or
			(p1 < p2) == (team == 1)      or
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
