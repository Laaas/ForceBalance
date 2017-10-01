local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self.last_update = -1

	self:NetworkUpdate()

	self.Enabled = true
	return true
end

function Plugin:Cleanup()
	Shine.ScreenText.Remove "forcebalance_current"
	Shine.ScreenText.Remove "forcebalance_marine"
	Shine.ScreenText.Remove "forcebalance_alien"

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
