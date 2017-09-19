local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self.Enabled = true
	return true
end

function Plugin:Cleanup()
	Shine.ScreenText.Remove "jointeam_current"
	Shine.ScreenText.Remove "jointeam_marine"
	Shine.ScreenText.Remove "jointeam_alien"

	self.BaseClass.Cleanup(self)

	self.Enabled = false
end
