-- RbxCharacterSounds: Sistema avanzado de sonidos de personaje para Roblox

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local FootstepsSoundGroup = SoundService:WaitForChild("Footsteps")

local SOUND_DATA = {
	Climbing = {
		SoundId = "rbxasset://sounds/action_footsteps_plastic.mp3",
		Looped = true,
	},
	Died = {
		SoundId = "rbxasset://sounds/uuhhh.mp3",
	},
	FreeFalling = {
		SoundId = "rbxasset://sounds/action_falling.mp3",
		Looped = true,
	},
	GettingUp = {
		SoundId = "rbxasset://sounds/action_get_up.mp3",
	},
	Jumping = {
		SoundId = "rbxasset://sounds/action_jump.mp3",
	},
	Landing = {
		SoundId = "rbxasset://sounds/action_jump_land.mp3",
	},
	Running = {
		SoundId = '',
		Looped = true,
		Playing = true,
		Pitch = 1,
	},
	Splash = {
		SoundId = "rbxasset://sounds/impact_water.mp3",
	},
	Swimming = {
		SoundId = "rbxasset://sounds/action_swim.mp3",
		Looped = true,
		Pitch = 1.6,
	},
}

local function map(x, inMin, inMax, outMin, outMax)
	return (x - inMin)*(outMax - outMin)/(inMax - inMin) + outMin
end

local function playSound(sound)
	sound.TimePosition = 0
	sound.Playing = true
end

local function stopSound(sound)
	sound.Playing = false
	sound.TimePosition = 0
end

