--[[
Este script controla los sonidos de respiración según la velocidad del personaje:
- Velocidad entre 0 y 16: respiración normal
- Velocidad mayor a 16 y hasta 40: respiración de correr
Coloca este script en StarterCharacterScripts.
--]]

local RunService = game:GetService("RunService")
local player = game.Players.LocalPlayer
local character = script.Parent
local humanoid = character:FindFirstChildOfClass("Humanoid")
local head = character:FindFirstChild("Head")

local breathSounds = {
	normal = "rbxassetid://360202811",
	run = "rbxassetid://180315285"
}

local currentState = nil

local function playBreathSound(state)
	if not head then return end
	-- Elimina el sonido anterior si existe
	local existing = head:FindFirstChild("Breathing")
	if existing then existing:Destroy() end

	local sound = Instance.new("Sound")
	sound.Name = "Breathing"
	sound.Looped = true
	sound.Volume = 0.7
	sound.RollOffMode = Enum.RollOffMode.Linear
	sound.EmitterSize = 2
	sound.MaxDistance = 15
	sound.SoundId = breathSounds[state] or breathSounds.normal
	sound.Parent = head
	sound:Play()
end

local function updateBreath()
	if not humanoid then return end
	local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed

	if speed <= 16 then
		if currentState ~= "normal" then
			currentState = "normal"
			playBreathSound("normal")
		end
	elseif speed > 16 and speed <= 40 then
		if currentState ~= "run" then
			currentState = "run"
			playBreathSound("run")
		end
	elseif speed > 40 then
		if currentState ~= "run" then
			currentState = "run"
			playBreathSound("run")
		end
	end
end

-- Actualiza el sonido cada frame para detectar cambios de velocidad
RunService.Heartbeat:Connect(function()
	updateBreath()
end)

-- Al iniciar, espera a que todo esté listo y reproduce el sonido correcto
task.wait(1)
updateBreath()

