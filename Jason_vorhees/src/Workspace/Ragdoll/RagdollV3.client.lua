repeat wait() until workspace.CurrentCamera ~= nil
wait(0.001)

local cleanUpTime = 60 -- tiempo razonable para limpieza

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

local function cleanupDescendants(parent)
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

local function RagdollV3()
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

	fhum.MaxHealth = 100
	fhum.Health = fhum.MaxHealth
end

char.Humanoid.Died:Connect(RagdollV3)
