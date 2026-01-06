--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()
local UIS = UserInputService

--// Settings
local ESPObjects = {}
local ESPEnabled = true
local ShowDistance = true
local TeamColors = true
local AimlockEnabled = false
local FlyEnabled = false
local ESPKey = Enum.KeyCode.E -- Standardtastenzuweisung für ESP
local FlyKey = Enum.KeyCode.F -- Standardtastenzuweisung für Fly
local AimKey = Enum.UserInputType.MouseButton2
local FlySpeed = 50
local SmoothAimSpeed = 0.15
local GUIVisible = true

-- Fly Variables
local FlyBV

--// GUI erstellen
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "Modern_ESP_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

-- Hauptframe
local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 300, 0, 450)
Frame.Position = UDim2.new(0, 20, 0, 20) -- Position im sichtbaren Bereich
Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = true
Frame.Parent = ScreenGui

-- Runder Corner
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 15)
UICorner.Parent = Frame

-- Schatten
local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(60, 60, 60)
UIStroke.Thickness = 2
UIStroke.Parent = Frame

-- Titel
local Title = Instance.new("TextLabel")
Title.Text = "ESP & Aimlock & Fly"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 0)
Title.BackgroundTransparency = 1
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 24
Title.Parent = Frame

--// Hover-Effekt
local function HoverEffect(button)
    button.MouseEnter:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    end)
end

--// Button mit On/Off-Indikator
local function CreateToggleButton(text, posY, stateGetter, callback)
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 220, 0, 40)
    button.Position = UDim2.new(0, 20, 0, posY)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.Font = Enum.Font.Gotham
    button.TextSize = 18
    button.Text = text
    button.Parent = Frame
    HoverEffect(button)

    local indicator = Instance.new("Frame")
    indicator.Size = UDim2.new(0, 30, 0, 30)
    indicator.Position = UDim2.new(0, 200, 0, posY + 5)
    indicator.BackgroundColor3 = stateGetter() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    indicator.BorderSizePixel = 0
    indicator.Parent = Frame

    local indCorner = Instance.new("UICorner")
    indCorner.CornerRadius = UDim.new(0, 12)
    indCorner.Parent = indicator

    button.MouseButton1Click:Connect(function()
        callback()
        indicator.BackgroundColor3 = stateGetter() and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 0, 0)
    end)

    return posY + 50 -- neue Y-Position zurück
end

--// Slider erstellen
local function CreateSlider(text, posY, min, max, default, callback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 250, 0, 20)
    label.Position = UDim2.new(0, 20, 0, posY)
    label.BackgroundTransparency = 1
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.Gotham
    label.TextSize = 14
    label.Text = string.format("%s: %.2f", text, default)
    label.Parent = Frame

    local slider = Instance.new("Frame")
    slider.Size = UDim2.new(0, 250, 0, 12)
    slider.Position = UDim2.new(0, 20, 0, posY + 20)
    slider.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
    slider.Parent = Frame

    local sliderCorner = Instance.new("UICorner")
    sliderCorner.CornerRadius = UDim.new(0, 6)
    sliderCorner.Parent = slider

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(default, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
    fill.Parent = slider

    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(0, 6)
    fillCorner.Parent = fill

    local dragging = false
    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    slider.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UIS.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local relative = math.clamp((Mouse.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
            fill.Size = UDim2.new(relative, 0, 1, 0)
            local value = min + (max - min) * relative
            label.Text = string.format("%s: %.2f", text, value)
            callback(value)
        end
    end)
    return posY + 50
end

--// Buttons & Sliders modular platzieren
local currentY = 40

-- ESP / Aimlock Module
currentY = CreateToggleButton("ESP", currentY, function() return ESPEnabled end, function() ESPEnabled = not ESPEnabled end)
currentY = CreateToggleButton("Distance", currentY, function() return ShowDistance end, function() ShowDistance = not ShowDistance end)
currentY = CreateToggleButton("Team Colors", currentY, function() return Team
