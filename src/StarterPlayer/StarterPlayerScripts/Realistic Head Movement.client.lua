--[[
	Originally written by TsarMac
	Modified by foodman54
	Rewritten (:soulless:) by GizmoTjaz
	Modificado para desactivar el movimiento de cabeza en primera persona y hacerlo más fluido.
	Ahora también se desactiva si el personaje muere, y se puede controlar con headMovementEnabled (0 = activado, >0 = desactivado).
]]

-- Services
local runService = game:GetService("RunService")
local playerService = game:GetService("Players")

-- Variables de control
local headHorFactor = 1
local headVerFactor = .6
local bodyHorFactor = .5
local bodyVerFactor = .4
local updateSpeed = 0.15 -- Más fluido (antes era .25)

local plr = playerService.LocalPlayer
local cam = workspace.CurrentCamera

-- Control manual: 0 = activado, >0 = desactivado
local headMovementEnabled = 0

-- Función para cambiar el estado manualmente (puedes exponer esto si quieres cambiarlo desde otro script)
local function SetHeadMovementEnabled(val)
	headMovementEnabled = val
end

-- Variables de personaje
local char = plr.Character or plr.CharacterAdded:Wait()
local hum = char:WaitForChild("Humanoid")
local isR6 = hum.RigType == Enum.HumanoidRigType.R6
local head = char:FindFirstChild("Head")
local root = char:FindFirstChild("HumanoidRootPart")
local torso = isR6 and char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
local neck = isR6 and (torso and torso:FindFirstChild("Neck")) or (head and head:FindFirstChild("Neck"))
local waist = (not isR6) and (torso and torso:FindFirstChild("Waist"))

local neckC0 = neck and neck.C0
local waistC0 = waist and waist.C0

if neck then
	neck.MaxVelocity = 1/3
end

local inFirstPerson = false
local lastFirstPerson = false
local isAlive = true

-- Función para restaurar C0 original
local function restoreC0()
	if neck and neckC0 then neck.C0 = neckC0 end
	if waist and waistC0 then waist.C0 = waistC0 end
end

-- Función para actualizar referencias al respawnear
local function updateCharacterReferences()
	char = plr.Character or plr.CharacterAdded:Wait()
	hum = char:WaitForChild("Humanoid")
	isR6 = hum.RigType == Enum.HumanoidRigType.R6
	head = char:FindFirstChild("Head")
	root = char:FindFirstChild("HumanoidRootPart")
	torso = isR6 and char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
	neck = isR6 and (torso and torso:FindFirstChild("Neck")) or (head and head:FindFirstChild("Neck"))
	waist = (not isR6) and (torso and torso:FindFirstChild("Waist"))
	neckC0 = neck and neck.C0
	waistC0 = waist and waist.C0
	if neck then
		neck.MaxVelocity = 1/3
	end
end

-- Detectar muerte y respawn
hum.Died:Connect(function()
	isAlive = false
	restoreC0()
end)

plr.CharacterAdded:Connect(function()
	updateCharacterReferences()
	isAlive = true
end)

runService.RenderStepped:Connect(function ()
	if not (torso and head and neck and cam and hum) then return end

	-- Detectar si está en primera persona (la cámara está muy cerca de la cabeza)
	local camToHeadDist = (cam.CFrame.Position - head.Position).Magnitude
	inFirstPerson = camToHeadDist < 1

	-- Solo aplicar movimiento de cabeza si:
	-- - Está vivo
	-- - Está en tercera persona
	-- - headMovementEnabled == 0
	if isAlive and not inFirstPerson and headMovementEnabled == 0 then
		local camCF = cam.CFrame
		local headCF = head.CFrame
		local torsoLV = torso.CFrame.LookVector

		local dist = (headCF.Position - camCF.Position).Magnitude
		local diff = headCF.Y - camCF.Y

		-- Evitar división por cero
		if dist > 0 then
			local asinDiffDist = math.asin(diff / dist)
			local whateverThisDoes = ((headCF.Position - camCF.Position).Unit:Cross(torsoLV)).Y

			if isR6 then
				neck.C0 = neck.C0:Lerp(neckC0 * CFrame.Angles(-1 * asinDiffDist * headVerFactor, 0, -1 * whateverThisDoes * headHorFactor), updateSpeed)
			else
				neck.C0 = neck.C0:Lerp(neckC0 * CFrame.Angles(asinDiffDist * headVerFactor, -1 * whateverThisDoes * headHorFactor, 0), updateSpeed)
				if waist and waistC0 then
					waist.C0 = waist.C0:Lerp(waistC0 * CFrame.Angles(asinDiffDist * bodyVerFactor, -1 * whateverThisDoes * bodyHorFactor, 0), updateSpeed)
				end
			end
		end
	else
		-- Si está en primera persona, muerto, o desactivado manualmente, restaurar el C0 original (mirar al frente)
		if neckC0 then neck.C0 = neckC0 end
		if waist and waistC0 then waist.C0 = waistC0 end
	end

	lastFirstPerson = inFirstPerson
end)

-- Exponer la función para cambiar el estado desde otros scripts si se requiere
_G.SetHeadMovementEnabled = SetHeadMovementEnabled

