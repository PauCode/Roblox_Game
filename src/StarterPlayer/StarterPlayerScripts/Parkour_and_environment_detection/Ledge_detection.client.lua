-- Simple ledge detection script for Roblox


-- (VaultDeductStamina undo: removed all global vault stamina logic)

local player = game.Players.LocalPlayer
local char = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
local runService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

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
local activeLedgePos = nil -- Store the current ledge position for G key

local promptPart = nil
local promptBillboard = nil
local promptTextLabel = nil

local function destroyPrompt()
    if promptPart and promptPart.Parent then
        promptPart:Destroy()
    end
    promptPart = nil
    promptBillboard = nil
    promptTextLabel = nil
    activeLedgePos = nil
end

local function createHoldGPrompt(worldPos)
    -- Remove any existing prompt
    destroyPrompt()
    activeLedgePos = worldPos -- Set the active ledge position
    print("[LedgeDetection] activeLedgePos set:", activeLedgePos)
    promptPart = Instance.new("Part")
    promptPart.Name = "LedgeHoldPrompt"
    promptPart.Anchored = true
    promptPart.CanCollide = false
    promptPart.Size = Vector3.new(2, 1, 2)
    promptPart.Position = worldPos + Vector3.new(0, 2, 0) -- float above ledge
    promptPart.Transparency = 1
    promptPart.Parent = workspace

    promptBillboard = Instance.new("BillboardGui")
    promptBillboard.Name = "HoldGPromptGui"
    promptBillboard.Adornee = promptPart
    promptBillboard.Size = UDim2.new(0, 200, 0, 50)
    promptBillboard.StudsOffset = Vector3.new(0, 2, 0)
    promptBillboard.AlwaysOnTop = true
    promptBillboard.Parent = promptPart

    promptTextLabel = Instance.new("TextLabel")
    promptTextLabel.Size = UDim2.new(1, 0, 1, 0)
    promptTextLabel.BackgroundTransparency = 1
    promptTextLabel.Text = "Press G to vaulty :)"
    promptTextLabel.TextColor3 = Color3.new(1, 1, 1)
    promptTextLabel.TextStrokeTransparency = 0.5
    promptTextLabel.TextScaled = true
    promptTextLabel.Font = Enum.Font.GothamBold
    promptTextLabel.Parent = promptBillboard
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




runService.RenderStepped:Connect(function()
    local found, ledgePos = detectLedge()
    -- Hide or show prompt text based on player distance to ledge
    if promptPart and promptTextLabel and activeLedgePos then
        local charPos = humanoidRootPart and humanoidRootPart.Position or Vector3.new(0,0,0)
        local dist = (charPos - activeLedgePos).Magnitude
        if dist < 5 then
            promptTextLabel.Visible = true
        else
            promptTextLabel.Visible = false
        end
        -- If player is too far from ledge, destroy prompt
        if dist > 10 then
            print("[LedgeDetection] Player moved too far from ledge, destroying prompt.")
            destroyPrompt()
        end
    elseif promptPart and not activeLedgePos then
        -- Defensive: if prompt exists but no ledge, destroy
        destroyPrompt()
    end
end)

-- Move player to ledge when pressing G (if prompt is active)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    print("[LedgeDetection] InputBegan ANY:", input.KeyCode, "gameProcessed:", gameProcessed, "activeLedgePos:", activeLedgePos)
    if input.KeyCode == Enum.KeyCode.G then
        print("[LedgeDetection] G key pressed! (regardless of ledge)")
    end
    if input.KeyCode == Enum.KeyCode.G and activeLedgePos then
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid and humanoidRootPart then
            -- Deduct 5% stamina from Run meter if possible
            -- (VaultDeductStamina undo: removed vault stamina deduction call)
            end

            -- Play animation in reverse (replace assetId with your animation)
            local anim = Instance.new("Animation")
            anim.AnimationId = "rbxassetid://71691533756386" -- Example: Roblox jump animation, replace with your own
            local track = humanoid:LoadAnimation(anim)
            track:Play()
            -- Wait for animation to load so Length is available
            while track.Length == 0 do
                task.wait()
            end
            -- Set just before the end to ensure full reverse playback
            track.TimePosition = math.max(track.Length - 0.05, 0)
            track:AdjustSpeed(-1) -- Play in reverse

            print("[LedgeDetection] Applying upward momentum. activeLedgePos:", activeLedgePos)
            print("[LedgeDetection] HumanoidRootPart before:", humanoidRootPart.Position)
            -- Apply upward velocity for a vault/boost effect (faster acceleration)
            humanoidRootPart.Velocity = Vector3.new(humanoidRootPart.Velocity.X, 45, humanoidRootPart.Velocity.Z)
            print("[LedgeDetection] G pressed: Upward momentum applied!")
            print("[LedgeDetection] HumanoidRootPart after:", humanoidRootPart.Position)
            destroyPrompt() -- Clean up prompt after use
        else
            print("[LedgeDetection] Could not find humanoid or root part!")
        end
    end
end)