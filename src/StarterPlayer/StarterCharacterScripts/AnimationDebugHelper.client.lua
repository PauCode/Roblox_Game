-- AnimationDebugHelper: Now uses AnimationStateManager for clean transitions

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local AnimationStateManager = require(ReplicatedStorage:WaitForChild("AnimationStateManager"))

local anims = {
	idle1 = "rbxassetid://88878584918093", -- UPDATED ID
	idle2 = "rbxassetid://111219973667367",
	walk = "rbxassetid://74177399285067",
	run = "rbxassetid://70377042525324",
	panic = "rbxassetid://107254584850709",
	climb = "rbxassetid://14874131805",
	climb_idle = "rbxassetid://14874286370",
	jump = "rbxassetid://987654321098765",
	hurt_idle = "rbxassetid://94719979895402",
	hurt_walk = "rbxassetid://132562775980592",
	hurt_run = "rbxassetid://131663207030417",
	crouch_idle = "rbxassetid://130073502619387",
	crouch_walk = "rbxassetid://122685295973913"
}

local character = script.Parent
local humanoid = character:FindFirstChildOfClass("Humanoid")
if not humanoid then
	warn("No Humanoid found in character!")
	return
end

local animManager = AnimationStateManager.new(humanoid, anims)

-- Example: Play idle1 on spawn
animManager:play("idle1")

-- Example: Simulate state changes for debug
task.wait(2)
animManager:play("crouch_idle")
task.wait(2)
animManager:play("hurt_idle")
task.wait(2)
animManager:play("idle1")

-- You can hook this up to your actual state logic (isCrouching, isHurt, etc.)

