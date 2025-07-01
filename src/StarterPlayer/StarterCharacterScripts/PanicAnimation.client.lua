local panicAnimId = "rbxassetid://107254584850709"
local PANIC_KEY = Enum.KeyCode.F

local ContextActionService = game:GetService("ContextActionService")
local character = script.Parent
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then return end

local panicAnim = Instance.new("Animation")
panicAnim.AnimationId = panicAnimId
panicAnim.Name = "Panic"

local panicTrack = humanoid:LoadAnimation(panicAnim)
panicTrack.Priority = Enum.AnimationPriority.Action

local function stopAllTracksExceptPanic()
	for _, track in humanoid:GetPlayingAnimationTracks() do
		if track ~= panicTrack then
			track:Stop()
		end
	end
end

local function onPanicAction(actionName, inputState, inputObj)
	if inputState == Enum.UserInputState.Begin then
		stopAllTracksExceptPanic()
		panicTrack:Play()
	elseif inputState == Enum.UserInputState.End then
		panicTrack:Stop()
	end
end

ContextActionService:BindAction("PlayPanicAnim", onPanicAction, false, PANIC_KEY)

-- Clean up on character removal
character.AncestryChanged:Connect(function()
	if not character:IsDescendantOf(game) then
		ContextActionService:UnbindAction("PlayPanicAnim")
	end
end)

