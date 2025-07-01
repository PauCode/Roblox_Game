repeat wait() until workspace.CurrentCamera ~= nil
wait(0.001)

local cleanUpTime = 60 -- tiempo razonable para limpieza

local painSounds = {
    "rbxassetid://101433568913389",
    -- agrega más sonidos si quieres
}
local deathSounds = {
    "rbxassetid://87080612196118",
    -- agrega más sonidos si quieres
}

local function playRandomSound(soundList, part)
    if #soundList == 0 or not part then return end
    local soundId = soundList[math.random(1, #soundList)]
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = 1
    s.Parent = part
    s:Play()
    s.Ended:Connect(function()
        s:Destroy()
    end)
end

local function NewHingePart()
    local B = Instance.new("Part")
    B.TopSurface = Enum.SurfaceType.Smooth
    B.BottomSurface = Enum.SurfaceType.Smooth
    B.Shape = Enum.PartType.Ball
    B.Size = Vector3.new(1, 1, 1)
    B.Transparency = 1
    B.CanCollide = true
    return B
end

local function CreateJoint(j_type, p0, p1, c0, c1)
    local nj = Instance.new(j_type)
    nj.Part0 = p0
    nj.Part1 = p1
    if c0 ~= nil then nj.C0 = c0 end
    if c1 ~= nil then nj.C1 = c1 end
    nj.Parent = p0
end

local AttachmentData = {
    ["RA"] = {"Right Arm", CFrame.new(0, 0.5, 0), CFrame.new(1.5, 0.5, 0)},
    ["LA"] = {"Left Arm", CFrame.new(0, 0.5, 0), CFrame.new(-1.5, 0.5, 0)},
    ["RL"] = {"Right Leg", CFrame.new(0, 0.5, 0), CFrame.new(0.5, -1.5, 0)},
    ["LL"] = {"Left Leg", CFrame.new(0, 0.5, 0), CFrame.new(-0.5, -1.5, 0)},
}

local collision_part = Instance.new("Part")
collision_part.Name = "CP"
collision_part.TopSurface = Enum.SurfaceType.Smooth
collision_part.BottomSurface = Enum.SurfaceType.Smooth
collision_part.Size = Vector3.new(1, 1.5, 1)
collision_part.Transparency = 1

local camera = workspace.CurrentCamera
local char = script.Parent
local humanoid = char:FindFirstChildOfClass("Humanoid")

local painPlayed = false
local isDead = false
local ragdolling = false

if humanoid then
    humanoid.HealthChanged:Connect(function(health)
        if isDead then return end
        local maxHealth = humanoid.MaxHealth
        if health <= maxHealth * 0.3 and health > 0 and not painPlayed then
            painPlayed = true
            local soundPart = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
            playRandomSound(painSounds, soundPart)
        elseif health > maxHealth * 0.3 then
            painPlayed = false
        end
    end)
end

function cleanupDescendants(parent)
    for _, obj in pairs(parent:GetChildren()) do
        cleanupDescendants(obj)
        if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("ForceField") or obj:IsA("ParticleEmitter") or
            ((obj:IsA("Weld") or obj:IsA("Motor6D")) and obj.Name ~= "AttachementWeld") then
            obj:Destroy()
        elseif obj:IsA("BasePart") then
            obj.Velocity = Vector3.new()
            obj.RotVelocity = Vector3.new()
            if obj.Parent:IsA("Accessory") then
                obj.CanCollide = false
            end
        end
    end
end

local function addBounceToRagdoll(ragdoll)
    for _, part in ipairs(ragdoll:GetDescendants()) do
        if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
            part.Touched:Connect(function(hit)
                if hit:IsA("BasePart") and hit.Anchored and math.abs(part.Velocity.Y) > 25 then
                    -- Rebote solo si el impacto es fuerte y con el suelo
                    part.Velocity = Vector3.new(part.Velocity.X, math.abs(part.Velocity.Y) * 0.35, part.Velocity.Z)
                end
            end)
        end
    end
end

local function RagdollV3()
    if isDead or ragdolling then return end
    isDead = true
    ragdolling = true
    char.Archivable = true
    local ragdoll = char:Clone()
    char.Archivable = false

    -- Limpia el personaje original excepto humanoide
    for _, obj in pairs(char:GetChildren()) do 
        if not obj:IsA("Humanoid") then
            obj:Destroy()
        end
    end

    cleanupDescendants(ragdoll)

    -- AJUSTE DE PESO Y REBOTE REALISTA EN EL RAGDOLL
    for _, part in ipairs(ragdoll:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Massless = false
            part.CustomPhysicalProperties = PhysicalProperties.new(
                2,    -- Density (peso humano)
                0.3,  -- Friction
                0.5,  -- Elasticity (rebote realista)
                1,    -- FrictionWeight
                1     -- ElasticityWeight
            )
        end
    end

    local fhum = ragdoll:FindFirstChild("Humanoid")
    fhum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
    fhum.PlatformStand = true
    fhum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
    fhum.Name = "RagdollHumanoid"

    local torso = ragdoll:FindFirstChild("Torso") or ragdoll:FindFirstChild("UpperTorso")
    if torso then
        torso.Velocity = Vector3.new(math.random(), 0.0000001, math.random()).Unit * 5 + Vector3.new(0, 0.15, 0)
        local head = ragdoll:FindFirstChild("Head")
        if head then
            camera.CameraSubject = head
            CreateJoint("Weld", torso, head, CFrame.new(0, 1.5, 0))
        end

        for att_tag, att_data in pairs(AttachmentData) do
            local limb = ragdoll:FindFirstChild(att_data[1])
            if limb then
                local att1 = Instance.new("Attachment")
                att1.Name = att_tag
                att1.CFrame = att_data[2]
                att1.Parent = limb

                local att2 = Instance.new("Attachment")
                att2.Name = att_tag
                att2.CFrame = att_data[3]
                att2.Parent = torso

                local socket = Instance.new("BallSocketConstraint")
                socket.Name = att_tag .. "_SOCKET"
                socket.Attachment0 = att2
                socket.Attachment1 = att1
                socket.Radius = 0
                socket.Parent = torso

                limb.CanCollide = false

                local cp = collision_part:Clone()
                local cp_weld = Instance.new("Weld")
                cp_weld.C0 = CFrame.new(0, -0.25, 0)
                cp_weld.Part0 = limb
                cp_weld.Part1 = cp
                cp_weld.Parent = cp
                cp.Parent = ragdoll
            end
        end
    end

    ragdoll.Parent = workspace
    game:GetService("Debris"):AddItem(ragdoll, cleanUpTime)

    -- Rebote visible y natural
    addBounceToRagdoll(ragdoll)

    -- Reproducir sonido de muerte en el ragdoll
    local ragdollPart = ragdoll:FindFirstChild("Head") or ragdoll:FindFirstChild("Torso") or ragdoll:FindFirstChild("UpperTorso") or ragdoll:FindFirstChildWhichIsA("BasePart")
    playRandomSound(deathSounds, ragdollPart)

    fhum.MaxHealth = 100
    fhum.Health = fhum.MaxHealth
end

char.Humanoid.Died:Connect(RagdollV3)

-- ACTIVADOR DE RAGDOLL POR CAÍDA

local rootPart = char:FindFirstChild("HumanoidRootPart")
local gravity = workspace.Gravity or 196.2
local function getJumpHeight()
    if humanoid then
        local jp = humanoid.UseJumpPower and humanoid.JumpPower or 50
        return (jp * jp) / (4 * gravity)
    end
    return 7.2
end

local function getFallHeightTrigger()
    return math.max(getJumpHeight() * 5, 30)
end

local fallStartY = nil
local wasFalling = false
local fallStartTime = nil
local MIN_FALL_TIME = 0.3 -- seconds in Freefall before we consider it a real fall

game:GetService("RunService").Heartbeat:Connect(function()
    if not rootPart or not humanoid or humanoid.Health <= 0 or isDead or ragdolling then return end

    local state = humanoid:GetState()
    local y = rootPart.Position.Y
    local now = tick()

    if state == Enum.HumanoidStateType.Climbing then
        -- Reset fall detection when climbing (e.g. on ladder)
        wasFalling = false
        fallStartY = nil
        fallStartTime = nil
    elseif state == Enum.HumanoidStateType.Freefall then
        if not wasFalling then
            -- Just started falling
            fallStartY = y
            fallStartTime = now
            wasFalling = true
        elseif y > fallStartY then
            -- If player goes up while falling (e.g. bounce), update start
            fallStartY = y
            fallStartTime = now
        end
    elseif wasFalling and humanoid.FloorMaterial ~= Enum.Material.Air then
        -- Landed after a fall
        local fallDistance = (fallStartY or y) - y
        local trigger = getFallHeightTrigger()
        local fallDuration = now - (fallStartTime or now)
        if fallDuration >= MIN_FALL_TIME and fallDistance >= trigger and state ~= Enum.HumanoidStateType.Climbing then
            RagdollV3()
        end
        wasFalling = false
        fallStartY = nil
        fallStartTime = nil
    elseif state ~= Enum.HumanoidStateType.Freefall then
        -- Reset if not falling
        wasFalling = false
        fallStartY = nil
        fallStartTime = nil
    end
end)

humanoid.Died:Connect(function()
    isDead = true
    ragdolling = false
end)
char.AncestryChanged:Connect(function()
    if not char:IsDescendantOf(workspace) then
        isDead = false
        ragdolling = false
    end
end)