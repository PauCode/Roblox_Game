-- IdleAnimScript
-- This script makes an NPC idle by playing an idle animation

local npc = script.Parent
local idleAnimationId = "rbxassetid://(Your-Animation-Id)" -- Replace with your idle animation asset ID

-- Ensure the NPC has a Humanoid and an Animator
local humanoid = npc:FindFirstChildOfClass("Humanoid")
if not humanoid then
    warn("No Humanoid found in NPC")
    return
end

local animator = humanoid:FindFirstChildOfClass("Animator")
if not animator then
    warn("No Animator found in Humanoid")
    return
end

-- Load and play the idle animation
local idleAnimation = Instance.new("Animation")
idleAnimation.AnimationId = idleAnimationId

local idleTrack = animator:LoadAnimation(idleAnimation)
idleTrack.Looped = true
idleTrack:Play()

-- Ensure the animation keeps playing even if the NPC respawns
humanoid.Died:Connect(function()
    idleTrack:Stop()
end)

npc.AncestryChanged:Connect(function(_, parent)
    if not parent then
        idleTrack:Stop()
    end
end)