-- Simple ledge detection script for Roblox

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
local runService = game:GetService("RunService")

-- Update references on respawn
player.CharacterAdded:Connect(function(newChar)
	char = newChar
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
end)

-- Detection parameters
local FORWARD_DISTANCE = 3      -- How far ahead to check for a wall
local MAX_LEDGE_HEIGHT = 7      -- Max height of a ledge you can jump over (studs)
local LEDGE_CLEARANCE = 0       -- How much empty space is needed above the ledge


local lastDetectionTime = 0
local DETECTION_COOLDOWN = 0.5 -- seconds

local function detectLedge()
	if not humanoidRootPart or not humanoidRootPart.Parent then
		-- Try to reacquire if possible
		humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart or not humanoidRootPart.Parent then
			return false
		end
	end
	local rootPos = humanoidRootPart.Position
	local lookVector = humanoidRootPart.CFrame.LookVector

	-- Get character height (estimate from HumanoidRootPart size or default to 5)
	local charHeight = humanoidRootPart.Size and humanoidRootPart.Size.Y or 5
	local maxLedgeHeight = MAX_LEDGE_HEIGHT
	-- Only check if cooldown has passed
	if tick() - lastDetectionTime < DETECTION_COOLDOWN then
		return false
	end

	-- Cast forward to find a wall (start at fixed height 2 studs above ground)
	local wallOrigin = Vector3.new(rootPos.X, 2, rootPos.Z)
	local wallDirection = lookVector * FORWARD_DISTANCE
	print(string.format("[LedgeDetection] Ray origin: (%.2f, %.2f, %.2f) direction: (%.2f, %.2f, %.2f)", wallOrigin.X, wallOrigin.Y, wallOrigin.Z, wallDirection.X, wallDirection.Y, wallDirection.Z))
	local wallRay = Ray.new(wallOrigin, wallDirection)
	local wallHit, wallPos, wallNormal = workspace:FindPartOnRay(wallRay, char, false, true)
	print("[LedgeDetection] wallHit (leg):", wallHit, wallHit and wallHit.Name or "nil", wallPos)
	-- If no hit, try a ray at player's feet
	if not wallHit then
		local footOrigin = Vector3.new(rootPos.X, 0.1, rootPos.Z)
		local footRay = Ray.new(footOrigin, wallDirection)
		local footHit, footPos, footNormal = workspace:FindPartOnRay(footRay, char, false, true)
		print("[LedgeDetection] footHit:", footHit, footHit and footHit.Name or "nil", footPos)
		if footHit then
			wallHit, wallPos, wallNormal = footHit, footPos, footNormal
		end
	end

	if wallHit then
		print("[LedgeDetection] Jumping! wallHit:", wallHit, wallHit and wallHit.Name or "nil", wallPos)
		lastDetectionTime = tick()
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			local state = humanoid:GetState()
			print("[LedgeDetection] Humanoid state:", state.Name)
			if state ~= Enum.HumanoidStateType.Jumping
				and state ~= Enum.HumanoidStateType.PlatformStand
				and state ~= Enum.HumanoidStateType.Seated
				and state ~= Enum.HumanoidStateType.Dead then
				print("[LedgeDetection] Sending jump command!")
				humanoid.Jump = true
				-- Prevent repeated jump spamming by adding a short delay
				wait(0.1)
				humanoid.Jump = false
			else
				print("[LedgeDetection] Jump blocked by state:", state.Name)
			end
		else
			print("[LedgeDetection] No humanoid found!")
		end
		return true, wallPos
	else
		print("[LedgeDetection] No wall detected by raycast.")
	end
	return false
end


-- Check for ledges every 1 second
local lastCheck = 0
runService.RenderStepped:Connect(function()
	if tick() - lastCheck >= 1 then
		lastCheck = tick()
		detectLedge()
	end
end)