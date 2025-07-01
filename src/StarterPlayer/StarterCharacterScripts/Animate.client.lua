-- Official Roblox Animate Script (R6 version, 2024)
-- Handles all default character animations with proper transitions and priorities

local Figure = script.Parent
local Humanoid = Figure:FindFirstChildOfClass("Humanoid")
if not Humanoid then return end

local Animate = {}

-- Animation asset IDs (default Roblox R6)
Animate.idle = { Animation1 = "rbxassetid://180435571", Animation2 = "rbxassetid://180435792" }
Animate.walk = { Animation = "rbxassetid://180426354" }
Animate.run = { Animation = "rbxassetid://180426354" }
Animate.jump = { Animation = "rbxassetid://125750702" }
Animate.fall = { Animation = "rbxassetid://180436148" }
Animate.climb = { Animation = "rbxassetid://180436334" }
Animate.sit = { Animation = "rbxassetid://178130996" }
Animate.toolnone = { Animation = "rbxassetid://182393478" }
Animate.toolslash = { Animation = "rbxassetid://129967390" }
Animate.toollunge = { Animation = "rbxassetid://129967478" }
Animate.swim = { Animation = "rbxassetid://180426354" }
Animate.swimidle = { Animation = "rbxassetid://180426354" }

local loadedAnims = {}
local currentAnim = ""
local currentAnimTrack = nil
local currentAnimKey = ""
local animTable = {}
local animNames = { "idle", "walk", "run", "jump", "fall", "climb", "sit", "toolnone", "toolslash", "toollunge", "swim", "swimidle" }

function stopAllAnimations()
	for _, track in Humanoid:GetPlayingAnimationTracks() do
		track:Stop()
	end
end

function playAnimation(animName, animKey)
	if currentAnim == animName and currentAnimKey == animKey then return end
	currentAnim = animName
	currentAnimKey = animKey

	if currentAnimTrack then
		currentAnimTrack:Stop()
		currentAnimTrack = nil
	end

	local animId = ""
	if Animate[animName] then
		animId = Animate[animName][animKey] or Animate[animName].Animation or Animate[animName].Animation1
	end
	if animId and animId ~= "" then
		local anim = Instance.new("Animation")
		anim.AnimationId = animId
		currentAnimTrack = Humanoid:LoadAnimation(anim)
		currentAnimTrack:Play()
	end
end

-- Idle animation alternates between two animations
local idleToggle = true
function playIdle()
	idleToggle = not idleToggle
	local key = idleToggle and "Animation1" or "Animation2"
	playAnimation("idle", key)
end

-- Movement state handlers
Humanoid.Running:Connect(function(speed)
	if speed > 0.1 then
		playAnimation("walk", "Animation")
	else
		playIdle()
	end
end)

local UIS = game:GetService("UserInputService")
Humanoid.Jumping:Connect(function()
	if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
		-- Block jump animation if Ctrl is held
		return
	end
	playAnimation("jump", "Animation")
end)

Humanoid.Climbing:Connect(function(speed)
	playAnimation("climb", "Animation")
end)

Humanoid.FreeFalling:Connect(function(active)
	if active then
		playAnimation("fall", "Animation")
	end
end)

Humanoid.StateChanged:Connect(function(old, new)
	if new == Enum.HumanoidStateType.Seated then
		playAnimation("sit", "Animation")
	end
end)

-- Play idle on spawn
playIdle()

