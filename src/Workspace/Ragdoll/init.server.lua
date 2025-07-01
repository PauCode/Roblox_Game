game.Players.PlayerAdded:connect(function(player)
	player.CharacterAdded:connect(function(character)
		local ragdollV3 = script.RagdollV3:Clone()
		ragdollV3.Parent = character
		ragdollV3.Disabled = false
	end)
end)