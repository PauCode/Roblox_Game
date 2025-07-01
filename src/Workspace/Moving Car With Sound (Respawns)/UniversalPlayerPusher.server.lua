--[[
    Universal Player Pusher Script
    Attach this script to any Model or Part to push players away when touched.
    Example: Attach to "Moving Car With Sound (Respawns)" or any other object.
--]]

local function onTouched(hit, selfPart)
    local character = hit.Parent
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if humanoid and root then
        -- Calculate push direction: from the object to the player
        local pushOrigin = selfPart.Position
        local pushTarget = root.Position
        local direction = (pushTarget - pushOrigin).Unit
        -- Push strength (tweak as needed)
        local pushForce = 120
        -- Set velocity
        root.AssemblyLinearVelocity = direction * pushForce + Vector3.new(0, 10, 0) -- upward nudge
    end
end

local function bindToPart(part)
    part.Touched:Connect(function(hit)
        onTouched(hit, part)
    end)
end

local parent = script.Parent
if parent:IsA("BasePart") then
    bindToPart(parent)
elseif parent:IsA("Model") then
    -- Bind to all descendant parts
    for _, descendant in parent:GetDescendants() do
        if descendant:IsA("BasePart") then
            bindToPart(descendant)
        end
    end
end

