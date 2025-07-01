--[[ 
  Script: Advanced Run, Panic, Crouch, Stamina, FOV, Camera Shake, and Animation Handler
  Place this script in StarterCharacterScripts.
  FIXES:
    - Dual stamina bars (RUN y PANIC) con HUD visual llamativo.
    - Panic run con saturación progresiva y aturdimiento con saturación oscilante y zoom/deszoom.
--]]

local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local cam = workspace.CurrentCamera

-- Animation asset IDs
local anims = {
	idle1 = "rbxassetid://111219973667367",
	idle2 = "rbxassetid://96792590819142",
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

-- Movement and stamina settings
local WALK_SPEED = 14
local RUN_SPEED = 26
local PANIC_SPEED = 40
local CROUCH_SPEED = 7
local SPEED_LERP_RATE = 8
local DOUBLE_TAP_TIME = 0.3
local runStamina = 100
local panicStamina = 100
local isRunning = false
local isPanicking = false
local isCrouching = false
local lastShift = 0

-- Aturdimiento y cooldown
local isStunned = false
local stunStartTime = 0
local stunDuration = 10
local panicCooldownActive = false
local panicCooldownStart = 0
local panicCooldownTime = 30
local panicSaturation = 0

-- Animation state
local animator = humanoid:WaitForChild("Animator")
local currentAnim = nil
local currentAnimId = nil
local lastState = nil
local lastAnimType = nil

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

-- UI for stamina (dual bars, visual)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StaminaDisplay"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local bgFrame = Instance.new("Frame")
bgFrame.AnchorPoint = Vector2.new(1, 1)
bgFrame.Position = UDim2.new(1, -20, 1, -20)
bgFrame.Size = UDim2.new(0, 170, 0, 80)
bgFrame.BackgroundTransparency = 0.2
bgFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
bgFrame.BorderSizePixel = 0
bgFrame.Parent = screenGui

local runBar = Instance.new("Frame")
runBar.Position = UDim2.new(0, 10, 0, 15)
runBar.Size = UDim2.new(0, 120, 0, 18)
runBar.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
runBar.BorderSizePixel = 0
runBar.BackgroundTransparency = 0.1
runBar.Parent = bgFrame

local runBarOutline = Instance.new("UIStroke")
runBarOutline.Color = Color3.fromRGB(0, 60, 120)
runBarOutline.Thickness = 2
runBarOutline.Parent = runBar

local runLabel = Instance.new("TextLabel")
runLabel.Position = UDim2.new(0, 135, 0, 15)
runLabel.Size = UDim2.new(0, 30, 0, 18)
runLabel.BackgroundTransparency = 1
runLabel.TextColor3 = Color3.fromRGB(80, 180, 255)
runLabel.Font = Enum.Font.GothamBold
runLabel.TextSize = 16
runLabel.TextXAlignment = Enum.TextXAlignment.Left
runLabel.TextYAlignment = Enum.TextYAlignment.Center
runLabel.Text = "RUN"
runLabel.Parent = bgFrame

local panicBar = Instance.new("Frame")
panicBar.Position = UDim2.new(0, 10, 0, 45)
panicBar.Size = UDim2.new(0, 120, 0, 18)
panicBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
panicBar.BorderSizePixel = 0
panicBar.BackgroundTransparency = 0.1
panicBar.Parent = bgFrame

local panicBarOutline = Instance.new("UIStroke")
panicBarOutline.Color = Color3.fromRGB(120, 0, 0)
panicBarOutline.Thickness = 2
panicBarOutline.Parent = panicBar

local panicLabel = Instance.new("TextLabel")
panicLabel.Position = UDim2.new(0, 135, 0, 45)
panicLabel.Size = UDim2.new(0, 30, 0, 18)
panicLabel.BackgroundTransparency = 1
panicLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
panicLabel.Font = Enum.Font.GothamBold
panicLabel.TextSize = 16
panicLabel.TextXAlignment = Enum.TextXAlignment.Left
panicLabel.TextYAlignment = Enum.TextYAlignment.Center
panicLabel.Text = "PANIC"
panicLabel.Parent = bgFrame

local glow = Instance.new("UIGradient")
glow.Color = ColorSequence.new{
	ColorSequenceKeypoint.new(0, Color3.fromRGB(80,180,255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255,255,255)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255,80,80))
}
glow.Rotation = 0
glow.Parent = bgFrame

local label = Instance.new("TextLabel")
label.AnchorPoint = Vector2.new(1, 1)
label.Position = UDim2.new(1, -10, 1, -110)
label.Size = UDim2.new(0, 120, 0, 30)
label.BackgroundTransparency = 0.5
label.BackgroundColor3 = Color3.new(0, 0, 0)
label.TextColor3 = Color3.new(1, 1, 1)
label.Font = Enum.Font.SourceSansBold
label.TextSize = 20
label.TextXAlignment = Enum.TextXAlignment.Right
label.TextYAlignment = Enum.TextYAlignment.Center
label.Parent = screenGui
label.Text = "Ready"

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
	local moveSpeed = humanoid.MoveDirection.Magnitude
	local humanoidState = humanoid:GetState()
	local baseState = nil

	local isTrulyIdle = moveSpeed < 0.1 and not isRunning and not isPanicking and not isCrouching and not isStunned and humanoid.Health > (humanoid.MaxHealth * 0.4)
	if isTrulyIdle then
		idleSwitchTimer = idleSwitchTimer + (dt or 0)
		if idleSwitchTimer >= idleSwitchInterval then
			idleToggle = not idleToggle
			idleSwitchTimer = 0
		end
	else
		idleSwitchTimer = 0
	end

	if isStunned then
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

