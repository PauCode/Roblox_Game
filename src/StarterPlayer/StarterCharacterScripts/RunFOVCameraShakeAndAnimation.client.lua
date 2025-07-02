																																															--[[ 
  Script: Advanced Run, Panic, Crouch, Stamina, FOV, Camera Shake, Animation Handler, Horror HUD, Sound & Blood Overlay
  Place this script in StarterCharacterScripts.
  - HUD visual agresivo y estresante, con efectos de alerta, parpadeo, sonidos y overlays sangrientos.
--]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera

-- Animation asset IDs
local anims = {
	idle1 = "rbxassetid://111219973667367",
	idle2 = "rbxassetid://96792590819142",
	walk = "rbxassetid://74177399285067",
	run = "rbxassetid://131590005888247",
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

-- Sound asset names (put Sound objects in ReplicatedStorage with these names)
local SOUND_PANIC = "PanicSting"
local SOUND_FATIGUE = "FatigueCrack"
local SOUND_BREATH = "Breath"
local SOUND_HEART = "Heartbeat"

-- Overlay asset (put Image in ReplicatedStorage with this name)
local BLOOD_OVERLAY = "BloodOverlay"

-- Movement and stamina settings
local WALK_SPEED = 12
local RUN_SPEED = 32
local PANIC_SPEED = 45
local CROUCH_SPEED = 5
local SPEED_LERP_RATE = 8
local DOUBLE_TAP_TIME = 0.3
-- runStamina is now managed by StaminaModule

-- (VaultDeductStamina undo: removed global vault stamina deduction logic)
local runStamina = 100
local panicStamina = 100
local isRunning = false
local isPanicking = false
local isCrouching = false
local lastShift = 0

-- Fatigue and cooldown
local isFatigued = false
local fatigueStartTime = 0
local fatigueDuration = 10
local panicCooldownActive = false
local panicCooldownStart = 0
local panicCooldownTime = 30
local panicSaturation = 0
local runLocked = false

-- Animation state

local animator = humanoid:WaitForChild("Animator")
local currentAnim = nil
local currentAnimId = nil
local lastState = nil
local lastAnimType = nil

-- Handle character respawn to re-acquire humanoid and animator
player.CharacterAdded:Connect(function(newChar)
	character = newChar
	humanoid = character:WaitForChild("Humanoid")
	animator = humanoid:WaitForChild("Animator")
	currentAnim = nil
	currentAnimId = nil
	lastState = nil
	lastAnimType = nil
end)

-- Idle switching logic
local idleToggle = true
local idleSwitchTimer = 0
local idleSwitchInterval = 4

-- Camera and UI
local shakeMagnitude = 0.15
local shakeSpeed = 25
local shakeTime = 0
local targetFOV = 70
local bobbingTime = 0
local bobbingSpeedWalk = 6
local bobbingSpeedRun = 10
local bobbingAmount = 0.1
local crouchCamTargetOffset = Vector3.new(0, -1.46 + 0.08, 0)
local currentCrouchCamOffset = Vector3.new(0, 0, 0)

-- FOV values
local FOV_WALK = 70
local FOV_RUN = 95
local FOV_PANIC = 111
local FOV_CROUCH = 65
local lastTargetFOV = FOV_WALK

-- HUD CLEANUP
local function removeOldStaminaHUD()
	local gui = player:FindFirstChild("PlayerGui")
	if gui then
		local old = gui:FindFirstChild("StaminaDisplay")
		if old then
			old:Destroy()
		end
	end
end
removeOldStaminaHUD()

-- HORROR HUD
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StaminaDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local bgFrame = Instance.new("Frame")
bgFrame.AnchorPoint = Vector2.new(1, 1)
bgFrame.Position = UDim2.new(1, -30, 1, -30)
bgFrame.Size = UDim2.new(0, 180, 0, 90)
bgFrame.BackgroundTransparency = 0.1
bgFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
bgFrame.BorderSizePixel = 0
bgFrame.Parent = screenGui

local horrorOutline = Instance.new("UIStroke")
horrorOutline.Color = Color3.fromRGB(255, 0, 0)
horrorOutline.Thickness = 4
horrorOutline.Transparency = 0.2
horrorOutline.Parent = bgFrame

local runBar = Instance.new("Frame")
runBar.Position = UDim2.new(0, 15, 0, 20)
runBar.Size = UDim2.new(0, 120, 0, 18)
runBar.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
runBar.BorderSizePixel = 0
runBar.BackgroundTransparency = 0.05
runBar.Parent = bgFrame

local runBarOutline = Instance.new("UIStroke")
runBarOutline.Color = Color3.fromRGB(0, 60, 120)
runBarOutline.Thickness = 2
runBarOutline.Parent = runBar

local runLabel = Instance.new("TextLabel")
runLabel.Position = UDim2.new(0, 140, 0, 20)
runLabel.Size = UDim2.new(0, 35, 0, 18)
runLabel.BackgroundTransparency = 1
runLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
runLabel.Font = Enum.Font.GothamBlack
runLabel.TextSize = 18
runLabel.TextStrokeTransparency = 0.2
runLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
runLabel.TextXAlignment = Enum.TextXAlignment.Left
runLabel.TextYAlignment = Enum.TextYAlignment.Center
runLabel.Text = "RUN"
runLabel.Parent = bgFrame

local panicBar = Instance.new("Frame")
panicBar.Position = UDim2.new(0, 15, 0, 50)
panicBar.Size = UDim2.new(0, 120, 0, 18)
panicBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
panicBar.BorderSizePixel = 0
panicBar.BackgroundTransparency = 0.05
panicBar.Parent = bgFrame

local panicBarOutline = Instance.new("UIStroke")
panicBarOutline.Color = Color3.fromRGB(120, 0, 0)
panicBarOutline.Thickness = 2
panicBarOutline.Parent = panicBar

local panicLabel = Instance.new("TextLabel")
panicLabel.Position = UDim2.new(0, 140, 0, 50)
panicLabel.Size = UDim2.new(0, 35, 0, 18)
panicLabel.BackgroundTransparency = 1
panicLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
panicLabel.Font = Enum.Font.GothamBlack
panicLabel.TextSize = 18
panicLabel.TextStrokeTransparency = 0.2
panicLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
panicLabel.TextXAlignment = Enum.TextXAlignment.Left
panicLabel.TextYAlignment = Enum.TextYAlignment.Center
panicLabel.Text = "PANIC"
panicLabel.Parent = bgFrame

local alertLabel = Instance.new("TextLabel")
alertLabel.AnchorPoint = Vector2.new(0.5, 0.5)
alertLabel.Position = UDim2.new(0.5, 0, 0, -18)
alertLabel.Size = UDim2.new(1, 0, 0, 28)
alertLabel.BackgroundTransparency = 1
alertLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
alertLabel.Font = Enum.Font.GothamBlack
alertLabel.TextSize = 24
alertLabel.TextStrokeTransparency = 0.1
alertLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
alertLabel.Text = ""
alertLabel.Parent = bgFrame

-- Blood overlay
local bloodOverlay = nil
local bloodAsset = ReplicatedStorage:FindFirstChild(BLOOD_OVERLAY)
if bloodAsset then
	bloodOverlay = bloodAsset:Clone()
	bloodOverlay.Size = UDim2.new(1,0,1,0)
	bloodOverlay.Position = UDim2.new(0,0,0,0)
	bloodOverlay.BackgroundTransparency = 1
	bloodOverlay.ImageTransparency = 1
	bloodOverlay.Parent = screenGui
end

-- Sound helpers
local function playSound(name, volume, pitch)
	local sound = ReplicatedStorage:FindFirstChild(name)
	if sound then
		local s = sound:Clone()
		s.Parent = workspace
		s.Volume = volume or 1
		s.Pitch = pitch or 1
		s:Play()
		game.Debris:AddItem(s, s.TimeLength + 1)
	end
end

-- Efectos visuales
local saturationEffect = Lighting:FindFirstChild("SaturationEffect")
if not saturationEffect then
	saturationEffect = Instance.new("ColorCorrectionEffect")
	saturationEffect.Name = "SaturationEffect"
	saturationEffect.Saturation = 0
	saturationEffect.Enabled = false
	saturationEffect.Parent = Lighting
end

local blurEffect = Lighting:FindFirstChild("BlurEffect_Motion")
if not blurEffect then
	blurEffect = Instance.new("BlurEffect")
	blurEffect.Name = "BlurEffect_Motion"
	blurEffect.Size = 0
	blurEffect.Parent = Lighting
end

local dizzyAngle = 0

local function playAnim(id)
	if currentAnimId == id then return end
	local anim = Instance.new("Animation")
	anim.AnimationId = id
	local newAnim = animator:LoadAnimation(anim)
	if currentAnim then
		currentAnim:AdjustWeight(0, 0.3)
		currentAnim:Stop(0.3)
	end
	newAnim:Play(0.3)
	currentAnim = newAnim
	currentAnimId = id
end

local function updateAnimState(dt)
	-- ...existing code for animation state...
	local moveSpeed = humanoid.MoveDirection.Magnitude
	local humanoidState = humanoid:GetState()
	local baseState = nil

	local isTrulyIdle = moveSpeed < 0.1 and not isRunning and not isPanicking and not isCrouching and not isFatigued and humanoid.Health > (humanoid.MaxHealth * 0.4)
	if isTrulyIdle then
		idleSwitchTimer = idleSwitchTimer + (dt or 0)
		if idleSwitchTimer >= idleSwitchInterval then
			idleToggle = not idleToggle
			idleSwitchTimer = 0
		end
	else
		idleSwitchTimer = 0
	end

	if isFatigued then
		baseState = "walk"
	elseif humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
		baseState = "jump"
	elseif humanoidState == Enum.HumanoidStateType.Climbing then
		if moveSpeed > 0.1 then baseState = "climb" else baseState = "climb_idle" end
	elseif isCrouching then
		if moveSpeed < 0.1 then baseState = "crouch_idle" else baseState = "crouch_walk" end
	elseif isPanicking and panicStamina > 0 then
		baseState = "panic"
	elseif panicCooldownActive or panicStamina <= 0 then
		if moveSpeed < 0.1 then
			baseState = idleToggle and "idle1" or "idle2"
		else
			baseState = isRunning and "run" or "walk"
		end
	else
		if moveSpeed < 0.1 and not isRunning then
			baseState = idleToggle and "idle1" or "idle2"
		elseif isRunning then
			baseState = "run"
		else
			baseState = "walk"
		end
	end

	local isHurt = humanoid.Health <= (humanoid.MaxHealth * 0.4)
	local state = baseState
	local animType = nil

	if isHurt then
		if baseState == "idle1" or baseState == "idle2" then
			state = "hurt_idle"
			animType = "hurt_idle"
		elseif baseState == "walk" then
			state = "hurt_walk"
			animType = "hurt_walk"
		elseif baseState == "run" then
			state = "hurt_run"
			animType = "hurt_run"
		else
			animType = baseState
		end
	else
		if baseState == "idle1" or baseState == "idle2" then
			animType = "idle"
		else
			animType = baseState
		end
	end

	if animType == "hurt_idle" then
		if lastAnimType == "idle" and currentAnim then
			currentAnim:Stop(0.2)
			currentAnim = nil
			currentAnimId = nil
		end
		if lastState ~= state then
			playAnim(anims[state])
		end
	elseif animType == "idle" then
		if lastAnimType ~= "hurt_idle" then
			if lastState ~= state then
				playAnim(anims[state])
			end
		end
	else
		if lastState ~= state then
			playAnim(anims[state])
		end
	end

	lastState = state
	lastAnimType = animType
end

local targetWalkSpeed = WALK_SPEED
humanoid.WalkSpeed = WALK_SPEED

-- Sound/overlay state flags
local lastPanicking = false
local lastFatigued = false
local lowStaminaSoundPlaying = false
local lowHealthOverlay = false

-- Centralized FOV logic
-- GTA4-style FOV offset: look up/down zoom effect
local function getGTA4FOVOffset()
	local cam = workspace.CurrentCamera
	local camLook = cam.CFrame.LookVector
	local upAmount = camLook:Dot(Vector3.new(0,1,0)) -- 1 = up, 0 = horizontal, -1 = down
	local gta4Offset = 0
	if upAmount > 0.4 then
		gta4Offset = (FOV_RUN - FOV_WALK) * ((upAmount - 0.4) / 0.6) -- up to +25 when looking up
	elseif upAmount < -0.4 then
		gta4Offset = -7 * ((-upAmount - 0.4) / 0.6) -- up to -7 when looking down
	end
	return gta4Offset
end

local function getTargetFOV()
	local fov, reason
	if isFatigued then
		fov, reason = 55, "fatigued"
	elseif isCrouching then
		fov, reason = FOV_CROUCH, "crouching"
	elseif isPanicking then
		fov, reason = FOV_PANIC, "panicking"
	elseif isRunning then
		fov, reason = FOV_RUN, "running"
	else
		fov, reason = FOV_WALK, "walking"
	end
	-- Add GTA4-style FOV offset
	local gta4Offset = getGTA4FOVOffset()
	local finalFOV = fov + gta4Offset
	print("[DEBUG] getTargetFOV: reason=", reason, "isRunning=", isRunning, "isCrouching=", isCrouching, "isPanicking=", isPanicking, "isFatigued=", isFatigued, "FOV=", fov, "GTA4Offset=", gta4Offset, "finalFOV=", finalFOV)
	return finalFOV
end

-- Centralized camera update
local function updateCamera(dt)
	local desiredFOV = getTargetFOV()
	local fovLerpSpeed = 6
	if isPanicking then
		fovLerpSpeed = 3
	elseif isRunning then
		fovLerpSpeed = 3
	elseif isCrouching then
		fovLerpSpeed = 8
	elseif isFatigued then
		fovLerpSpeed = 2
	end
	print("[DEBUG] updateCamera: isRunning=", isRunning, "isCrouching=", isCrouching, "isPanicking=", isPanicking, "isFatigued=", isFatigued, "desiredFOV=", desiredFOV, "currentFOV=", cam.FieldOfView)
	-- For debugging, force FOV instantly:
	-- cam.FieldOfView = desiredFOV
	cam.FieldOfView = cam.FieldOfView + (desiredFOV - cam.FieldOfView) * math.clamp(dt * fovLerpSpeed, 0, 1)
end

-- Camera pitch clamp settings
local MAX_UP_ANGLE = math.rad(70)   -- 70 degrees up from horizontal
local MAX_DOWN_ANGLE = math.rad(-70) -- 70 degrees down from horizontal

local function clampCameraPitch(cam)
	-- Get camera's current CFrame and decompose to get pitch
	local look = cam.CFrame.LookVector
	local flatLook = Vector3.new(look.X, 0, look.Z)
	if flatLook.Magnitude < 1e-4 then return end -- avoid division by zero
	local flatLookUnit = flatLook.Unit
	local up = Vector3.new(0,1,0)
	local pitch = math.asin(look.Y)
	if pitch > MAX_UP_ANGLE then
		-- Clamp up
		local axis = flatLookUnit:Cross(up)
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + flatLookUnit * math.cos(MAX_UP_ANGLE) + up * math.sin(MAX_UP_ANGLE))
	elseif pitch < MAX_DOWN_ANGLE then
		-- Clamp down
		local axis = flatLookUnit:Cross(up)
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, cam.CFrame.Position + flatLookUnit * math.cos(MAX_DOWN_ANGLE) + up * math.sin(MAX_DOWN_ANGLE))
	end
