local OrigCF = script.Parent.CFrame
while true do
	while true do
		wait()
		for i = 1,1000 do
			script.Parent.CFrame = script.Parent.CFrame + Vector3.new(0,0,5)	--car goes forward
			wait()
		end

		script.Parent.CFrame = OrigCF
		
	end
end