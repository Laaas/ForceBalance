local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self.text_current = Shine.ScreenText.Add("jointeam_current", {
		X = 0.6,
		Y = 0.5,
		Text = "",
		Alignment = 0,
	})
	self.text_current:SetIsVisible(false)

	self.text_marine = Shine.ScreenText.Add("jointeam_marine", {
		X = 0.6,
		Y = 0.55,
		Text = "",
		Alignment = 0
	})
	self.text_marine:SetIsVisible(false)

	self.text_alien = Shine.ScreenText.Add("jointeam_alien", {
		X = 0.6,
		Y = 0.6,
		Text = "",
		Alignment = 0
	})
	self.text_alien:SetIsVisible(false)

	self:NetworkUpdate()

	self.Enabled = true
	return true
end

function Plugin:NetworkUpdate()
	local player = Client.GetLocalPlayer()
	local team   = player:GetTeamNumber()

	if self.dt.inform == false or team ~= 1 and team ~= 2 then
		self.text_current:SetIsVisible(false)
		self.text_marine:SetIsVisible(true)
		self.text_alien:SetIsVisible(true)
		return
	end

	local localskill = player:GetPlayerSkill()
	local maxdiff = self.dt.maxdiff
	local team1   = self.dt.team1
	local team2   = self.dt.team2
	local reldiff = 2^math.abs(math.log(team1 / team2, 2))

	do
		local text = self.text_current

		text:SetIsVisible(true)

		text.Text =
			string.format("%s M: %d, A: %d, Abs Rel Diff: %f, Max: %f",
				self:GetPhrase "TEXT_CURRENT",
				team1,
				team2,
				reldiff,
				maxdiff
			)

		local color = reldiff < maxdiff and self.NotifyGood or self.NotifyBad
		text.R = color[1]
		text.G = color[2]
		text.B = color[3]
	end

	local _, reldiff1, reldiff2, team1n, team2n = self:GetCanJoinTeam(1, localskill)
	do
		local text = self.text_marine

		text:SetIsVisible(true)

		text.Text =
			string.format("%s M: %d, A: %d, Rel Diff: %f",
				self:GetPhrase "TEXT_JOIN_M",
				team1n,
				team2,
				team1n / team2
			)

		local color =
			reldiff1 < reldiff2 and self.NotifyGood or
			reldiff1 < maxdiff  and self.NotifyEqual or
			self.NotifyBad

		text.R = color[1]
		text.G = color[2]
		text.B = color[3]
	end

	do
		local text = self.text_alien

		text:SetIsVisible(true)

		text.Text =
			string.format("%s M: %d, A: %d, Rel Diff: %f",
				self:GetPhrase "TEXT_JOIN_A",
				team1,
				team2n,
				team2n / team1
			)

		local color =
			reldiff2 < reldiff1 and self.NotifyGood or
			reldiff2 < maxdiff  and self.NotifyEqual or
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
