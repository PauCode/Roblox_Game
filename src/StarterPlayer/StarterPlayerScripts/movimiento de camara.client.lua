local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Player = game:GetService("Players").LocalPlayer

-- Crear BlurEffect si no existe
local blur = Lighting:FindFirstChildOfClass("BlurEffect")
if not blur then
	blur = Instance.new("BlurEffect")
	blur.Size = 0
	blur.Parent = Lighting
end

-- Crear sonido distorsión
local distortionSound = Instance.new("Sound")
distortionSound.SoundId = "rbxassetid://136224586361044" -- Cambia por tu sonido
distortionSound.Looped = true
distortionSound.Volume = 0
distortionSound.Parent = Player:WaitForChild("PlayerGui")

local lastCameraCFrame = workspace.CurrentCamera.CFrame

-- Máximo blur y volumen que queremos alcanzar
local maxBlur = 24
local maxVolume = 0.3

-- Umbral mínimo para empezar a aplicar efectos (grados)
local minRotationThreshold = 1 

RunService.RenderStepped:Connect(function()
	local camera = workspace.CurrentCamera
	local currentCFrame = camera.CFrame

	-- Calculamos diferencia de rotación entre el frame anterior y el actual
	local deltaCFrame = lastCameraCFrame:ToObjectSpace(currentCFrame)
	lastCameraCFrame = currentCFrame

	-- Obtenemos rotación en X, Y, Z en radianes
	local x, y, z = deltaCFrame:ToEulerAnglesXYZ()
	local rotationSpeed = math.deg(math.abs(x) + math.abs(y) + math.abs(z))

	if rotationSpeed > minRotationThreshold then
		-- Calculamos proporción entre 0 y 1 (clamp para no pasar de 1)
		local t = math.clamp((rotationSpeed - minRotationThreshold) / (10 - minRotationThreshold), 0, 1)
		blur.Size = t * maxBlur
		distortionSound.Volume = t * maxVolume
		if not distortionSound.IsPlaying then
			distortionSound:Play()
		end
	else
		blur.Size = 0
		distortionSound.Volume = 0
		if distortionSound.IsPlaying then
			distortionSound:Stop()
		end
	end
end)

