local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

local painSounds = {
	"rbxassetid://101433568913389",
	-- agrega más sonidos si quieres
}

local deathSounds = {
	"rbxassetid://87080612196118",
	-- agrega más sonidos si quieres
}

local painSoundInstance = nil
local deathSoundInstance = nil
local lastPainTime = 0
local isDead = false

local function stopPainSound()
	if painSoundInstance then
		painSoundInstance:Stop()
		painSoundInstance:Destroy()
		painSoundInstance = nil
	end
end

local function playPainSound()
	if isDead then return end -- si murió, no hacer nada

	local now = tick()
	if now - lastPainTime < 4 then return end
	lastPainTime = now

	if painSoundInstance and painSoundInstance.IsPlaying then return end

	local head = character:FindFirstChild("Head")
	if not head then return end

	if painSoundInstance then
		painSoundInstance:Destroy()
	end

	painSoundInstance = Instance.new("Sound")
	painSoundInstance.SoundId = painSounds[math.random(1, #painSounds)]
	painSoundInstance.Volume = 1
	painSoundInstance.RollOffMode = Enum.RollOffMode.Linear
	painSoundInstance.EmitterSize = 2
	painSoundInstance.MaxDistance = 20
	painSoundInstance.Parent = head
	painSoundInstance:Play()

	painSoundInstance.Ended:Connect(function()
		painSoundInstance:Destroy()
		painSoundInstance = nil
	end)
end


local function playDeathSound()
	isDead = true
	stopPainSound() -- para inmediatamente el sonido de dolor

	local head = character:FindFirstChild("Head")
	if not head then
		print("[DeathAndPain] No head found, parenting death sound to workspace.")
	end

	local parentForSound = head or workspace
	print("[DeathAndPain] Playing death sound, parent:", parentForSound.Name)

	deathSoundInstance = Instance.new("Sound")
	deathSoundInstance.SoundId = deathSounds[math.random(1, #deathSounds)]
	deathSoundInstance.Volume = 1
	deathSoundInstance.RollOffMode = Enum.RollOffMode.Inverse
	deathSoundInstance.EmitterSize = 10
	deathSoundInstance.MaxDistance = 100
	deathSoundInstance.Parent = parentForSound
	deathSoundInstance:Play()

	deathSoundInstance.Ended:Connect(function()
		print("[DeathAndPain] Death sound ended and destroyed.")
		deathSoundInstance:Destroy()
		deathSoundInstance = nil
	end)
end



-- Fix: typo in function name and event handler
local function connectDeath()
	if humanoid then
		humanoid.Died:Connect(playDeathSound)
	end
end

connectDeath()

RunService.RenderStepped:Connect(function()
	if humanoid.Health > 0 and humanoid.Health <= humanoid.MaxHealth * 0.4 then
		playPainSound()
	end
end)

player.CharacterAdded:Connect(function(newCharacter)
	character = newCharacter
	humanoid = character:WaitForChild("Humanoid")
	isDead = false
	painSoundInstance = nil
	deathSoundInstance = nil
	connectDeath()
end)
