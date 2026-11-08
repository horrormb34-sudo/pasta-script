-- language: Luau (Roblox), executor compatible
-- *PASTA: Highlight + Skeleton + Weapon (FIX)*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    SpeedEnabled = false,
    SpeedValue = 50,
    InfJump = false,
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.2,
    
    ESPEnabled = true,
    ESPMaxDistance = 1000,
    SkeletonESP = true,
    WeaponESP = true,
    
    ColorEnemy = Color3.fromRGB(255, 105, 180),
    ColorAlly = Color3.fromRGB(0, 255, 170),
    ColorSkeleton = Color3.fromRGB(255, 255, 255),
    ColorText = Color3.fromRGB(255, 240, 245),
    
    JitterEnabled = false,
    MenuOpen = true,
    Keybind = Enum.KeyCode.RightShift,
    ColorAccent = Color3.fromRGB(255, 105, 180),
    ColorBg = Color3.fromRGB(30, 20, 25),
}

local Highlights = {}
local Drawings = {}
local FOVCircle = Drawing.new("Circle")

-- ==========================================
-- UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PastaUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Settings.ColorBg
MainFrame.BackgroundTransparency = 0.1
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.Size = UDim2.new(0, 400, 0, 400)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Stroke = Instance.new("UIStroke", MainFrame)
Stroke.Color = Settings.ColorAccent
Stroke.Thickness = 1.5

local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "🌸 PASTA"
Title.TextColor3 = Settings.ColorAccent
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UIPadding", Title).PaddingLeft = UDim.new(0, 15)

local Line = Instance.new("Frame", MainFrame)
Line.BackgroundColor3 = Settings.ColorAccent
Line.BackgroundTransparency = 0.5
Line.Position = UDim2.new(0, 10, 0, 40)
Line.Size = UDim2.new(1, -20, 0, 1)
Line.BorderSizePixel = 0

local TabPanel = Instance.new("Frame", MainFrame)
TabPanel.BackgroundColor3 = Color3.fromRGB(40, 25, 30)
TabPanel.Position = UDim2.new(0, 0, 0, 45)
TabPanel.Size = UDim2.new(0, 100, 1, -45)
TabPanel.BorderSizePixel = 0
Instance.new("UICorner", TabPanel).CornerRadius = UDim.new(0, 12)
Instance.new("UIListLayout", TabPanel).Padding = UDim.new(0, 5)

local ContentFrame = Instance.new("Frame", MainFrame)
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 110, 0, 50)
ContentFrame.Size = UDim2.new(1, -120, 1, -60)

local function CreateTabButton(name, order)
    local Btn = Instance.new("TextButton", TabPanel)
    Btn.BackgroundColor3 = Color3.fromRGB(50, 30, 35)
    Btn.Size = UDim2.new(1, -10, 0, 30)
    Btn.Text = name
    Btn.Font = Enum.Font.GothamSemibold
    Btn.TextSize = 12
    Btn.TextColor3 = Color3.fromRGB(255, 240, 245)
    Btn.LayoutOrder = order
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    return Btn
end

