local player = game.Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

function autoHit()
    while true do
        wait(0.1)  -- adjust as needed for performance
        for _, enemy in pairs(workspace:GetChildren()) do
            if enemy:IsA("Model") and enemy:FindFirstChild("Humanoid") then
                local distance = (character.HumanoidRootPart.Position - enemy.PrimaryPart.Position).magnitude
                if distance <= 10 then  -- set your hitting range
                    character.Humanoid:MoveTo(enemy.PrimaryPart.Position)
                    enemy.Humanoid:TakeDamage(10)  -- adjust damage as needed
                end
            end
        end
    end
end

autoHit()
