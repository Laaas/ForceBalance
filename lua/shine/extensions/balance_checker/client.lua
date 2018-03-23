local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self.last_update = -1

	self:NetworkUpdate()

	self.Enabled = true
	return true
end

function Plugin:Cleanup()
	Shine.ScreenText.Remove "balance_checker_current"
	Shine.ScreenText.Remove "balance_checker_marine"
	Shine.ScreenText.Remove "balance_checker_alien"

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
