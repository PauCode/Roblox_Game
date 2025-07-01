
-- Backwards walk: Hold S to walk backwards while facing forwards
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local hrp = character:WaitForChild("HumanoidRootPart")

local backwardsActive = false
local leftActive = false
local rightActive = false

UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.S then
        -- Only activate if camera is looking forward (aligned with character's front)
        local cam = workspace.CurrentCamera
        local charLook = hrp.CFrame.LookVector
        local camLook = cam.CFrame.LookVector
        -- dot > 0.7 means camera is pointing mostly forward
        if charLook:Dot(camLook) > 0.7 then
            backwardsActive = true
            humanoid.AutoRotate = false
        end
    elseif input.KeyCode == Enum.KeyCode.A then
        leftActive = true
    elseif input.KeyCode == Enum.KeyCode.D then
        rightActive = true
    end
end)

UIS.InputEnded:Connect(function(input, gameProcessed)
    if input.KeyCode == Enum.KeyCode.S then
        backwardsActive = false
        humanoid.AutoRotate = true
    elseif input.KeyCode == Enum.KeyCode.A then
        leftActive = false
    elseif input.KeyCode == Enum.KeyCode.D then
        rightActive = false
    end
end)

RunService.RenderStepped:Connect(function()
    if backwardsActive then
        -- Calculate movement direction: backwards + left/right
        local moveDir = -hrp.CFrame.LookVector
        if leftActive then
            moveDir = moveDir - hrp.CFrame.RightVector
        end
        if rightActive then
            moveDir = moveDir + hrp.CFrame.RightVector
        end
        if moveDir.Magnitude > 0 then
            moveDir = moveDir.Unit
        end
        local speed = humanoid.WalkSpeed * 0.65
        humanoid:Move(moveDir * speed / humanoid.WalkSpeed, false)
    end
end)