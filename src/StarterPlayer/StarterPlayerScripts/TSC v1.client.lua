--You can put this in: StarterCharacterScripts, StarterPlayerScripts, StarterGui, ReplicatedFirst and StarterPack.

local run = game:GetService'RunService'
local uis = game:GetService'UserInputService'

local cam = workspace.CurrentCamera

local mult = 180/math.pi
local clamp = math.clamp

local current = Vector2.zero
local targetX, targetY = 0, 0

local speed = 4.5 -- Set the speed of the animation
local sensitivity = 0.7 -- Set the sensitivity of the rotation

run:BindToRenderStep("SmoothCam", Enum.RenderPriority.Camera.Value-1, function(dt)
	uis.MouseDeltaSensitivity = 0.01
	
	local delta = uis:GetMouseDelta()*sensitivity*50
	targetX += delta.X
	targetY = clamp(targetY+delta.Y,-90,90)
	current = current:Lerp(Vector2.new(-targetX,-targetY), dt*(speed*5))
	
	cam.CFrame = CFrame.fromOrientation(current.Y/mult,current.X/mult,0)
end)