local function CreateToggle(parent, name, defaultState, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
    Btn.Size = UDim2.new(1, 0, 0, 30)
    Btn.Text = ""
    Btn.AutoButtonColor = false
    Instance.new("UICorner", Btn).CornerRadius = UDim.new(0, 6)
    
    local Label = Instance.new("TextLabel", Btn)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 0)
    Label.Size = UDim2.new(1, -40, 1, 0)
    Label.Font = Enum.Font.Gotham
    Label.Text = name
    Label.TextColor3 = Color3.fromRGB(255, 240, 245)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left
    
    local Ind = Instance.new("Frame", Btn)
    Ind.BackgroundColor3 = defaultState and Settings.ColorAccent or Color3.fromRGB(70, 50, 55)
    Ind.Position = UDim2.new(1, -35, 0.5, -8)
    Ind.Size = UDim2.new(0, 20, 0, 16)
    Instance.new("UICorner", Ind).CornerRadius = UDim.new(1, 0)
    
    local Dot = Instance.new("Frame", Ind)
    Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Dot.Position = defaultState and UDim2.new(1, -12, 0, 2) or UDim2.new(0, 2, 0, 2)
    Dot.Size = UDim2.new(0, 12, 1, -4)
    Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

    local state = defaultState
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Ind.BackgroundColor3 = state and Settings.ColorAccent or Color3.fromRGB(70, 50, 55)
        Dot:TweenPosition(state and UDim2.new(1, -12, 0, 2) or UDim2.new(0, 2, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        callback(state)
    end)
end

local function CreateSlider(parent, name, min, max, default, callback)
    local Frame = Instance.new("Frame", parent)
    Frame.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
    Frame.Size = UDim2.new(1, 0, 0, 45)
    Instance.new("UICorner", Frame).CornerRadius = UDim.new(0, 6)

    local Label = Instance.new("TextLabel", Frame)
    Label.BackgroundTransparency = 1
    Label.Position = UDim2.new(0, 10, 0, 5)
    Label.Size = UDim2.new(1, -20, 0, 15)
    Label.Font = Enum.Font.Gotham
    Label.Text = name .. ": " .. default
    Label.TextColor3 = Color3.fromRGB(255, 240, 245)
    Label.TextSize = 12
    Label.TextXAlignment = Enum.TextXAlignment.Left

    local Bar = Instance.new("Frame", Frame)
    Bar.BackgroundColor3 = Color3.fromRGB(70, 50, 55)
    Bar.Position = UDim2.new(0, 10, 0, 30)
    Bar.Size = UDim2.new(1, -20, 0, 4)
    Instance.new("UICorner", Bar).CornerRadius = UDim.new(1, 0)

    local Fill = Instance.new("Frame", Bar)
    Fill.BackgroundColor3 = Settings.ColorAccent
    Fill.Size = UDim2.new((default - min)/(max - min), 0, 1, 0)
    Instance.new("UICorner", Fill).CornerRadius = UDim.new(1, 0)

    local Btn = Instance.new("TextButton", Bar)
    Btn.BackgroundTransparency = 1
    Btn.Size = UDim2.new(1, 20, 1, 20)
    Btn.Position = UDim2.new(0, -10, 0, -8)
    Btn.Text = ""

    local dragging = false
    Btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = true end
    end)
    Btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            local percent = math.clamp((UserInputService:GetMouseLocation().X - Bar.AbsolutePosition.X) / Bar.AbsoluteSize.X, 0, 1)
            Fill.Size = UDim2.new(percent, 0, 1, 0)
            local val = math.floor(min + (max - min) * percent)
            Label.Text = name .. ": " .. val
            callback(val)
        end
    end)
end

local function CreatePage()
    local Page = Instance.new("ScrollingFrame", ContentFrame)
    Page.BackgroundTransparency = 1
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BorderSizePixel = 0
    Page.Visible = false
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Settings.ColorAccent
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)
    return Page
end

local TabMisc = CreateTabButton("MISC", 1)
local TabAim = CreateTabButton("AIM", 2)
local TabVisuals = CreateTabButton("VISUALS", 3)
local TabAntiAim = CreateTabButton("ANTI-AIM", 4)

local PageMisc, PageAim, PageVisuals, PageAntiAim = CreatePage(), CreatePage(), CreatePage(), CreatePage()

local function SelectTab(btn, page)
    for _, b in pairs(TabPanel:GetChildren()) do 
        if b:IsA("TextButton") then b.BackgroundColor3 = Color3.fromRGB(50, 30, 35) end 
    end
    btn.BackgroundColor3 = Settings.ColorAccent
    btn.TextColor3 = Color3.fromRGB(0, 0, 0)
    
    for _, p in pairs(ContentFrame:GetChildren()) do 
        if p:IsA("ScrollingFrame") then p.Visible = false end 
    end
    page.Visible = true
