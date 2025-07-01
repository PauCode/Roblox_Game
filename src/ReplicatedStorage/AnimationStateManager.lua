local lastAnimType = nil
local currentIdle = "idle1"
local idlePlaying = false
local idleTrack = nil

local function playIdleRandom()
	local nextIdle = math.random() < 0.5 and "idle1" or "idle2"
	currentIdle = nextIdle
	if idleTrack then
		idleTrack:Disconnect()
		idleTrack = nil
	end
	local track = animManager:play(currentIdle)
	if track and track.Stopped then
		idleTrack = track.Stopped:Connect(function()
			if idlePlaying then
				playIdleRandom()
			end
		end)
	end
	lastAnimType = "idle"
end

local function updateAnimState(dt)
	local moveSpeed = humanoid.MoveDirection.Magnitude
	local humanoidState = humanoid:GetState()
	local baseState = nil

	local isTrulyIdle = moveSpeed < 0.1 and not isRunning and not isPanicking and not isCrouching and not isFatigued and humanoid.Health > (humanoid.MaxHealth * 0.4)
	if isTrulyIdle then
		if not idlePlaying then
			playIdleRandom()
			idlePlaying = true
		end
		return
	else
		if idleTrack then
			idleTrack:Disconnect()
			idleTrack = nil
		end
		idlePlaying = false
	end

	if isFatigued then
		baseState = "idle1"
	elseif humanoidState == Enum.HumanoidStateType.Jumping or humanoidState == Enum.HumanoidStateType.Freefall then
		baseState = "jump"
	elseif humanoidState == Enum.HumanoidStateType.Climbing then
		baseState = moveSpeed > 0.1 and "climb" or "climb_idle"
	elseif isCrouching then
		baseState = moveSpeed < 0.1 and "crouch_idle" or "crouch_walk"
	elseif isPanicking and stamina > 0 then
		baseState = "panic"
	elseif panicCooldownActive or stamina <= 0 then
		baseState = moveSpeed < 0.1 and "idle1" or (isRunning and "run" or "walk")
	else
		if moveSpeed < 0.1 and not isRunning then
			baseState = "idle1"
		elseif isRunning then
			baseState = "run"
		else
			baseState = "walk"
		end
	end

	local isHurt = humanoid.Health <= (humanoid.MaxHealth * 0.4)
	local animName = baseState
	local animType = baseState

	if isHurt then
		if baseState == "idle1" or baseState == "idle2" then
			animName = "hurt_idle"
			animType = "hurt_idle"
		elseif baseState == "walk" then
			animName = "hurt_walk"
			animType = "hurt_walk"
		elseif baseState == "run" then
			animName = "hurt_run"
			animType = "hurt_run"
		end
	else
		if baseState == "idle1" or baseState == "idle2" then
			animType = "idle"
		end
	end

	-- Solo cambia animación si NO es idle
	if animType == "idle" then
		-- No hagas nada, el ciclo idle random lo gestiona playIdleRandom y el evento .Stopped
	else
		-- Si sales de idle, sí cambia la animación
		if animType ~= lastAnimType then
			animManager:play(animName)
		end
	end

	lastAnimType = animType
end