loadstring(game:HttpGet('https://raw.githubusercontent.com/EdgeIY/infiniteyield/master/source'))()

-- EDUCATIONAL PURPOSES (UI / math / camera techniques)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UIS = UserInputService

--// ================= SETTINGS =================
local Settings = {
    ESP = true,
    ESPName = true, -- neu: Name separat togglebar
    Distance = true,
    TeamColors = true,

    Aimlock = false,
    SmoothAim = 0.1,

    WallCheck = true,
    FOV = true,
    FOVRadius = 150,

    Fly = false,
    FlySpeed = 60,
}

--// ================= GUI =================
local ScreenGui = Instance.new("ScreenGui", LocalPlayer.PlayerGui)
ScreenGui.ResetOnSpawn = false

local Frame = Instance.new("Frame", ScreenGui)
Frame.Size = UDim2.fromOffset(320, 560)
Frame.Position = UDim2.fromOffset(20, 20)
Frame.BackgroundColor3 = Color3.fromRGB(25,25,25)
Frame.Active = true
Frame.Draggable = true
Instance.new("UICorner", Frame).CornerRadius = UDim.new(0,16)

local Title = Instance.new("TextLabel", Frame)
Title.Size = UDim2.new(1,0,0,40)
Title.BackgroundTransparency = 1
Title.Text = "Tweeks Privat Script"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 22
Title.TextColor3 = Color3.new(1,1,1)

--// ================= UI HELPERS =================
local function Toggle(text, y, get, set)
    local b = Instance.new("TextButton", Frame)
    b.Size = UDim2.fromOffset(220,38)
    b.Position = UDim2.fromOffset(20,y)
    b.BackgroundColor3 = Color3.fromRGB(45,45,45)
    b.Text = text
    b.Font = Enum.Font.Gotham
    b.TextSize = 16
    b.TextColor3 = Color3.new(1,1,1)

    local ind = Instance.new("Frame", Frame)
    ind.Size = UDim2.fromOffset(26,26)
    ind.Position = UDim2.fromOffset(250,y+6)
    Instance.new("UICorner", ind)

    local function refresh()
        ind.BackgroundColor3 = get() and Color3.fromRGB(0,200,0) or Color3.fromRGB(200,0,0)
    end
    refresh()

    b.MouseButton1Click:Connect(function()
        set(not get())
        refresh()
    end)
    return y + 46
end

local function Slider(text,y,min,max,default,callback)
    local lbl = Instance.new("TextLabel",Frame)
    lbl.Position = UDim2.fromOffset(20,y)
    lbl.Size = UDim2.fromOffset(260,18)
    lbl.BackgroundTransparency = 1
    lbl.Font = Enum.Font.Gotham
    lbl.TextSize = 14
    lbl.TextColor3 = Color3.new(1,1,1)

    local bar = Instance.new("Frame",Frame)
    bar.Position = UDim2.fromOffset(20,y+20)
    bar.Size = UDim2.fromOffset(260,10)
    bar.BackgroundColor3 = Color3.fromRGB(60,60,60)
    Instance.new("UICorner",bar)

    local fill = Instance.new("Frame",bar)
    fill.BackgroundColor3 = Color3.fromRGB(204,0,204)
    Instance.new("UICorner",fill)

    local function setValue(v)
        v = math.clamp(v,min,max)
        fill.Size = UDim2.new((v-min)/(max-min),0,1,0)
        lbl.Text = string.format("%s: %.2f", text, v)
        callback(v)
    end

    setValue(default)

    local drag=false
    bar.InputBegan:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=true end
    end)
    bar.InputEnded:Connect(function(i)
        if i.UserInputType==Enum.UserInputType.MouseButton1 then drag=false end
    end)
    UIS.InputChanged:Connect(function(i)
        if drag and i.UserInputType==Enum.UserInputType.MouseMovement then
            local r=(i.Position.X-bar.AbsolutePosition.X)/bar.AbsoluteSize.X
            setValue(min+(max-min)*r)
        end
    end)
    return y+48
end

--// ================= BUILD UI =================
local y=50
y=Toggle("ESP",y,function()return Settings.ESP end,function(v)Settings.ESP=v end)
y=Toggle("Names",y,function()return Settings.ESPName end,function(v)Settings.ESPName=v end)
y=Toggle("Distance",y,function()return Settings.Distance end,function(v)Settings.Distance=v end)
y=Toggle("Team Colors",y,function()return Settings.TeamColors end,function(v)Settings.TeamColors=v end)
y=Toggle("Aimlock (RMB)",y,function()return Settings.Aimlock end,function(v)Settings.Aimlock=v end)
y=Toggle("Wallcheck",y,function()return Settings.WallCheck end,function(v)Settings.WallCheck=v end)
y=Toggle("FOV Circle",y,function()return Settings.FOV end,function(v)Settings.FOV=v end)
y=Slider("FOV Radius",y,50,500,Settings.FOVRadius,function(v)Settings.FOVRadius=v end)
y=Slider("Aim Smooth",y,0.05,1,Settings.SmoothAim,function(v)Settings.SmoothAim=v end)
y=Toggle("Fly",y,function()return Settings.Fly end,function(v)Settings.Fly=v end)
y=Slider("Fly Speed",y,20,200,Settings.FlySpeed,function(v)Settings.FlySpeed=v end)

