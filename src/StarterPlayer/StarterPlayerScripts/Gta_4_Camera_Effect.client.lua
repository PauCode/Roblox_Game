-- gta4fov: FOV dinámico estilo GTA IV para Roblox, con tilt lateral y hook para vignette
-- Coloca este LocalScript en StarterCharacterScripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local hrp = character:WaitForChild("HumanoidRootPart")

-- FOV dinámico estilo GTA IV
local BASE_FOV = 70
local MAX_FOV = 90
local FOV_LERP_SPEED = 0.15
local lastFov = BASE_FOV

-- Tilt lateral
local MAX_TILT = math.rad(8) -- máximo 8 grados de inclinación
local TILT_LERP_SPEED = 0.15
local lastTilt = 0

-- Vignette (si tienes un efecto de post-procesado llamado "GTA4Vignette" en Lighting)
local vignette = nil
if game:GetService("Lighting"):FindFirstChild("GTA4Vignette") then
	vignette = game:GetService("Lighting"):FindFirstChild("GTA4Vignette")
end

-- ColorCorrection (si tienes un efecto llamado "GTA4Color" en Lighting)
local colorCorrection = nil
if game:GetService("Lighting"):FindFirstChild("GTA4Color") then
	colorCorrection = game:GetService("Lighting"):FindFirstChild("GTA4Color")
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local camLook = cam.CFrame.LookVector
	local upAmount = camLook:Dot(Vector3.new(0,1,0)) -- 1 = arriba, 0 = horizontal, -1 = abajo
	-- FOV dinámico: zoom-in al mirar abajo
	local targetFov = BASE_FOV
	if upAmount > 0.4 then
		targetFov = BASE_FOV + (MAX_FOV - BASE_FOV) * ((upAmount - 0.4) / 0.6)
	elseif upAmount < -0.4 then
		targetFov = BASE_FOV - 7 * ((-upAmount - 0.4) / 0.6) -- hasta 7 menos al mirar abajo
	end
	if targetFov > MAX_FOV then targetFov = MAX_FOV end
	if targetFov < BASE_FOV - 7 then targetFov = BASE_FOV - 7 end
	lastFov = lastFov + (targetFov - lastFov) * (FOV_LERP_SPEED + dt)
	cam.FieldOfView = lastFov

	-- Tilt lateral según giro horizontal de la cámara respecto al personaje
	local charLook = hrp.CFrame.LookVector
	local camRight = cam.CFrame.RightVector
	local sideAmount = charLook:Dot(camRight) -- -1 = mirando izquierda, 1 = mirando derecha
	local targetTilt = sideAmount * MAX_TILT
	lastTilt = lastTilt + (targetTilt - lastTilt) * (TILT_LERP_SPEED + dt)
	cam.CFrame = cam.CFrame * CFrame.Angles(0, 0, lastTilt)

	-- Vignette: más fuerte al mirar arriba
	if vignette then
		if upAmount > 0.85 then
			vignette.Enabled = true
			vignette.Intensity = 0.6 -- más fuerte
		elseif upAmount > 0.4 then
			vignette.Enabled = true
			vignette.Intensity = 0.3 -- intermedio
		else
			vignette.Enabled = false
		end
	end

	-- Desaturación/color al mirar arriba
	if colorCorrection then
		if upAmount > 0.4 then
			colorCorrection.Saturation = -0.5 * ((upAmount - 0.4) / 0.6) -- hasta -0.5
			colorCorrection.TintColor = Color3.new(0.85,0.9,1)
		else
			colorCorrection.Saturation = 0
			colorCorrection.TintColor = Color3.new(1,1,1)
		end
	end
end)
