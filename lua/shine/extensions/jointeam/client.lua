local Plugin = Plugin
local Shine = Shine

Log "\n\nLoading client.lua!\n\n"

function Plugin:Initialise()
	Log "Loaded jointeam on client!"
	self.text_current = Shine.ScreenText.Add("jointeam_current", {
		X = 0.6,
		Y = 0.5,
		Text = "",
		Alignment = 0,
	})

	self.text_marine = Shine.ScreenText.Add("jointeam_marine", {
		X = 0.6,
		Y = 0.55,
		Text = "",
		Alignment = 0
	})

	self.text_alien = Shine.ScreenText.Add("jointeam_alien", {
		X = 0.6,
		Y = 0.6,
		Text = "",
		Alignment = 0
	})

	self:NetworkUpdate()

	self.Enabled = true
	return true
end

function Plugin:NetworkUpdate()
	Log "Got a network update!"
	local player = Client.GetLocalPlayer()
	local team   = player:GetTeamNumber()

	if self.dt.inform == false then
		self.text_current:SetIsVisible(false)
		self.text_marine:SetIsVisible(false)
		self.text_alien:SetIsVisible(false)
	elseif team ~= 1 and team ~= 2 then
		self.text_current:SetIsVisible(true)
		self.text_marine:SetIsVisible(true)
		self.text_alien:SetIsVisible(true)
	elseif GetGameInfoEntity():GetState() ~= kGameState.Started then
		self.text_current:SetIsVisible(true)
		self.text_marine:SetIsVisible(false)
		self.text_alien:SetIsVisible(false)
	else
		self.text_current:SetIsVisible(false)
		self.text_marine:SetIsVisible(false)
		self.text_alien:SetIsVisible(false)
		return
	end

	local skill   = player:GetPlayerSkill()
	local maxprob = self.dt.maxprob
	local team1   = self.dt.team1
	local team2   = self.dt.team2

	local team1_n = team1 + skill
	local team2_n = team2 + skill

	local playercount = 0
	local teaminfos   = GetEntities "TeamInfo"
	for _, info in ipairs(teaminfos) do
		if info:GetTeamNumber() == 1 or info:GetTeamNumber() == 2 then
			playercount = playercount + info:GetPlayerCount()
		end
	end

	local p  = self:CalculateProbability(team1,   team2,   playercount)
	local p1 = self:CalculateProbability(team1_n, team2,   playercount)
	local p2 = self:CalculateProbability(team1,   team2_n, playercount)

	local p1abs = math.abs(p1 - 0.5)
	local p2abs = math.abs(p1 - 0.5)

	if self.dt.acceptable then
		maxprob = math.max(maxprob, math.abs(p - 0.5))
	end

	do
		local text = self.text_current

		text.Text =
			string.format("%s: %f",
				self:GetPhrase "TEXT_CURRENT",
				p
			)

		local color = math.abs(p - 0.5) < maxprob and self.NotifyGood or self.NotifyBad
		text.R = color[1]
		text.G = color[2]
		text.B = color[3]
	end

	do
		local text = self.text_marine

		text.Text =
			string.format("%s: %f",
				self:GetPhrase "TEXT_JOIN_M",
				p1
			)

		local color =
			p1abs < p2abs   and self.NotifyGood or
			p1abs < maxprob and self.NotifyEqual or
			self.NotifyBad

		text.R = color[1]
		text.G = color[2]
		text.B = color[3]
	end

	do
		local text = self.text_alien

		text.Text =
			string.format("%s: %f",
				self:GetPhrase "TEXT_JOIN_A",
				p2
			)

		local color =
			p2abs < p1abs and self.NotifyGood or
			p2abs < maxprob and self.NotifyEqual or
			self.NotifyBad

		text.R = color[1]
		text.G = color[2]
		text.B = color[3]
	end
end

function Plugin:Cleanup()
	Shine.ScreenText.Remove "jointeam_current"
	Shine.ScreenText.Remove "jointeam_marine"
	Shine.ScreenText.Remove "jointeam_alien"

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
