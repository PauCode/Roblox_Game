-- << VARIABLES >>
local music_list = {108600815235138,108600815235138}
local volume = 0

-- << CONSTANTS & SETUP >>
local rs = game:GetService("ReplicatedStorage")
local pos = math.random(1,#music_list)
local sound = Instance.new("Sound",workspace)
sound.Volume = volume

-- << MAIN >>
while true do	
	sound.SoundId = "rbxassetid://"..music_list[pos]
	pos = pos + 1
	sound:Play()
	sound.Ended:Wait()
	if pos > #music_list then
		pos = 1
	end
end

-- ~ForeverHD
		