end

TabMisc.MouseButton1Click:Connect(function() SelectTab(TabMisc, PageMisc) end)
TabAim.MouseButton1Click:Connect(function() SelectTab(TabAim, PageAim) end)
TabVisuals.MouseButton1Click:Connect(function() SelectTab(TabVisuals, PageVisuals) end)
TabAntiAim.MouseButton1Click:Connect(function() SelectTab(TabAntiAim, PageAntiAim) end)
SelectTab(TabVisuals, PageVisuals)

-- ==========================================
-- НАПОЛНЕНИЕ (Добавлены кнопки Скелет и Оружие)
-- ==========================================
-- MISC
CreateToggle(PageMisc, "Speed Hack", false, function(s) Settings.SpeedEnabled = s end)
CreateToggle(PageMisc, "Infinite Jump", false, function(s) Settings.InfJump = s end)

-- AIM
CreateToggle(PageAim, "Smooth Aimbot (RMB)", false, function(s) Settings.AimbotEnabled = s end)
CreateSlider(PageAim, "FOV Radius", 50, 500, Settings.AimbotFOV, function(val) 
    Settings.AimbotFOV = val 
    FOVCircle.Radius = val
end)

-- VISUALS
CreateToggle(PageVisuals, "Wallhack (ESP)", true, function(s) Settings.ESPEnabled = s end)
CreateToggle(PageVisuals, "Skeleton", true, function(s) Settings.SkeletonESP = s end) -- НОВОЕ
CreateToggle(PageVisuals, "Weapon Text", true, function(s) Settings.WeaponESP = s end) -- НОВОЕ
CreateSlider(PageVisuals, "Max Distance (m)", 50, 3000, Settings.ESPMaxDistance, function(val) 
    Settings.ESPMaxDistance = val 
end)

-- ANTI-AIM
CreateToggle(PageAntiAim, "Jitter", false, function(s) Settings.JitterEnabled = s end)

local CloseBtn = Instance.new("TextButton", PageMisc)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 51, 102)
CloseBtn.Size = UDim2.new(1, 0, 0, 30)
CloseBtn.Text = "CLOSE SCRIPT (Unload)"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    FOVCircle:Remove()
    for _, hl in pairs(Highlights) do if hl and hl.Parent then hl:Destroy() end end
    for _, draw in pairs(Drawings) do
        if draw.skel then for _, l in pairs(draw.skel) do l:Remove() end end
        if draw.text then draw.text:Remove() end
    end
    ScreenGui:Destroy()
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Keybind then
        Settings.MenuOpen = not Settings.MenuOpen
        MainFrame.Visible = Settings.MenuOpen
    end
end)

-- ==========================================
-- ЛОГИКА (Highlight + Drawing)
-- ==========================================
local function GetClosestEnemy()
    local closest = nil
    local shortestDist = Settings.AimbotFOV
    local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if player.Team == LocalPlayer.Team and player.Team ~= nil then continue end
        local char = player.Character
        local hum = char and char:FindFirstChild("Humanoid")
        local root = char and char:FindFirstChild("HumanoidRootPart")
        if hum and hum.Health > 0 and root then
            local pos, on_screen = Camera:WorldToViewportPoint(root.Position)
            if on_screen then
                local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                if dist < shortestDist then
                    shortestDist = dist
                    closest = char
                end
            end
        end
    end
    return closest
end

local function CreateDrawing()
    local obj = {skel = {}, text = Drawing.new("Text")}
    for i = 1, 15 do
        local line = Drawing.new("Line")
        line.Thickness = 1.5
        line.Visible = false
        table.insert(obj.skel, line)
    end
    obj.text.Size = 14
    obj.text.Center = true
    obj.text.Outline = true
    obj.text.Visible = false
    return obj
