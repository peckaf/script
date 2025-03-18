local getupval = debug.getupvalue or getupvalue
local getupvals = debug.getupvalues or getupvalues
local getreg = debug.getregistry or getregistry
local setupval = debug.setupvalue or setupvalue
local getlocalval = debug.getlocal or getlocal
local getlocalvals = debug.getlocals or getlocals
local setlocalval = debug.setlocal or setlocal
local getmetat = getrawmetatable
local setreadonly1 = make_writeable or setreadonly
local copy = setclipboard or clipboard.set or copystring
local Workspace = cloneref(game:GetService("Workspace"))
local RunService = cloneref(game:GetService("RunService"))
local Camera = Workspace.CurrentCamera

local fov_circle_outer = Drawing.new("Circle")
fov_circle_outer.Visible = true
fov_circle_outer.Thickness = 3
fov_circle_outer.Color = Color3.fromRGB(0, 0, 0)
fov_circle_outer.Position = Camera.ViewportSize / 2
fov_circle_outer.Radius = 121

local fov_circle_inner = Drawing.new("Circle")
fov_circle_inner.Visible = true
fov_circle_inner.Thickness = 1
fov_circle_inner.Color = Color3.fromRGB(255, 255, 255)
fov_circle_inner.Position = Camera.ViewportSize / 2
fov_circle_inner.Radius = 120

local snap_line_outer = Drawing.new("Line")
snap_line_outer.Visible = false
snap_line_outer.Color = Color3.fromRGB(0, 0, 0)
snap_line_outer.Thickness = 3

local snap_line_inner = Drawing.new("Line")
snap_line_inner.Visible = false
snap_line_inner.Color = Color3.fromRGB(255, 255, 255)
snap_line_inner.Thickness = 1

local Classes = getrenv()._G.classes
local EntityMap, loaded = {}, false

task.spawn(function()
    while task.wait() do 
        loaded = true
        EntityMap = table.clone(Classes.EntityClient.EntityMap)
    end
end)

while not loaded do
   task.wait() 
end


local l
l = hookmetamethod(game, "__index", newcclosure(function(Self, Index)
    
    if tostring(Self) == "Neck" and Self.Parent and tostring(Self.Parent) == "Head" and Index == "Enabled" then
        return true
    end

    return l(Self, Index)
end))


local Settings = {
    ["Combat"] = {
        ["Aimbot"] = {
            ["Enabled"]    = false,
            ["Mode"]       = "None",
            ["Target"]     = "None",
            ["Enabled2"]   = false,
            ["Fov Size"]   = 120,
            ["Resover"]    = false,
        }
        
    },
}

function to_viewport(pos)
    if typeof(pos) ~= "Vector3" then return Vector2.zero, false end
    local point, on = Camera:WorldToViewportPoint(pos)
    return Vector2.new(point.X, point.Y), on
end

local target = nil