--// ================= ESP =================
local ESP = {}
local function newESP(plr)
    if plr==LocalPlayer then return end
    local box = Drawing.new("Square")
    box.Thickness = 2
    box.Filled = false
    local txt = Drawing.new("Text")
    txt.Center = true
    txt.Outline = true
    ESP[plr] = {box, txt}
end
local function remESP(plr)
    if ESP[plr] then
        ESP[plr][1]:Remove()
        ESP[plr][2]:Remove()
        ESP[plr] = nil
    end
end
for _,p in ipairs(Players:GetPlayers()) do newESP(p) end
Players.PlayerAdded:Connect(newESP)
Players.PlayerRemoving:Connect(remESP)

--// ================= FOV CIRCLE =================
local FOVCircle = Drawing.new("Circle")
FOVCircle.NumSides = 64
FOVCircle.Thickness = 2
FOVCircle.Filled = false
FOVCircle.Color = Color3.fromRGB(102,0,102)

--// ================= WALLCHECK =================
local function hasLineOfSight(part)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Blacklist
    params.FilterDescendantsInstances = {LocalPlayer.Character, part.Parent}
    params.IgnoreWater = true
    local r = workspace:Raycast(Camera.CFrame.Position, part.Position-Camera.CFrame.Position, params)
    return not r or r.Instance:IsDescendantOf(part.Parent)
end

--// ================= AIM =================
local currentTarget
local function closestEnemy()
    local best, dist = nil, math.huge
    local viewportCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    for plr,_ in pairs(ESP) do
        local c = plr.Character
        local h = c and c:FindFirstChild("Humanoid")
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        if h and hrp and h.Health > 0 and plr.Team ~= LocalPlayer.Team then
            local pos, on = Camera:WorldToViewportPoint(hrp.Position)
            if on then
                local d = (viewportCenter - Vector2.new(pos.X,pos.Y)).Magnitude
                if (not Settings.FOV or d <= Settings.FOVRadius) and (not Settings.WallCheck or hasLineOfSight(hrp)) then
                    if d < dist then
                        best = hrp
                        dist = d
                    end
                end
            end
        end
    end
    return best
end

--// ================= RGB HELPER =================
local function getRainbowColor(speed)
    local t = tick() * speed
    return Color3.fromHSV(t % 1, 1, 1)
end

--// ================= MAIN LOOP =================
local BV
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    local hum = char and char:FindFirstChild("Humanoid")
    if not hrp or not hum then return end

    -- FOV-Circle
    local viewportCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    FOVCircle.Visible = Settings.FOV
    FOVCircle.Position = viewportCenter
    FOVCircle.Radius = Settings.FOVRadius

    -- ESP
    for plr,v in pairs(ESP) do
        local box, txt = v[1], v[2]
        local c = plr.Character
        local hrp2 = c and c:FindFirstChild("HumanoidRootPart")
        local h = c and c:FindFirstChild("Humanoid")
        if Settings.ESP and hrp2 and h and h.Health > 0 then
            local pos, on = Camera:WorldToViewportPoint(hrp2.Position)
            if on then
                local scale = 1/(pos.Z*math.tan(math.rad(Camera.FieldOfView/2))*2)*1000
                local w,hg = math.clamp(4.5*scale,20,300), math.clamp(6*scale,35,400)
                
                -- Box
                box.Size = Vector2.new(w,hg)
                box.Position = Vector2.new(pos.X-w/2,pos.Y-hg/2)
                if plr.Team == LocalPlayer.Team then
                    box.Color = Color3.fromRGB(0,255,0)
                else
                    box.Color = getRainbowColor(0.2)
                end
                box.Visible = true

                -- Name
                if Settings.ESPName then
                    txt.Text = Settings.Distance and plr.Name.." ["..math.floor((hrp2.Position - hrp.Position).Magnitude).."]" or plr.Name
                    txt.Position = Vector2.new(pos.X,pos.Y-hg/2-14)
                    txt.Size = math.clamp(12*scale,12,22)
                    txt.Color = box.Color
                    txt.Visible = true
                else
                    txt.Visible = false
                end
            else
                box.Visible=false
                txt.Visible=false
            end
        else
            box.Visible=false
            txt.Visible=false
        end
    end

    -- Aimlock
    if Settings.Aimlock and UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        currentTarget = currentTarget or closestEnemy()
        if currentTarget then
            Camera.CFrame = Camera.CFrame:Lerp(
                CFrame.new(Camera.CFrame.Position, currentTarget.Position),
                Settings.SmoothAim
            )
        end
    else
        currentTarget = nil
    end

    -- Fly
    if Settings.Fly then
        if not BV then
            BV=Instance.new("BodyVelocity",hrp)
            BV.MaxForce=Vector3.new(1e6,1e6,1e6)
        end
        local dir=Vector3.zero
        local cf=Camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.yAxis end
        BV.Velocity=dir.Magnitude>0 and dir.Unit*Settings.FlySpeed or Vector3.zero
        hum.PlatformStand=true
    else
        if BV then BV:Destroy() BV=nil end
        hum.PlatformStand=false
    end
end)
