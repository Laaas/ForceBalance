local Plugin = {}
Plugin.NotifyBad   = {255, 0,   0}
Plugin.NotifyGood  = {0,   255, 0}
Plugin.NotifyEqual = {0,   150, 255}

Plugin.Conflicts = {
	DisableThem = {
		"jointeam"
	}
}

function Plugin:SetupDataTable()
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team1", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "team2", 0)
    self:AddDTVar("integer (0 to " .. 2^16-1 .. ")", "playercount", 0)
	self:AddDTVar("float",   "maxprob", 0)
	self:AddDTVar("boolean", "antistack", true)
	self:AddDTVar("boolean", "inform", true)
	self:AddDTVar("boolean", "acceptable", true)
	self:AddDTVar("float",   "mapbalance", 0)
	self:AddDTVar("float",   "unimportance", 1)
end

function Plugin:CalculateProbability(team1, team2, playercount)
	return 1 / (1 + math.exp(
		(team2 - team1) / (playercount * self.dt.unimportance) - self.dt.mapbalance
	))
end

function Plugin.eq(a, b)
	return math.abs(a - b) < 0.001
end

local eq = Plugin.eq

local function NetworkUpdate(self, first)
	local player = Client.GetLocalPlayer()
	local team   = player:GetTeamNumber()

	Shine.ScreenText.Remove "forcebalance_current"
	Shine.ScreenText.Remove "forcebalance_marine"
	Shine.ScreenText.Remove "forcebalance_alien"

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

	local playercount = self.dt.playercount

	local p  = self:CalculateProbability(team1,         team2,         playercount)

	local color = (math.abs(p - 0.5) < maxprob or p ~= p) and self.NotifyGood or self.NotifyBad
	Shine.ScreenText.Add("forcebalance_current", {
		X = 0.6,
		Y = 0.5,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_CURRENT", p),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
		FadeIn = 0,
	})

	if team == 1 or team == 2 then
		if first == false then Log("team1: %s, team2: %s, playercount: %s, p: %s", team1, team2, playercount, p) end
		return
	end

	local p1 = self:CalculateProbability(team1 + skill, team2,         playercount + 1)
	local p2 = self:CalculateProbability(team1,         team2 + skill, playercount + 1)
	local p1abs = math.abs(p1 - 0.5)
	local p2abs = math.abs(p2 - 0.5)

	if first == false then Log("team1: %s, team2: %s, playercount: %s, p: %s, p1abs: %s, p2abs: %s", team1, team2, playercount, p, p1abs, p2abs) end

	if self.dt.acceptable then
		maxprob = math.max(maxprob, math.abs(p - 0.5))
	end


	local color =
		p1abs < p2abs    and self.NotifyGood  or
		eq(p1abs, p2abs) and self.NotifyGood  or
		p1abs < maxprob  and self.NotifyEqual or
		self.NotifyBad
	Shine.ScreenText.Add("forcebalance_marine", {
		X = 0.6,
		Y = 0.55,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_JOIN_M", p1),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
		FadeIn = 0,
	})

	local color =
		p2abs < p1abs    and self.NotifyGood  or
		eq(p1abs, p2abs) and self.NotifyGood  or
		p2abs < maxprob  and self.NotifyEqual or
		self.NotifyBad
	Shine.ScreenText.Add("forcebalance_alien", {
		X = 0.6,
		Y = 0.6,
		Text = string.format("%s: %f", self:GetPhrase "TEXT_JOIN_A", p2),
		Alignment = 0,
		R = color[1],
		G = color[2],
		B = color[3],
		FadeIn = 0,
	})
end

if Client then
	-- We actually do it twice
	-- Once to immediately update the text
	-- Once to update in case of delayed netvars, which could e.g. cause the text to show while playing
	--
	-- We use pcall ourselves because the shine error handler can't handle this function for some reason.
	function Plugin:NetworkUpdate()
		if self.last_update == Shared.GetTime() then return end -- Don't update multiple times per tick, since the netvars won't change anyway.
		self.last_update = Shared.GetTime()

		local f = function() -- Team netvar needs to be completely updated too.
			local success, message = pcall(NetworkUpdate, self, false)
			if success == false then
				Shared.Message(debug.traceback(message))
			end
		end

		self:SimpleTimer(0.05, f)
		self:SimpleTimer(0.5, f)
	end
end


Shine:RegisterExtension("forcebalance", Plugin)