RunService.RenderStepped:Connect(function(dt)
	humanoid.WalkSpeed = humanoid.WalkSpeed + (targetWalkSpeed - humanoid.WalkSpeed) * math.clamp(dt * SPEED_LERP_RATE, 0, 1)

	-- Dual stamina logic
	if isPanicking then
		panicStamina -= dt * 20
		-- Saturación progresiva durante panic run
		panicSaturation = math.clamp(panicSaturation + dt * 1.2, 0, 1)
		saturationEffect.Saturation = panicSaturation
		saturationEffect.Enabled = true
	else
		panicSaturation = 0
	end

	if isRunning and not isPanicking then
		runStamina -= dt * 10
	else
		runStamina += dt * 15
		panicStamina += dt * 10
	end

	runStamina = math.clamp(runStamina, 0, 100)
	panicStamina = math.clamp(panicStamina, 0, 100)

	runBar.Size = UDim2.new(0, 120 * (runStamina/100), 0, 18)
	panicBar.Size = UDim2.new(0, 120 * (panicStamina/100), 0, 18)

	if runStamina <= 0 then
		runBar.BackgroundColor3 = Color3.fromRGB(120, 120, 120)
	else
		runBar.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
	end
	if panicStamina <= 0 then
		panicBar.BackgroundColor3 = Color3.fromRGB(120, 60, 60)
	else
		panicBar.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
	end

	-- Aturdimiento y cooldown
	if isStunned then
		local elapsed = tick() - stunStartTime
		-- Saturación oscilante fuerte y zoom/deszoom
		local osc = math.sin(elapsed * 4) * 1.2
		saturationEffect.Saturation = math.clamp(osc, -1, 1)
		saturationEffect.Enabled = true
		blurEffect.Size = 10
		cam.FieldOfView = 55 + math.sin(elapsed * 2) * 8
		targetWalkSpeed = WALK_SPEED
		humanoid.WalkSpeed = WALK_SPEED
		isRunning = false
		isPanicking = false
		label.Text = "Stunned!"
		label.TextColor3 = Color3.new(1, 0.5, 0)
		if elapsed >= stunDuration then
			isStunned = false
			saturationEffect.Enabled = false
			blurEffect.Size = 0
			cam.FieldOfView = 70
			panicCooldownActive = true
			panicCooldownStart = tick()
			label.Text = "Cooldown"
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	elseif panicCooldownActive then
		saturationEffect.Enabled = false
		blurEffect.Size = 0
		cam.FieldOfView = 70
		local cdLeft = math.max(0, panicCooldownTime - (tick() - panicCooldownStart))
		label.Text = string.format("Cooldown %.1f s", cdLeft)
		label.TextColor3 = Color3.new(1, 1, 1)
		if cdLeft <= 0 then
			panicCooldownActive = false
			panicStamina = 100
			label.Text = "Ready"
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	else
		-- Efectos de cámara normales
		if isPanicking then
			dizzyAngle += dt * 2
			local dizzyX = math.sin(dizzyAngle) * 0.05
			local dizzyY = math.cos(dizzyAngle * 1.5) * 0.05
			cam.CFrame = cam.CFrame * CFrame.Angles(dizzyX, dizzyY, 0)
			blurEffect.Size = 0
			cam.FieldOfView = cam.FieldOfView + (110 - cam.FieldOfView) * math.clamp(dt * 3, 0, 1)
			label.Text = string.format("Panic: %d", panicStamina)
			label.TextColor3 = Color3.new(1, 0, 0)
		elseif isRunning then
			cam.FieldOfView = cam.FieldOfView + (85 - cam.FieldOfView) * math.clamp(dt * 3, 0, 1)
			blurEffect.Size = 0
			saturationEffect.Enabled = false
			label.Text = string.format("Run: %d", runStamina)
			label.TextColor3 = Color3.new(0.7, 0.9, 1)
		else
			cam.FieldOfView = cam.FieldOfView + (70 - cam.FieldOfView) * math.clamp(dt * 6, 0, 1)
			blurEffect.Size = 0
			saturationEffect.Enabled = false
			label.Text = "Ready"
			label.TextColor3 = Color3.new(1, 1, 1)
		end
	end

	-- Si el panic run se queda sin stamina, activa aturdimiento
	if panicStamina <= 0 and isPanicking and not isStunned then
		isPanicking = false
		isRunning = false
		isStunned = true
		stunStartTime = tick()
		label.Text = "Stunned!"
		label.TextColor3 = Color3.new(1, 0.5, 0)
	end

	updateAnimState(dt)
end)

UIS.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift then
		local now = tick()
		if not isStunned and not panicCooldownActive and now - lastShift < DOUBLE_TAP_TIME and panicStamina > 20 and not isCrouching then
			isPanicking = true
			isRunning = false
			targetWalkSpeed = PANIC_SPEED
			panicBar.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			label.Text = "Panic!"
			label.TextColor3 = Color3.new(1, 0, 0)
			updateAnimState()
		else
			if not isPanicking and runStamina > 5 and not isStunned and not isCrouching then
				isRunning = true
				targetWalkSpeed = RUN_SPEED
				updateAnimState()
			end
		end
		lastShift = now
	elseif input.KeyCode == Enum.KeyCode.LeftControl then
		if not isPanicking and not isStunned then
			isCrouching = true
			targetWalkSpeed = CROUCH_SPEED
			updateAnimState()
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
		else
			isRunning = false
			targetWalkSpeed = WALK_SPEED
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
		cam.FieldOfView = 70
		blurEffect.Size = 0
		saturationEffect.Enabled = false
	end
	label.Text = "Dead"
end)

humanoid.HealthChanged:Connect(function(health)
	if health <= 0 then
		label.Text = "Dead"
	end
end)