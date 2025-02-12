local Aiming = local UI = game:GetObjects("rbxassetid://8025924073/")[1]
local Services = setmetatable(game:GetChildren(), {
	__index = function(self, ServiceName)
		local Valid, Service = pcall(game.GetService, game, ServiceName)
		if Valid then
			self[ServiceName] = Service
			return Service
		end
	end
})
local Me = Services.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Code = Services.HttpService:GenerateGUID(true)
local DeltaSens
local Settings = setmetatable({
	Set = function(self, Setting, Value)
		local Label = UI[Setting]
		if Setting:sub(#Setting - 2) == "Key" then
			Label.State.Text = Value.Name
		else
			Label.State.Text = Value and "ON" or "OFF"
			Label.State.TextColor3 = Value and Color3.new(0,1,0) or Color3.new(1,0,0)
		end
	end,
	Hook = function(self, Setting, Function)
		return UI[Setting].State:GetPropertyChangedSignal("Text"):Connect(function()
				Function(UI[Setting].State.Text == "ON")
		end)
	end
}, {
	__index = function(self, Setting)
		if Setting:sub(#Setting - 2) == "Key" then
			local Setting = UI[Setting].State.Text
			return Setting ~= "Awaiting input..." and ((Setting:match("MouseButton") and Enum.UserInputType[Setting]) or Enum.KeyCode[Setting])
		elseif UI[Setting]:FindFirstChild("Slide") then
			return tonumber(UI[Setting].Value.Text)
		else
			return UI[Setting].State.Text == "ON"
		end
	end
})
local Utility = {
	GetPlayer = function(self)
		local MousePos = Services.UserInputService:GetMouseLocation()
		local Players = Services.Players:GetPlayers()
		local Selected, Distance = nil, Settings.MaxDistance
		for i = 1, #Players do
			local Player = Players[i]
			local Character = Player.Character or workspace:FindFirstChild(Player.Name, true)
			local Head = Character and (Character:FindFirstChild(Settings.AimForHead and "Head" or "HumanoidRootPart", true) or Character.PrimaryPart)
			if (Player ~= Me) and (self:IsValidHead(Head)) and ((Settings.TeamCheck and Player.TeamColor ~= Me.TeamColor) or (not Settings.TeamCheck)) then
				local Point, Visible = Camera:WorldToScreenPoint(Head.Position)
				if Visible then
					local SelectedDistance = (Vector2.new(Point.X, Point.Y) - MousePos).Magnitude
					local Eval = SelectedDistance <= Distance
					Selected = Eval and Head or Selected
					Distance = Eval and SelectedDistance or Distance
				end
			end
		end
		return Selected
	end,
	GetInputType = function(self, Input)
		return Input.KeyCode.Name ~= "Unknown" and Input.KeyCode or
		Input.UserInputType.Name:match("MouseButton") and Input.UserInputType
	end,
	IsValidHead = function(self, Head)
		if not Head then
			return false 
		end
		local Character = Head:FindFirstAncestorOfClass("Model")
		local Humanoid = Character and (Character:FindFirstChildWhichIsA("Humanoid",true) or {Health = (Character:FindFirstChild("Health",true) or {Value = 1}).Value})
		local _, Visible = Camera:WorldToViewportPoint(Head.Position)
		return Humanoid and Visible and Humanoid.Health > 0
	end
}
local ContextActionFunctions = {
	Aimbotting = function(_, State)
		if not Settings.Functionality or (Settings.AimKeyToggles and State == Enum.UserInputState.End) then
			return
		end
		Settings:Set("Aimbotting", not Settings.Aimbotting)
	end,
	Functionality = function(_, State)
		if State == Enum.UserInputState.Begin and not Settings.Aimbotting then
			Settings:Set("Functionality", not Settings.Functionality)
		end
	end
}
local MoveMouse = (Input and Input.MoveMouse) or mousemoverel
for Index, Button in next, UI:GetChildren() do
	if Button.ClassName == "TextButton" and Button:FindFirstChild("State") then
		if Button.Name:sub(#Button.Name - 2) == "Key" then
			local FunctionName = Button.Name:sub(1, #Button.Name - 3)
			Button.MouseButton1Click:Connect(function()
				Services.ContextActionService:UnbindAction(Code..Button.Name:sub(1, #Button.Name - 3))
				Button.State.Text = "Awaiting input..."
				local Input
				repeat
					Input = Utility:GetInputType(Services.UserInputService.InputBegan:Wait())
				until Input
				Settings:Set(Button.Name, Input)
			end)
			Settings:Hook(Button.Name, function()
				local Input = Settings[Button.Name]
				if Input then
					Services.ContextActionService:BindAction(Code..FunctionName, ContextActionFunctions[FunctionName], false, Input)
				end
			end)
			Services.ContextActionService:BindAction(Code..FunctionName, ContextActionFunctions[FunctionName], false, Settings[Button.Name])
		else
			Button.MouseButton1Click:Connect(function()
				Settings:Set(Button.Name, not Settings[Button.Name])
			end)
		end
	elseif Button:FindFirstChild("Slide") then
		local Slider = Button.Slide.Slider
		local MaxValue = tonumber(Button.Value.Text)
		Slider.MouseButton1Down:Connect(function()
			while Services.UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
				local Mouse = Services.UserInputService:GetMouseLocation()
				Slider.Position = UDim2.new(
					math.clamp((Mouse.X - Slider.Parent.AbsolutePosition.X) / 184, 0, 1),
					0,
					.5,
					-3
				)
				Button.Value.Text = math.floor(math.clamp(MaxValue * Slider.Position.X.Scale, 0, MaxValue))	
				Services.RunService.RenderStepped:Wait()
			end
		end)
	end
end
local CF = CFrame.new
local V2 = Vector2.new
Settings:Hook("Aimbotting", function(Aimbotting)
	if Aimbotting then
		local Aim = Utility:GetPlayer()
		local Smoothness = 1 - Settings.Smoothness / 100
		if MoveMouse and Smoothness ~= 0.99 then
			DeltaSens = Services.UserInputService.MouseDeltaSensitivity
			Services.UserInputService.MouseDeltaSensitivity = Smoothness
			Services.RunService:BindToRenderStep(Code.."RenderStep", 2000, function()
				if not Utility:IsValidHead(Aim) then
					Aim = Utility:GetPlayer()
					return
				end
				local ScreenPoint = Camera:WorldToViewportPoint(Aim.Position)
				local MousePos = V2(ScreenPoint.X, ScreenPoint.Y) - Services.UserInputService:GetMouseLocation()
				MoveMouse(MousePos.X, MousePos.Y)
			end)
		else
			Services.RunService:BindToRenderStep(Code.."RenderStep", 2000, function()
				if not Utility:IsValidHead(Aim) then
					Aim = Utility:GetPlayer()
					return
				end
				Camera.CFrame = Camera.CFrame:Lerp(CF(Camera.CFrame.Position, Aim.Position), Smoothness)
			end)
		end
	else
		Services.UserInputService.MouseDeltaSensitivity = DeltaSens
		Services.RunService:UnbindFromRenderStep(Code.."RenderStep")
	end
end)
Services.ContextActionService:BindAction(Code.."CloseOpen", function(_, State)
	if State == Enum.UserInputState.Begin and Services.UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		UI.Visible = not UI.Visible
	end
end, false, Enum.KeyCode.Tab)
Settings:Set("TeamCheck", #Services.Teams:GetChildren() > 0)
UI.Name = Code
UI.Parent = game:GetService("CoreGui"):FindFirstChildOfClass("ScreenGui")
local AimingChecks = Aiming.Checks
local AimingSelected = Aiming.Selected

-- // Services
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- // Vars
Aiming.AimLock = {
    Enabled = true,
    Keybind = Enum.KeyCode.E,- // You can also have Enum.KeyCode.E, etc.
}
local IsToggled = false
local Settings = Aiming.AimLock

-- //
function Settings.ShouldUseCamera()
    -- //
    return (UserInputService.MouseBehavior == Enum.MouseBehavior.LockCenter)
end
 c`
-- // Allows for custom
function Settings.AimLockPosition(CameraMode)
    local Position = CameraMode and AimingSelected.Part.Position or AimingSelected.Position
    return Position, {}
end

-- // For the toggle and stuff
local function CheckInput(Input, Expected)
    if (not Input or not Expected) then
        return false
    end

    local InputType = Expected.EnumType == Enum.KeyCode and "KeyCode" or "UserInputType"
    return Input[InputType] == Expected
end

UserInputService.InputBegan:Connect(function(Input, GameProcessedEvent)
    -- // Make sure is not processed
    if (GameProcessedEvent) then
        return
    end

    -- // Check if matches bind
    if (CheckInput(Input, Settings.Keybind)) then
        if (Settings.ToggleBind) then
            IsToggled = not IsToggled
        else
            IsToggled = true
        end
    end
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessedEvent)
    -- // Make sure is not processed
    if (GameProcessedEvent) then
        return
    end

    -- // Check if matches bind
    if (CheckInput(Input, Settings.Keybind) and not Settings.ToggleBind) then
        IsToggled = false
    end
end)

-- // Constantly run
local BeizerCurve = Aiming.BeizerCurve
RunService:BindToRenderStep("AimLockAiming", 0, function()
    -- // Vars
    local CameraMode = Settings.ShouldUseCamera()
    local Manager = CameraMode and BeizerCurve.ManagerB or BeizerCurve.ManagerA

    -- // Make sure key (or mouse button) is down
    if (Settings.Enabled and IsToggled and AimingChecks.IsAvailable()) then
        -- // Vars
        local Position, BeizerData = Settings.AimLockPosition(CameraMode)
        BeizerData.TargetPosition = Position

        -- // Aim
        Manager:ChangeData(BeizerData)
    else
        -- // Stop any aim
        Manager:StopCurrent()
    end
end)

-- // Check if GUI exists (for Linoria)
if (Aiming.GUI) then
    -- // Vars
    local AimingTab = Aiming.GUI[2]

    -- //
    local AimLockGroupBox = AimingTab:AddRightTabbox("Aim Lock")
    local MainTab = AimLockGroupBox:AddTab("Main")
    local MouseTab = AimLockGroupBox:AddTab("Mouse")
    local CameraTab = AimLockGroupBox:AddTab("Camera")

    -- //
    MainTab:AddToggle("AimLockEnabled", {
        Text = "Enabled",
        Default = Settings.Enabled,
        Tooltip = "Toggle the Aim Lock on and off",
        Callback = function(Value)
            Settings.Enabled = Value
        end
    }):AddKeyPicker("AimLockEnabledKey", {
        Default = Settings.Keybind,
        SyncToggleState = false,
        Mode = Settings.ToggleBind and "Toggle" or "Hold",
        Text = "Aim Lock",
        NoUI = false,
        Callback = function(State)
            IsToggled = State
        end
    })
    Settings.Keybind = nil

    -- //
    MouseTab:AddSlider("AimLockMouseSmoothness", {
        Text = "Smoothness",
        Tooltip = "How smooth and fast the Mouse lock is",
        Default = BeizerCurve.ManagerA.Smoothness,
        Min = 0,
        Max = 1,
        Rounding = 4,
        Callback = function(Value)
            BeizerCurve.ManagerA.Smoothness = Value
        end
    })

    MouseTab:AddToggle("AimLockMouseDrawPath", {
        Text = "Draw Path",
        Default = BeizerCurve.ManagerA.DrawPath,
        Tooltip = "Draw the aim curve when activated",
        Callback = function(Value)
            BeizerCurve.ManagerA.DrawPath = Value
        end
    })

    local function AddCurvePointSliders(Tab, ManagerName)
        -- // Vars
        local CurvePoints = BeizerCurve["Manager" .. ManagerName].CurvePoints

        -- //
        local function AddSliderXY(i)
            -- // Vars
            local PointName = "Point " .. (i == 1 and "A" or "B")
            local PointNumber = i == 1 and "first" or "second"

            -- // X Slider
            Tab:AddSlider("AimingCurvePointX" .. tostring(i), {
                Text = PointName .. ": X",
                Tooltip = "The X position of the " .. PointNumber .. " point",
                Default = CurvePoints[i].X,
                Min = 0,
                Max = 1,
                Rounding = 2,
                Callback = function(Value)
                    CurvePoints[i] = Vector2.new(Value, CurvePoints[i].Y)
                end
            })

            -- // Y Slider
            Tab:AddSlider("AimingCurvePointY" .. tostring(i), {
                Text = PointName .. ": Y",
                Tooltip = "The Y position of the " .. PointNumber .. " point",
                Default = CurvePoints[i].Y,
                Min = 0,
                Max = 1,
                Rounding = 2,
                Callback = function(Value)
                    CurvePoints[i] = Vector2.new(CurvePoints[i].X, Value)
                end
            })
        end

        AddSliderXY(1)
        AddSliderXY(2)
    end

    AddCurvePointSliders(MouseTab, "A")

    -- //
    CameraTab:AddSlider("AimLockCameraSmoothness", {
        Text = "Smoothness",
        Tooltip = "How smooth and fast the Camera lock is",
        Default = BeizerCurve.ManagerB.Smoothness,
        Min = 0,
        Max = 1,
        Rounding = 4,
        Callback = function(Value)
            BeizerCurve.ManagerB.Smoothness = Value
        end
    })

    AddCurvePointSliders(CameraTab, "B")
end

-- //
return Aiming