end

RunService.RenderStepped:Connect(function(dt)
	humanoid.WalkSpeed = humanoid.WalkSpeed + (targetWalkSpeed - humanoid.WalkSpeed) * math.clamp(dt * SPEED_LERP_RATE, 0, 1)

	-- Dual stamina logic
	if isPanicking then
		panicStamina -= dt * 20
		panicSaturation = math.clamp(panicSaturation + dt * 1.2, 0, 1)
		saturationEffect.Saturation = panicSaturation
		saturationEffect.Enabled = true
	else
		panicSaturation = 0
	end

	-- Only deplete stamina and allow running if moving
	local moveInput = UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D)
	-- Fix: Only turn off running if crouching or panicking, not just if either is true
	if isRunning then
		if isCrouching then
			isRunning = false
			print("[DEBUG] isRunning set to false (crouching)")
			targetWalkSpeed = CROUCH_SPEED
		elseif isPanicking then
			isRunning = false
			print("[DEBUG] isRunning set to false (panicking)")
			targetWalkSpeed = WALK_SPEED
		elseif not moveInput then
			isRunning = false
			print("[DEBUG] isRunning set to false (no move input)")
			targetWalkSpeed = WALK_SPEED
		end
	end
	if isRunning and not isPanicking and moveInput then
	runStamina -= dt * 10
	else
		-- Only regenerate stamina if not fatigued
		if not isFatigued then
			runStamina += dt * 15
		end
		-- Only regenerate panic bar if not fatigued
		if panicCooldownActive then
			if not isFatigued then
				local elapsed = math.clamp(tick() - panicCooldownStart, 0, panicCooldownTime)
				panicStamina = 100 * (elapsed / panicCooldownTime)
			end
		end
	end

	runStamina = math.clamp(runStamina, 0, 100)
	-- Only clamp panicStamina to 100 if not panicking and not in cooldown
	if not panicCooldownActive and not isPanicking then
		panicStamina = math.clamp(panicStamina, 0, 100)
	end

	runBar.Size = UDim2.new(0, 120 * (runStamina/100), 0, 18)
	panicBar.Size = UDim2.new(0, 120 * (panicStamina/100), 0, 18)

	-- Custom: Slow down run speed when stamina < 30%
	if isRunning and not isPanicking then
		if runStamina <= 30 and runStamina > 0 then
			local minSpeed = 20
			local maxSpeed = RUN_SPEED
			local percent = runStamina / 30
			targetWalkSpeed = minSpeed + (maxSpeed - minSpeed) * percent
		elseif runStamina > 30 then
			targetWalkSpeed = RUN_SPEED
		end
	end

	if runStamina <= 0 then
		runBar.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
		runLocked = true
	else
		runLocked = false
	end

	if runStamina >= 25 then
		runBar.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
	elseif runStamina > 0 then
		runBar.BackgroundColor3 = Color3.fromRGB(180, 180, 180)
	end

	if panicStamina <= 0 then
		panicBar.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
		-- Start panic cooldown if not already active
		if not panicCooldownActive then
			panicCooldownActive = true
			panicCooldownStart = tick()
			isPanicking = false -- Ensure panic run is stopped if stamina is depleted
			isRunning = false
			targetWalkSpeed = WALK_SPEED
		end
	else
		panicBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	end

	-- Custom: Decrease HP slowly when running and stamina is 0
	if isRunning and not isPanicking and runStamina <= 0 then
		humanoid.Health = math.max(0, humanoid.Health - dt * 2) -- lose 2 HP per second
	end

	-- HORROR HUD ALERTS & EFFECTS
	local t = tick()
	if isPanicking or isFatigued or runStamina < 25 then
		local pulse = math.abs(math.sin(t*8))
		bgFrame.BackgroundColor3 = Color3.fromRGB(30 + pulse*80, 0, 0)
		horrorOutline.Transparency = 0.1 + pulse*0.2
		bgFrame.Position = UDim2.new(1, -30 + math.random(-2,2), 1, -30 + math.random(-2,2))
		if isPanicking then
			alertLabel.Text = "PANIC!"
			alertLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
			panicLabel.TextColor3 = Color3.fromRGB(255, pulse*180, pulse*180)
		elseif isFatigued then
			alertLabel.Text = "FATIGUED!"
			alertLabel.TextColor3 = Color3.fromRGB(255, 120 + pulse*80, 0)
			panicLabel.TextColor3 = Color3.fromRGB(255, 120 + pulse*80, 0)
		elseif runStamina < 25 then
			alertLabel.Text = "RUN!"
			alertLabel.TextColor3 = Color3.fromRGB(255, 255*pulse, 0)
			runLabel.TextColor3 = Color3.fromRGB(255, 80 + pulse*80, 80 + pulse*80)
		end
	else
		bgFrame.BackgroundColor3 = Color3.fromRGB(10, 0, 0)
		horrorOutline.Transparency = 0.2
		bgFrame.Position = UDim2.new(1, -30, 1, -30)
		alertLabel.Text = ""
		panicLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
		runLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
	end

	-- SOUNDS
	if isPanicking and not lastPanicking then
		playSound(SOUND_PANIC, 1.2)
	end
	if isFatigued and not lastFatigued then
		playSound(SOUND_FATIGUE, 1)
	end
	if (runStamina < 20 or panicStamina < 20) and not lowStaminaSoundPlaying then
		playSound(SOUND_BREATH, 0.7)
		playSound(SOUND_HEART, 0.7)
		lowStaminaSoundPlaying = true
	elseif runStamina >= 20 and panicStamina >= 20 then
		lowStaminaSoundPlaying = false
	end
	lastPanicking = isPanicking
	lastFatigued = isFatigued

	-- BLOOD OVERLAY
	if humanoid.Health <= (humanoid.MaxHealth * 0.4) then
		if bloodOverlay then
			bloodOverlay.ImageTransparency = 0.2 + math.abs(math.sin(t*3))*0.2
			lowHealthOverlay = true
		end
	else
		if bloodOverlay and lowHealthOverlay then
			bloodOverlay.ImageTransparency = 1
			lowHealthOverlay = false
		end
	end

	-- Fatigue y cooldown
	if isFatigued then
		local elapsed = tick() - fatigueStartTime
		local osc = math.sin(elapsed * 4) * 1.2
		saturationEffect.Saturation = math.clamp(osc, -1, 1)
		saturationEffect.Enabled = true
		blurEffect.Size = 10
		updateCamera(dt)
		targetWalkSpeed = WALK_SPEED
		humanoid.WalkSpeed = WALK_SPEED
		isRunning = false
		isPanicking = false
		cam.CFrame = cam.CFrame * CFrame.new(math.random(-1,1)*0.2, math.random(-1,1)*0.2, 0)
		if elapsed >= fatigueDuration then
			isFatigued = false
			saturationEffect.Enabled = false
			blurEffect.Size = 0
			cam.FieldOfView = FOV_WALK
			panicCooldownActive = true
			panicCooldownStart = tick()
		end
	elseif panicCooldownActive then
		saturationEffect.Enabled = false
		blurEffect.Size = 0
		updateCamera(dt)
		-- Regenerate panic bar visually and logically during cooldown
		local elapsed = math.clamp(tick() - panicCooldownStart, 0, panicCooldownTime)
		local cdLeft = math.max(0, panicCooldownTime - elapsed)
		panicStamina = math.clamp(100 * (elapsed / panicCooldownTime), 0, 100)
		if cdLeft <= 0 then
			panicCooldownActive = false
			panicStamina = 100
		end
	else
		if isPanicking then
			dizzyAngle += dt * 2
			local dizzyX = math.sin(dizzyAngle) * 0.02
			local dizzyY = math.cos(dizzyAngle * 1.5) * 0.02
			cam.CFrame = cam.CFrame * CFrame.Angles(dizzyX, dizzyY, 0)
			blurEffect.Size = 0
			updateCamera(dt)
			cam.CFrame = cam.CFrame * CFrame.new(math.random(-1,1)*0.03, math.random(-1,1)*0.03, 0)
		elseif isRunning then
			updateCamera(dt)
			blurEffect.Size = 0
			if runStamina < 40 then
				saturationEffect.Saturation = -1 + (runStamina / 40)
				saturationEffect.Enabled = true
			else
				saturationEffect.Enabled = false
			end
		else
			updateCamera(dt)
			blurEffect.Size = 0
			saturationEffect.Enabled = false
		end
	end

	-- Si el panic run se queda sin stamina, activa fatiga
	if panicStamina <= 0 and isPanicking and not isFatigued then
		isPanicking = false
		isRunning = false
		isFatigued = true
		fatigueStartTime = tick()
	end

	-- Centralized FOV update
	targetFOV = getTargetFOV()
	local fovLerpSpeed = 6
	if isPanicking then
		fovLerpSpeed = 3
	elseif isRunning then
		fovLerpSpeed = 4
	elseif isCrouching then
		fovLerpSpeed = 8
	elseif isFatigued then
		fovLerpSpeed = 2
	end
	cam.FieldOfView = cam.FieldOfView + (targetFOV - cam.FieldOfView) * math.clamp(dt * fovLerpSpeed, 0, 1)

	-- Clamp camera pitch (prevents looking too far up or down)
	clampCameraPitch(cam)

	-- FORCEFULLY block all jump attempts if Ctrl is held (even if other scripts or Roblox core try to set it)
	RunService.Stepped:Connect(function()
		if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
			if humanoid.Jump then
				humanoid.Jump = false
			end
		end
	end)

	updateAnimState(dt)
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		local now = tick()
		-- Check if any movement key is pressed
		local moveInput = UIS:IsKeyDown(Enum.KeyCode.W) or UIS:IsKeyDown(Enum.KeyCode.A) or UIS:IsKeyDown(Enum.KeyCode.S) or UIS:IsKeyDown(Enum.KeyCode.D)
		if not moveInput then
			-- If shift is pressed but no movement key, do nothing (stay idle)
			return
		end
		-- Prevent running or panic while crouched
		if isCrouching then return end
		if not isFatigued and not panicCooldownActive and panicStamina == 100 and runStamina >= 50 and (now - lastShift) < DOUBLE_TAP_TIME then
			-- Double tap detected: start panic run
			isPanicking = true
			isRunning = false
			targetWalkSpeed = PANIC_SPEED
			panicBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			updateAnimState()
		else
			-- First tap: just start running if allowed
		if not isPanicking and runStamina > 5 and not isFatigued and not runLocked then
			isRunning = true
			print("[DEBUG] isRunning set to true (InputBegan: LeftShift, running started)")
			targetWalkSpeed = RUN_SPEED
			updateAnimState()
		end
		end
		lastShift = now
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		if not isPanicking and not isFatigued then
			isCrouching = true
			isRunning = false -- Stop running if crouch is pressed
			targetWalkSpeed = CROUCH_SPEED
			updateAnimState()
		end
	elseif input.KeyCode == Enum.KeyCode.Space then
		-- Prevent jumping while crouched
		if isCrouching then
			return
		end
	end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		if isPanicking then
			isPanicking = false
			isRunning = false
			targetWalkSpeed = WALK_SPEED
			panicBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
			saturationEffect.Saturation = 0
			saturationEffect.Enabled = false
			-- If panic bar is under 20% on release, trigger fatigue
			if panicStamina < 20 and not isFatigued then
				isFatigued = true
				fatigueStartTime = tick()
			elseif not panicCooldownActive then
				panicStamina = 0
				panicCooldownActive = true
				panicCooldownStart = tick()
			end
		else
			isRunning = false
			targetWalkSpeed = WALK_SPEED
			-- Fatigue if runStamina is at or below 20% on release
			if runStamina <= 20 and not isFatigued then
				isFatigued = true
				fatigueStartTime = tick()
			end
		end
		updateAnimState()
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		isCrouching = false
		targetWalkSpeed = isRunning and RUN_SPEED or WALK_SPEED
		updateAnimState()
	end
end)

humanoid.Died:Connect(function()
	if cam then
		cam.FieldOfView = FOV_WALK
		blurEffect.Size = 0
		saturationEffect.Enabled = false
	end
	alertLabel.Text = "DEAD"
	if bloodOverlay then
		bloodOverlay.ImageTransparency = 0.1
	end
end)

humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		alertLabel.Text = "DEAD"
		if bloodOverlay then
			bloodOverlay.ImageTransparency = 0.1
		end
	end
end)