function GetClosestTarget(maxDistance)
    
    local closestTarget, targetVelocity, closestDistance = nil, nil, math.huge;
    local viewportCenter = Camera.ViewportSize / 2
    for i, v in pairs(EntityMap) do
        if (v.type == "Player" or v.type == "Soldier" or v.type == "Guoul" or v.type == "Officer" or v.type == "General" ) and v.model:FindFirstChild("HumanoidRootPart") and not (#((v.model:FindFirstChild("AnimationController") and v.model.AnimationController.Animator:GetPlayingAnimationTracks()) or {}) > 0 and v.model.AnimationController.Animator:GetPlayingAnimationTracks()[1].Animation.AnimationId == "rbxassetid://13280887764") then  

            local distanceToPlayer = (v.model.HumanoidRootPart.Position - Camera.CFrame.Position).Magnitude;

            if (distanceToPlayer <= maxDistance) then
                local screenPoint, onScreen = Camera:WorldToViewportPoint(v.model.Head.Position);

                if (onScreen) then
                    local distanceFromCenter = (Vector2.new(screenPoint.X, screenPoint.Y) - viewportCenter).Magnitude;

                    if (distanceFromCenter < closestDistance and distanceFromCenter < fov_circle_inner.Radius) then
                        closestTarget = v
                        targetVelocity = v.velocityVector;
                        closestDistance = distanceFromCenter;
                    end
                end
            end
        end
    end
    return closestTarget
end



RunService.Heartbeat:Connect(function()
    target = GetClosestTarget(1200)
    fov_circle_inner.Radius = Settings["Combat"]["Aimbot"]["Fov Size"] * (math.tan(math.rad(70)) / math.tan(math.rad(Camera.FieldOfView))) ^ 0.8;
    fov_circle_outer.Radius = fov_circle_inner.Radius + 1 
    if target and target.model and target.model:FindFirstChild("Head") then
        local targetHeadPosition = target.model.Head.Position
        local targetScreenPosition, onScreen = to_viewport(targetHeadPosition)
        
        if onScreen then
            snap_line_outer.Visible = true
            snap_line_inner.Visible = true
            
            snap_line_outer.From = Camera.ViewportSize / 2
            snap_line_outer.To = targetScreenPosition
            
            snap_line_inner.From = Camera.ViewportSize / 2
            snap_line_inner.To = targetScreenPosition
        else
            snap_line_outer.Visible = false
            snap_line_inner.Visible = false
        end
    else
        snap_line_outer.Visible = false
        snap_line_inner.Visible = false
    end
end)

function CalculateBulletDrop(tPos, tVel, cPos, pSpeed, pDrop)
    if typeof(tPos) ~= "Vector3" or typeof(cPos) ~= "Vector3" or 
       typeof(tVel) ~= "Vector3" or typeof(pSpeed) ~= "number" or 
       typeof(pDrop) ~= "number" or pSpeed <= 0 or pDrop < 0 then
        return tPos
    end
    
    local dTT = (tPos - cPos).Magnitude  
    local tTT = dTT / pSpeed  
    local pTP = tPos + (tVel * tTT * 6.5)  
    local dP = -pDrop ^ (tTT * pDrop) + 1  
    local pPWD = pTP - Vector3.new(0, dP, 0) 
    local pHP = cPos + ((pTP - cPos).Unit * dTT)
    
    return pPWD, tTT, pHP
end


function Get_info(wep)
    local info = Classes[wep]
    if not info.ProjectileDrop then
        warn("Weapon info not found for:", wep)
        return 1002, 3
    end
    return info.ProjectileSpeed, info.ProjectileDrop
end

local mt = getrawmetatable(Random.new())
setreadonly(mt, false)

local oldNamecall = mt.__namecall
local has_shot = 0
mt.__namecall = newcclosure(function(self, ...)
    local args = {...}
    local methodName = getnamecallmethod()
    if methodName == "NextInteger" then

        if --[[typeof(getstack(3,4)) ~= "CFrame"]] typeof(getstack(3,1)) ~= "Table" or not getstack(3,1).type or getstack(3,1).type ~= "Ghoul" then
            oldNamecall(self, ...)
        end

        local wepdata = getstack(3, 1)
        if not wepdata and typeof(wepdata) ~= "Table" or not target or not target.model then
            return oldNamecall(self, ...)
        end
        
        local origin = Camera.CFrame.Position
        local targetPosition = target.model.Head and target.model.Head.Position
        local velocityVector = target.velocityVector
        local speed, drop, acc = Get_info(wepdata.type)
        local stacklvl = wepdata.type == "Bow" and 4 or 5
        if not targetPosition then
            return oldNamecall(self, ...)
        end

        local predictedPosition, tTT, pHP = CalculateBulletDrop(targetPosition, velocityVector, origin, speed, drop)
        
        if typeof(getstack(3,stacklvl)) == "CFrame" then
            
         spawn(function()
            local startTime = tick()
            while has_shot == 1 do
                RunService.Heartbeat:Wait()
            end
            if Head:FindFirstChild("Neck") then
            Head:FindFirstChild("Neck").Enabled = false
            end
            has_shot = 1
            local scaledTTT = (typeof(tTT) == "number") and ((tTT * 1.1) + ((tTT ^ 2 / tTT) - tTT)) or tTT

            while tick() - startTime < scaledTTT and not not Settings["Combat"]["Aimbot"]["Resover"] do
                Head.CFrame = CFrame.new(pHP + Vector3.new(0, 0, 0))
                RunService.Heartbeat:Wait()
            end
            
            if Head:FindFirstChild("Neck") then
            Head:FindFirstChild("Neck").Enabled = true 
            end
            
            has_shot = 0
        end)
         
        setstack(3, stacklvl, CFrame.lookAt(origin, predictedPosition))
        return 0
        end
        
        return oldNamecall(self, unpack(args))
    end

    return oldNamecall(self, ...)
end)

setreadonly(mt, true)
















-- no nono leaking