local function initializeSoundSystem(player, humanoid, rootPart)
	local sounds = {}
	for name, props in pairs(SOUND_DATA) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.Archivable = false
		sound.EmitterSize = 5
		sound.MaxDistance = 150
		sound.Volume = 0.65
		for propName, propValue in pairs(props) do
			sound[propName] = propValue
		end
		sound.Parent = rootPart
		sounds[name] = sound
	end

	local playingLoopedSounds = {}

	local function stopPlayingLoopedSounds(except)
		for sound in pairs(playingLoopedSounds) do
			if sound ~= except then
				sound.Playing = false
				playingLoopedSounds[sound] = nil
			end
		end
	end

	local function getFootstepProps(humanoid)
		local mat = humanoid.FloorMaterial
		local props = FootstepsSoundGroup:FindFirstChild(mat) or FootstepsSoundGroup:FindFirstChild("nil Sound")
		return props
	end

	local stateTransitions = {
		[Enum.HumanoidStateType.FallingDown] = function()
			stopPlayingLoopedSounds()
		end,
		[Enum.HumanoidStateType.GettingUp] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.GettingUp)
		end,
		[Enum.HumanoidStateType.Jumping] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.Jumping)
		end,
		[Enum.HumanoidStateType.Swimming] = function()
			local verticalSpeed = math.abs(rootPart.Velocity.Y)
			if verticalSpeed > 0.1 then
				sounds.Splash.Volume = math.clamp(map(verticalSpeed, 100, 350, 0.28, 1), 0, 1)
				playSound(sounds.Splash)
			end
			stopPlayingLoopedSounds(sounds.Swimming)
			sounds.Swimming.Playing = true
			playingLoopedSounds[sounds.Swimming] = true
		end,
		[Enum.HumanoidStateType.Freefall] = function()
			sounds.FreeFalling.Volume = 0
			stopPlayingLoopedSounds(sounds.FreeFalling)
			playingLoopedSounds[sounds.FreeFalling] = true
		end,
		[Enum.HumanoidStateType.Landed] = function()
			stopPlayingLoopedSounds()
			local verticalSpeed = math.abs(rootPart.Velocity.Y)
			if verticalSpeed > 75 then
				sounds.Landing.Volume = math.clamp(map(verticalSpeed, 50, 100, 0, 1), 0, 1)
				playSound(sounds.Landing)
			end
		end,
		[Enum.HumanoidStateType.Running] = function()
			stopPlayingLoopedSounds(sounds.Running)
			local props = getFootstepProps(humanoid)
			if props then
				sounds.Running.SoundId = props.SoundId
				sounds.Running.PlaybackSpeed = props.PlaybackSpeed
				sounds.Running.Volume = props.Volume
			end
			sounds.Running.Playing = true
			playingLoopedSounds[sounds.Running] = true
		end,
		[Enum.HumanoidStateType.Climbing] = function()
			local sound = sounds.Climbing
			if math.abs(rootPart.Velocity.Y) > 0.1 then
				sound.Playing = true
				stopPlayingLoopedSounds(sound)
			else
				stopPlayingLoopedSounds()
			end
			playingLoopedSounds[sound] = true
		end,
		[Enum.HumanoidStateType.Seated] = function()
			stopPlayingLoopedSounds()
		end,
		[Enum.HumanoidStateType.Dead] = function()
			stopPlayingLoopedSounds()
			playSound(sounds.Died)
		end,
	}

	local loopedSoundUpdaters = {
		[sounds.Climbing] = function(dt, sound, vel)
			sound.Playing = vel.Magnitude > 0.1
		end,
		[sounds.FreeFalling] = function(dt, sound, vel)
			if vel.Magnitude > 75 then
				sound.Volume = math.clamp(sound.Volume + 0.9*dt, 0, 1)
			else
				sound.Volume = 0
			end
		end,
		[sounds.Running] = function(dt, sound, vel)
			local props = getFootstepProps(humanoid)
			if props then
				sound.SoundId = props.SoundId
				sound.PlaybackSpeed = props.PlaybackSpeed * (vel.Magnitude/20)
				sound.Volume = props.Volume * (vel.Magnitude/12)
				sound.EmitterSize = props.Volume * (vel.Magnitude/12) * 50
			end
			sound.Playing = vel.Magnitude > 1 and humanoid.MoveDirection.Magnitude > 0.1
		end,
	}

	local stateRemap = {
		[Enum.HumanoidStateType.RunningNoPhysics] = Enum.HumanoidStateType.Running,
	}

	local activeState = stateRemap[humanoid:GetState()] or humanoid:GetState()

	local stateChangedConn = humanoid.StateChanged:Connect(function(_, state)
		state = stateRemap[state] or state
		if state ~= activeState then
			local transitionFunc = stateTransitions[state]
			if transitionFunc then
				transitionFunc()
			end
			activeState = state
		end
	end)

	local steppedConn = RunService.Stepped:Connect(function(_, worldDt)
		for sound in pairs(playingLoopedSounds) do
			local updater = loopedSoundUpdaters[sound]
			if updater then
				updater(worldDt, sound, rootPart.Velocity)
			end
		end
	end)

	local humanoidAncestryChangedConn
	local rootPartAncestryChangedConn
	local characterAddedConn

	local function terminate()
		stateChangedConn:Disconnect()
		steppedConn:Disconnect()
		humanoidAncestryChangedConn:Disconnect()
		rootPartAncestryChangedConn:Disconnect()
		characterAddedConn:Disconnect()
	end

	humanoidAncestryChangedConn = humanoid.AncestryChanged:Connect(function(_, parent)
		if not parent then terminate() end
	end)
	rootPartAncestryChangedConn = rootPart.AncestryChanged:Connect(function(_, parent)
		if not parent then terminate() end
	end)
	characterAddedConn = player.CharacterAdded:Connect(terminate)
end

local function playerAdded(player)
	local function characterAdded(character)
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local rootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoid and rootPart then
			initializeSoundSystem(player, humanoid, rootPart)
		end
	end
	if player.Character then characterAdded(player.Character) end
	player.CharacterAdded:Connect(characterAdded)
end

Players.PlayerAdded:Connect(playerAdded)
for _, player in ipairs(Players:GetPlayers()) do
	playerAdded(player)
end
