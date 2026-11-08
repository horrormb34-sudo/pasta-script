-- language: Luau (Roblox), executor compatible
-- *PASTA: External Visuals (Drawing)*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESPEnabled = true,
    BoxESP = true,
    NameESP = true,
    DistanceESP = true,
    HealthESP = true,
    MaxDistance = 1000,
    
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.2,
    
    ColorEnemy = Color3.fromRGB(255, 105, 180),
    ColorAlly = Color3.fromRGB(0, 255, 170),
    ColorText = Color3.fromRGB(255, 255, 255),
    
    MenuOpen = true,
    Keybind = Enum.KeyCode.RightShift,
    ColorAccent = Color3.fromRGB(255, 105, 180),
    ColorBg = Color3.fromRGB(30, 20, 25),
}

local Drawings = {}

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
MainFrame.Size = UDim2.new(0, 300, 0, 200)
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
Title.Text = "🌸 PASTA | DRAWING"
Title.TextColor3 = Settings.ColorAccent
Title.TextSize = 16
Title.TextXAlignment = Enum.TextXAlignment.Left
Instance.new("UIPadding", Title).PaddingLeft = UDim.new(0, 15)

local function CreateToggle(parent, name, posY, defaultState, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
    Btn.Position = UDim2.new(0, 10, 0, posY)
    Btn.Size = UDim2.new(1, -20, 0, 30)
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

CreateToggle(MainFrame, "Wallhack (ESP)", 50, true, function(s) Settings.ESPEnabled = s end)
CreateToggle(MainFrame, "Aimbot (RMB)", 90, false, function(s) Settings.AimbotEnabled = s end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 51, 102)
CloseBtn.Position = UDim2.new(0, 10, 0, 140)
CloseBtn.Size = UDim2.new(1, -20, 0, 30)
CloseBtn.Text = "FULL UNLOAD (CLOSE)"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    for _, obj in pairs(Drawings) do
        if obj.lines then for _, l in pairs(obj.lines) do l:Remove() end end
        if obj.text then obj.text:Remove() end
    end
    Drawings = {}
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
-- ЛОГИКА
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

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- Aimbot
    if Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestEnemy()
        if target then
            local targetPart = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), Settings.AimbotSmooth)
            end
        end
    end

    -- ESP (Drawing)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local pChar = player.Character
        local pHum = pChar and pChar:FindFirstChild("Humanoid")
        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
        
        if not pChar or not pHum or pHum.Health <= 0 or not pRoot then
            if Drawings[player] then
                if Drawings[player].lines then for _, l in pairs(Drawings[player].lines) do l:Remove() end end
                if Drawings[player].text then Drawings[player].text:Remove() end
                Drawings[player] = nil
            end
            continue
        end
        
        local distMeters = math.floor(((pRoot.Position - hrp.Position).Magnitude) / 3.28)
        
        if Settings.ESPEnabled and distMeters <= Settings.MaxDistance then
            if not Drawings[player] then
                local obj = {lines = {}, text = Drawing.new("Text")}
                for i = 1, 4 do
                    local line = Drawing.new("Line")
                    line.Thickness = 1.5
                    line.Visible = false
                    table.insert(obj.lines, line)
                end
                obj.text.Size = 14
                obj.text.Center = true
                obj.text.Outline = true
                obj.text.Visible = false
                Drawings[player] = obj
            end
            
            local esp = Drawings[player]
            local pos, on_screen = Camera:WorldToViewportPoint(pRoot.Position)
            local isEnemy = player.Team ~= LocalPlayer.Team or player.Team == nil
            local color = isEnemy and Settings.ColorEnemy or Settings.ColorAlly
            
            if on_screen then
                local height = 100 / pos.Z * 5
                local width = height / 2
                local x, y = pos.X, pos.Y
                local topY, botY = y - height, y + height
                
                -- Рисуем бокс
                local lines = {
                    {Vector2.new(x - width, topY), Vector2.new(x + width, topY)},
                    {Vector2.new(x + width, topY), Vector2.new(x + width, botY)},
                    {Vector2.new(x + width, botY), Vector2.new(x - width, botY)},
                    {Vector2.new(x - width, botY), Vector2.new(x - width, topY)}
                }
                for i, coords in ipairs(lines) do
                    esp.lines[i].From = coords[1]
                    esp.lines[i].To = coords[2]
                    esp.lines[i].Color = color
                    esp.lines[i].Visible = true
                end
                
                -- Пишем текст
                esp.text.Text = player.Name .. " [" .. distMeters .. "m]"
                esp.text.Position = Vector2.new(x, topY - 18)
                esp.text.Color = Settings.ColorText
                esp.text.Visible = true
            else
                for _, l in pairs(esp.lines) do l.Visible = false end
                esp.text.Visible = false
            end
        else
            if Drawings[player] then
                for _, l in pairs(Drawings[player].lines) do l.Visible = false end
                Drawings[player].text.Visible = false
            end
        end
    end
end)
