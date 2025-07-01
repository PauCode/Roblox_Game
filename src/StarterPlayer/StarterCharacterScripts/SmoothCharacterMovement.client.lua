--- CONFIGURATIONS ---
-- (Everything is in degrees)
local TorsoXRotation = 8 -- (When the character moves sideways)
local TorsoZRotation = 6 -- (When the character moves to the front)
local LegRotation = 3.5 -- (Affects both)

-- Dont touch anything unless you know what you're doing

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = script.Parent
local Humanoid = Character:WaitForChild("Humanoid")

local HumanoidRootPart = Character.HumanoidRootPart
local Torso = Character.Torso

local RootJoint = HumanoidRootPart.RootJoint
local LeftHipJoint = Torso["Left Hip"]
local RightHipJoint = Torso["Right Hip"]

local function Lerp(a, b, c)
	return a + (b - a) * c
end

local Force = nil
local Direction = nil
local Value1 = 0
local Value2 = 0

local RootJointC0 = RootJoint.C0
local LeftHipJointC0 = LeftHipJoint.C0
local RightHipJointC0 = RightHipJoint.C0

RunService.RenderStepped:Connect(function()
	--> To get the force, we multiply the velocity by 1,0,1, we don't want the Y value so we set y to 0
	Force = HumanoidRootPart.Velocity * Vector3.new(1,0,1)
	if Force.Magnitude > 0.001 then
		--> This represents the direction
		Direction = Force.Unit
		Value1 = HumanoidRootPart.CFrame.RightVector:Dot(Direction)
		Value2 = HumanoidRootPart.CFrame.LookVector:Dot(Direction)
	else
		Value1 = 0
		Value2 = 0
	end

	--> the values being multiplied are how much you want to rotate by

	RootJoint.C0 = RootJoint.C0:Lerp(RootJointC0 * CFrame.Angles(math.rad(Value2 * TorsoZRotation), math.rad(-Value1 * TorsoXRotation), 0), 0.2)
	LeftHipJoint.C0 = LeftHipJoint.C0:Lerp(LeftHipJointC0 * CFrame.Angles(math.rad(Value1 * LegRotation), 0, 0), 0.2)
	RightHipJoint.C0 = RightHipJoint.C0:Lerp(RightHipJointC0 * CFrame.Angles(math.rad(-Value1 * LegRotation), 0, 0), 0.2)
end)