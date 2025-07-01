repeat wait() until workspace.CurrentCamera ~= nil
wait(0.001)

local cleanUpTime = 60
local FALL_HEIGHT_TRIGGER = 10

local painSounds = {
    "rbxassetid://101433568913389",
}
local deathSounds = {
    "rbxassetid://87080612196118",
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

local camera = workspace.CurrentCamera
local char = script.Parent
local humanoid = char:FindFirstChildOfClass("Humanoid")
local rootPart = char:FindFirstChild("HumanoidRootPart")

local painPlayed = false
local isDead = false
local isRagdoll = false
local maxY = rootPart and rootPart.Position.Y or 0

-- Asegura colisión y masa real en brazos, piernas, pies y manos
local function enableLimbCollision()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            local n = part.Name:lower()
            if n:find("leg") or n:find("foot") or n:find("arm") or n:find("hand") then
                part.CanCollide = true
                part.Massless = false
                part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
            end
        end
    end
end

-- Simula pataleo y reflejos en el aire
local function applyReflexes()
    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") and (part.Name:lower():find("leg") or part.Name:lower():find("foot") or part.Name:lower():find("arm") or part.Name:lower():find("hand")) then
            local bv = Instance.new("BodyAngularVelocity")
            bv.AngularVelocity = Vector3.new(math.random(-15,15), math.random(-15,15), math.random(-15,15))
            bv.MaxTorque = Vector3.new(1e5,1e5,1e5)
            bv.P = 20000
            bv.Parent = part
            game:GetService("Debris"):AddItem(bv, 0.7)
        end
    end
end

-- Animación de tambaleo
local function playStumbleAnimation()
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if animator then
        local stumbleAnim = Instance.new("Animation")
        stumbleAnim.AnimationId = "rbxassetid://ID_ANIMACION_TAMBALEO" -- PON TU ID DE ANIMACIÓN
        local track = animator:LoadAnimation(stumbleAnim)
        track:Play()
        return track
    end
end

-- GTA IV style ragdoll: desactiva Motor6D y crea BallSocketConstraints
local function makeRagdollGTA4()
    if isRagdoll then return end
    isRagdoll = true

    enableLimbCollision()

    for _, desc in ipairs(char:GetDescendants()) do
        if desc:IsA("Motor6D") then
            local part0 = desc.Part0
            local part1 = desc.Part1
            local c0 = desc.C0
            local c1 = desc.C1
            local parent = desc.Parent
            desc.Enabled = false
            desc:Destroy()

            if part0 and part1 then
                local att0 = Instance.new("Attachment")
                att0.CFrame = c0
                att0.Name = "RagdollAttachment0"
                att0.Parent = part0

                local att1 = Instance.new("Attachment")
                att1.CFrame = c1
                att1.Name = "RagdollAttachment1"
                att1.Parent = part1

                local socket = Instance.new("BallSocketConstraint")
                socket.Attachment0 = att0
                socket.Attachment1 = att1
                socket.Parent = parent
                socket.LimitsEnabled = true
                socket.TwistLimitsEnabled = true
                socket.UpperAngle = 45
                socket.TwistLowerAngle = -45
                socket.TwistUpperAngle = 45
            end
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            part.Anchored = false
            if part.Name:lower():find("leg") or part.Name:lower():find("foot") or part.Name:lower():find("arm") or part.Name:lower():find("hand") then
                part.CanCollide = true
                part.Massless = false
                part.CustomPhysicalProperties = PhysicalProperties.new(1, 0.3, 0.5)
            else
                part.CanCollide = true
                part.Massless = false
            end
        end
    end

    humanoid.PlatformStand = true

    local head = char:FindFirstChild("Head")
    if head then
        camera.CameraSubject = head
    end

    local soundPart = char:FindFirstChild("Head") or char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChildWhichIsA("BasePart")
    playRandomSound(deathSounds, soundPart)

    if humanoid.FloorMaterial == Enum.Material.Air then
        applyReflexes()
    end
end

-- Cálculo de daño por caída realista
local function calculateFallDamage(velocity, hitPart, material)
    local baseDamage = math.abs(velocity) * 0.5
    if material == Enum.Material.Grass or material == Enum.Material.Fabric then
        baseDamage = baseDamage * 0.6
    end
    if hitPart and (hitPart.Name:lower():find("head") or hitPart.Name:lower():find("torso")) then
        baseDamage = baseDamage * 1.2
    end
    return math.floor(baseDamage)
end

-- Lógica de impacto al caer
local function onFallImpact(velocity, hitPart, material)
    local damage = calculateFallDamage(velocity, hitPart, material)
    if damage < 15 then
        playStumbleAnimation()
    elseif damage < 40 then
        applyReflexes()
        makeRagdollGTA4()
        -- Aquí puedes programar que intente levantarse tras unos segundos
    else
        applyReflexes()
        makeRagdollGTA4()
        humanoid.Health = humanoid.Health - damage
        -- Aquí puedes dejarlo inmóvil o con convulsiones (más BodyMovers)
    end
end

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

-- Detecta impacto con el suelo y calcula daño/reacción
rootPart.Touched:Connect(function(hit)
    if isRagdoll then return end
    if humanoid.FloorMaterial ~= Enum.Material.Air then
        local velocity = rootPart.Velocity.Y
        local material = hit.Material or Enum.Material.Plastic
        onFallImpact(velocity, hit, material)
    end
end)

humanoid.Died:Connect(function()
    isDead = true
    makeRagdollGTA4()
end)

char.AncestryChanged:Connect(function()
    if not char:IsDescendantOf(workspace) then
        isDead = false
        isRagdoll = false
    end
end)