end

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- AIM
    FOVCircle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    FOVCircle.Visible = Settings.AimbotEnabled
    
    if Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestEnemy()
        if target then
            local targetPart = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), Settings.AimbotSmooth)
            end
        end
    end

    -- VISUALS
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local pChar = player.Character
        local pHum = pChar and pChar:FindFirstChild("Humanoid")
        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
        
        if not pChar or not pHum or pHum.Health <= 0 or not pRoot then
            if Highlights[player] then Highlights[player]:Destroy() Highlights[player] = nil end
            if Drawings[player] then
                for _, l in pairs(Drawings[player].skel) do l:Remove() end
                Drawings[player].text:Remove()
                Drawings[player] = nil
            end
            continue
        end
        
        local distMeters = math.floor(((pRoot.Position - hrp.Position).Magnitude) / 3.28)
        
        if Settings.ESPEnabled and distMeters <= Settings.ESPMaxDistance then
            -- 1. Подсветка
            if not Highlights[player] then
                local hl = Instance.new("Highlight")
                hl.Name = "PastaHighlight"
                hl.Parent = pChar
                Highlights[player] = hl
            end
            local hl = Highlights[player]
            local isEnemy = player.Team ~= LocalPlayer.Team or player.Team == nil
            hl.FillColor = isEnemy and Settings.ColorEnemy or Settings.ColorAlly
            hl.OutlineColor = Color3.fromRGB(255, 255, 255)
            hl.FillTransparency = 0.5
            hl.OutlineTransparency = 0.5
            hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            
            -- 2. Скелет и Оружие
            if Settings.SkeletonESP or Settings.WeaponESP then
                if not Drawings[player] then Drawings[player] = CreateDrawing() end
                local esp = Drawings[player]
                local pos, on_screen = Camera:WorldToViewportPoint(pRoot.Position)
                
                if on_screen then
                    if Settings.SkeletonESP then
                        local bones = {{"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"UpperTorso", "RightUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"RightUpperArm", "RightLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LowerTorso", "RightUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"RightLowerLeg", "RightFoot"}}
                        local r6_bones = {{"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}}
                        local boneList = (pChar:FindFirstChild("Torso") ~= nil) and r6_bones or bones
                        
                        for i = 1, 15 do
                            local line = esp.skel[i]
                            if i <= #boneList then
                                local p1 = pChar:FindFirstChild(boneList[i][1])
                                local p2 = pChar:FindFirstChild(boneList[i][2])
                                if p1 and p2 then
                                    local p1Pos, on1 = Camera:WorldToViewportPoint(p1.Position)
                                    local p2Pos, on2 = Camera:WorldToViewportPoint(p2.Position)
                                    if on1 and on2 then
                                        line.From = Vector2.new(p1Pos.X, p1Pos.Y)
                                        line.To = Vector2.new(p2Pos.X, p2Pos.Y)
                                        line.Color = Settings.ColorSkeleton
                                        line.Visible = true
                                    else line.Visible = false end
                                else line.Visible = false end
                            else line.Visible = false end
                        end
                    else for _, l in pairs(esp.skel) do l.Visible = false end end
                    
                    if Settings.WeaponESP then
                        local tool = pChar:FindFirstChildOfClass("Tool")
                        if tool then
                            esp.text.Text = tool.Name
                            esp.text.Position = Vector2.new(pos.X, pos.Y + (100 / pos.Z * 5) + 20)
                            esp.text.Color = Settings.ColorText
                            esp.text.Visible = true
                        else esp.text.Visible = false end
                    else esp.text.Visible = false end
                else
                    for _, l in pairs(esp.skel) do l.Visible = false end
                    esp.text.Visible = false
                end
            end
        else
            if Highlights[player] then Highlights[player]:Destroy() Highlights[player] = nil end
            if Drawings[player] then
                for _, l in pairs(Drawings[player].skel) do l.Visible = false end
                Drawings[player].text.Visible = false
            end
        end
    end
end)
