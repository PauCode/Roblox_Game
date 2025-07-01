local kill = script.Parent
local debounce = false
local waitTime = 1
local damage = 70 -- Edit this to modify damage to player

function onTouched(hit)
	
	if not debounce then
		debounce = true
		if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
			hit.Parent.Humanoid.Health = hit.Parent.Humanoid.Health - damage
			--print(hit.Parent.Humanoid.Health)
		end
		wait(waitTime)
		debounce = false	
	end	
end

kill.Touched:connect(onTouched)

