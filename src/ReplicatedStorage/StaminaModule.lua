-- StaminaModule.lua
-- Centralized stamina logic for all movement scripts

local StaminaModule = {}

local runStamina = 100
local panicStamina = 100

function StaminaModule.GetRunStamina()
	return runStamina
end

function StaminaModule.SetRunStamina(val)
	runStamina = math.clamp(val, 0, 100)
end

function StaminaModule.DeductRunStamina(percent)
	if type(percent) ~= "number" then return end
	local amount = math.clamp(percent, 0, 100)
	runStamina = math.max(0, runStamina - amount)
	print("[StaminaModule] Deducted", amount, "runStamina now:", runStamina)
end

function StaminaModule.GetPanicStamina()
	return panicStamina
end

function StaminaModule.SetPanicStamina(val)
	panicStamina = math.clamp(val, 0, 100)
end

function StaminaModule.DeductPanicStamina(amount)
	if type(amount) ~= "number" then return end
	panicStamina = math.max(0, panicStamina - amount)
	print("[StaminaModule] Deducted", amount, "panicStamina now:", panicStamina)
end

return StaminaModule
