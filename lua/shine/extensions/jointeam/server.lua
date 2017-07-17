--The plugin table registered in shared.lua is passed in as the global "Plugin".
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "JoinTeam.json"
Plugin.DefaultConfig = {
    InformPlayer = true,
	ForcePlayer = true,
	MaxRelativeDifference = 1.2
}
Plugin.CheckConfig = true

function Plugin:Initialise()
	self.dt.maxdiff   = self.Config.MaxRelativeDifference
	self.dt.inform    = self.Config.InformPlayer
	self.dt.antistack = self.Config.ForcePlayer

	local gamerules = GetGamerules()

	local old = gamerules.JoinTeam
	gamerules.JoinTeam = function(...) return self:JoinTeam(old, ...) end

	self.Enabled = true
	return true
end

function Plugin:JoinTeam(old, gamerules, player, team, force, shineforce)
	if self.Enabled and self.Config.ForcePlayer and not (shineforce or force) and (team == 1 or team == 2) then
		local canjoin = self:GetCanJoinTeam(team, player:GetSkill())
		if canjoin then
			return old(gamerules, player, team, true, true)
			self:NotifyTranslated(Player, "OK_CHOICE")
		else
			self:NotifyTranslated(Player, "ERROR_1")
			return false, player
		end
	else
		return old(gamerules, player, team, force, shineforce)
	end
end

function Plugin:UpdateSkill()
	local t = {self, skill = 0}
	local closure =	Closure and Closure [[
		self self
		args player
		local skill = player:GetSkill()
		skill = math.max(skill * -100, skill) -- For bots: -1 -> 100
		self.skill = self.skill + skill
	]] (t) or function(player)
		local skill = player:GetSkill()
		skill = math.max(skill * -100, skill)
		t.skill = t.skill + skill
	end
	GetGamerules().team1:ForEachPlayer(closure)
	self.dt.team1 = t.skill
	t.skill = 0
	GetGamerules().team2:ForEachPlayer(closure)
	self.dt.team2 = t.skill
end

Plugin.PostJoinTeam = Plugin.UpdateSkill
Plugin.ClientDisconnect = Plugin.UpdateSkill
