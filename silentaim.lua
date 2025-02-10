-- Silent Aim Script for Trident Survival v5

-- Get the players character
local player = game.player

-- Function to check if the player can shoot
local function canShoot()
    if player and player.character and player.character.humanoid and player.character.humanoid.equipped and player.character.humanoid.equipped枪:FindFirstChild("shooting") then
        if player.character.humanoid:FindFirstChild("looking") then
            return true
        end
    end
    return false
end

-- Silent Aim Function
local function silentAim(target, range)
    if canShoot() then
        -- Check if the character is looking at the target
        if target:IsA("BasePart") then
            local normal = (target.Position - player.Character.HumanoidRootPart.Position).Unit
            local direction = (target.Position - player.Character.HumanoidRootPart.Position)
            local dot = (normal * direction).Magnitude / direction.Magnitude
            local aimData = player.Character.HumanoidRootPart.CFrame.LookAt(target.Position)
            local aimVelocity = aimData.LookVector
            local dot2 = (normal * aimVelocity).Magnitude
            if dot2 > dot * 0.8 then
                -- Shoot at the center of the target
                player.Character.Humanoid:Shoot()
                return true, target
            end
        end
    end
    return false
end

-- Usage
game:GetService("StarterPlayer").LocalPlayer.TriggerEvent("silentAim", function(t, r)
    if silentAim(t, r) then
        warn("Silent Aim used!")
    end
end)
-- Key Bindings
function players(key, func)
    if key == "q" then
        func("silentAim", {"player","target","range"})
    end
end
