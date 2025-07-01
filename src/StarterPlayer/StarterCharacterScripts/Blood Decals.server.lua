

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 92 then
		
		Instance.new("Decal", script.Parent["Left Leg"])
		script.Parent["Left Leg"].Decal.Texture = "rbxassetid://508050906"
		script.Parent["Left Leg"].Decal.Face = Region3int16
	end
end)

---------------------------------------------------------------------------

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 85 then
		
		Instance.new("Decal", script.Parent["Right Leg"])
		script.Parent["Right Leg"].Decal.Texture = "rbxassetid://508050982"
		script.Parent["Right Leg"].Decal.Face = Region3int16
	end
end)

----------------------------------------------------------------------------

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 73 then
		
		Instance.new("Decal", script.Parent["Left Arm"])
		script.Parent["Left Arm"].Decal.Texture = "rbxassetid://408754747"
		script.Parent["Left Arm"].Decal.Face = "Bottom"
	end
end)

-----------------------------------------------------------------------------

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 61 then
		
		Instance.new("Decal", script.Parent["Right Arm"])
		script.Parent["Right Arm"].Decal.Texture = "rbxassetid://508050982"
		script.Parent["Right Arm"].Decal.Face = "Right"
	end
end)

-----------------------------------------------------------------------------

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 49 then
		
		Instance.new("Decal", script.Parent.Torso)
		script.Parent.Torso.Decal.Texture = "rbxassetid://502143714"
		script.Parent.Torso.Decal.Face = Region3int16
	end
end)

-----------------------------------------------------------------------------

script.Parent.Humanoid.HealthChanged:Connect(function()
	if script.Parent.Humanoid.Health <= 37 then
		
		Instance.new("Decal", script.Parent.Head)
		script.Parent.Head.Decal.Texture = "rbxassetid://176678128"
		script.Parent.Head.Decal.Face = "Front"
	end
end)

------------------------------------------------------------------------------