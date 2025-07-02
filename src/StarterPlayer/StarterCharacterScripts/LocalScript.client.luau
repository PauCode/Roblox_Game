-- SpawnEffect.lua
-- Efecto "Jason": pantalla negra, sonido "ch ch ch ah ah ah" y fondo blur
-- Coloca este script en StarterPlayerScripts o StarterCharacterScripts

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local SoundService = game:GetService("SoundService")
local Lighting = game:GetService("Lighting")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Crear pantalla negra (ScreenGui + Frame)
local gui = Instance.new("ScreenGui")
local black = Instance.new("Frame")
black.BackgroundColor3 = Color3.new(0,0,0)
black.Size = UDim2.new(1,0,1,0)
black.Position = UDim2.new(0,0,0,0)
black.BorderSizePixel = 0
black.BackgroundTransparency = 0
black.Parent = gui
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.Name = "SpawnBlackout"
gui.Parent = playerGui

-- Blur de fondo
local blur = Instance.new("BlurEffect")
blur.Size = 24
blur.Parent = Lighting

-- Sonido "ch ch ch ah ah ah" (pon el assetId correcto)
local sound = Instance.new("Sound")
sound.SoundId = "rbxassetid://4503031546" -- Cambiado al assetId proporcionado
sound.Volume = 1
sound.Parent = SoundService

local function openEyes()
	wait(0.5)
	sound:Play()
	wait(5.5) -- Mantén la pantalla negra y el blur mientras suena el efecto
	TweenService:Create(black, TweenInfo.new(2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {BackgroundTransparency = 1}):Play()
	TweenService:Create(blur, TweenInfo.new(2), {Size = 0}):Play()
	wait(2.2)
	gui:Destroy()
	sound:Destroy()
	blur:Destroy()
end

openEyes()
