local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")

-- Panic Run settings
local PANIC_RUN_COOLDOWN = 10 -- seconds
local isReady = true

-- Sound setup (con el nuevo SoundId solicitado)
local readySound = Instance.new("Sound")
readySound.SoundId = "rbxassetid://1843616846"
readySound.Volume = 1

-- Función para reproducir el sonido de recarga
local function playReadySound()
    SoundService:PlayLocalSound(readySound)
end

-- Función para activar el Panic Run
local function activatePanicRun()
    if not isReady then return end
    isReady = false
    -- [Aquí va la lógica de la habilidad: aumentar velocidad, efectos, etc.]
    -- Iniciar cooldown
    task.spawn(function()
        task.wait(PANIC_RUN_COOLDOWN)
        isReady = true
        playReadySound()
        -- [Opcional: Notificar a la UI o jugador que la habilidad está lista]
    end)
end

-- Ejemplo: activar Panic Run al presionar "F"
UIS.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.KeyCode == Enum.KeyCode.F then
        activatePanicRun()
    end
end)

