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
local MAX_LEDGE_HEIGHT = 4      -- Max height of a ledge you can jump over (studs)
local LEDGE_CLEARANCE = 0       -- How much empty space is needed above the ledge


local lastDetectionTime = 0
local DETECTION_COOLDOWN = 0.5 -- seconds

-- Utility to create a "Hold G" prompt at a world position
local function createHoldGPrompt(worldPos)
    -- Remove any existing prompt
    if workspace:FindFirstChild("LedgeHoldPrompt") then
        workspace.LedgeHoldPrompt:Destroy()
    end
    local promptPart = Instance.new("Part")
    promptPart.Name = "LedgeHoldPrompt"
    promptPart.Anchored = true
    promptPart.CanCollide = false
    promptPart.Size = Vector3.new(2, 1, 2)
    promptPart.Position = worldPos + Vector3.new(0, 2, 0) -- float above ledge
    promptPart.Transparency = 1
    promptPart.Parent = workspace

    local billboard = Instance.new("BillboardGui")
    billboard.Name = "HoldGPromptGui"
    billboard.Adornee = promptPart
    billboard.Size = UDim2.new(0, 200, 0, 50)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = promptPart

    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.Text = "HAHA mofo, you found the ledge!"
    textLabel.TextColor3 = Color3.new(1, 1, 1)
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.Parent = billboard

    -- Optional: auto-remove after a few seconds
    delay(2, function()
        if promptPart and promptPart.Parent then
            promptPart:Destroy()
        end
    end)
end

local LEDGE_MIN_HEIGHT = 1 -- studs; ignore obstacles lower than this (e.g., carpets)

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

    -- Cast forward to find a wall (start at slightly higher than carpet, e.g. 1.1 studs above ground)
    local wallOrigin = Vector3.new(rootPos.X, LEDGE_MIN_HEIGHT + 0.1, rootPos.Z)
    local wallDirection = lookVector * FORWARD_DISTANCE
    print(string.format("[LedgeDetection] Ray origin: (%.2f, %.2f, %.2f) direction: (%.2f, %.2f, %.2f)", wallOrigin.X, wallOrigin.Y, wallOrigin.Z, wallDirection.X, wallDirection.Y, wallDirection.Z))
    local wallRay = Ray.new(wallOrigin, wallDirection)
    local wallHit, wallPos, wallNormal = workspace:FindPartOnRay(wallRay, char, false, true)
    print("[LedgeDetection] wallHit (min height):", wallHit, wallHit and wallHit.Name or "nil", wallPos)
    -- If no hit, try a ray at player's feet (for completeness, but will ignore carpets)
    if not wallHit then
        local footOrigin = Vector3.new(rootPos.X, 0.1, rootPos.Z)
        local footRay = Ray.new(footOrigin, wallDirection)
        local footHit, footPos, footNormal = workspace:FindPartOnRay(footRay, char, false, true)
        print("[LedgeDetection] footHit:", footHit, footHit and footHit.Name or "nil", footPos)
        -- Only treat as ledge if the hit is above the minimum height
        if footHit and footPos.Y >= LEDGE_MIN_HEIGHT then
            wallHit, wallPos, wallNormal = footHit, footPos, footNormal
        end
    end


    -- If a wall was hit, check that its height is within the ledge range (not too low, not too high)
    if wallHit and wallPos then
        -- Estimate the top of the obstacle by casting a ray down from above
        local topCheckOrigin = Vector3.new(wallPos.X, rootPos.Y + charHeight, wallPos.Z)
        local downRay = Ray.new(topCheckOrigin, Vector3.new(0, -charHeight * 2, 0))
        local topHit, topPos, topNormal = workspace:FindPartOnRay(downRay, char, false, true)
        local ledgeHeight = topHit and (topPos.Y - rootPos.Y) or (wallPos.Y - rootPos.Y)
        print(string.format("[LedgeDetection] ledgeHeight: %.2f (charHeight: %.2f)", ledgeHeight, charHeight))
        if ledgeHeight < charHeight * 0.1 or ledgeHeight > charHeight then
            print("[LedgeDetection] Obstacle not in ledge height range. Ignoring.")
            return false
        end
    end

    if wallHit then
        print("[LedgeDetection] Ledge found! Showing Hold G prompt. wallHit:", wallHit, wallHit and wallHit.Name or "nil", wallPos)
        createHoldGPrompt(wallPos)
        lastDetectionTime = tick()
        -- (Optional: keep jump logic if you want both prompt and auto-jump)
        -- local humanoid = char:FindFirstChildOfClass("Humanoid")
        -- if humanoid then
        --     local state = humanoid:GetState()
        --     if state ~= Enum.HumanoidStateType.Jumping
        --         and state ~= Enum.HumanoidStateType.PlatformStand
        --         and state ~= Enum.HumanoidStateType.Seated
        --         and state ~= Enum.HumanoidStateType.Dead then
        --         humanoid.Jump = true
        --         humanoid:Move(Vector3.new(0,0,0), true)
        --     end
        -- end
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