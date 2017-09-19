local Plugin = {}
Plugin.NotifyBad   = {255, 0,   0}
Plugin.NotifyGood  = {0,   255, 0}
Plugin.NotifyEqual = {0,   150, 255}

function Plugin:SetupDataTable()
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team1", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team2", 0)
	self:AddDTVar("float",   "maxprob", 0)
	self:AddDTVar("boolean", "antistack", true)
	self:AddDTVar("boolean", "inform", true)
	self:AddDTVar("boolean", "acceptable", true)
	self:AddDTVar("float",   "mapbalance", 0)
end

function Plugin:CalculateProbability(team1, team2, playercount)
	return 1 / (1 + math.exp(
		(team2 - team1) / (playercount * 500) - self.dt.mapbalance
	))
end

local function NetworkUpdate(self)
	local player = Client.GetLocalPlayer()
	local team   = player:GetTeamNumber()

	Shine.ScreenText.Remove "jointeam_current"
	Shine.ScreenText.Remove "jointeam_marine"
	Shine.ScreenText.Remove "jointeam_alien"

	if
		self.dt.inform == false or
		(team == 1 or team == 2) and GetGameInfoEntity():GetState() == kGameState.Started
	then
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

	local color = (math.abs(p - 0.5) < maxprob or p ~= p) and self.NotifyGood or self.NotifyBad
	Shine.ScreenText.Add("jointeam_current", {
		X = 0.6,
		Y = 0.5,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_CURRENT", p),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
	})

	if team == 1 or team == 2 then return end

	local color =
		p1abs < p2abs   and self.NotifyGood or
		p1abs < maxprob and self.NotifyEqual or
		self.NotifyBad
	Shine.ScreenText.Add("jointeam_marine", {
		X = 0.6,
		Y = 0.55,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_JOIN_M", p1),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
	})

	local color =
		p2abs < p1abs and self.NotifyGood or
		p2abs < maxprob and self.NotifyEqual or
		self.NotifyBad
	Shine.ScreenText.Add("jointeam_alien", {
		X = 0.6,
		Y = 0.6,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_JOIN_A", p2),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
	})
end

local function handler(err)
	Shared.Message(debug.traceback(err))
end

function Plugin:NetworkUpdate()
	if Client then
		xpcall(NetworkUpdate, handler, self)
	end
end


Shine:RegisterExtension("jointeam", Plugin)
