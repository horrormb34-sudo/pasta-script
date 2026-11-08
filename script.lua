-- language: Luau (Roblox), executor compatible
-- *PASTA: Highlight ESP (Fully Unloadable)*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESPEnabled = true,
    MaxDistance = 1000,
    
    AimbotEnabled = false,
    AimbotFOV = 150,
    AimbotSmooth = 0.2,
    
    ColorEnemy = Color3.fromRGB(255, 105, 180),
    ColorAlly = Color3.fromRGB(0, 255, 170),
    
    MenuOpen = true,
    Keybind = Enum.KeyCode.RightShift,
    ColorAccent = Color3.fromRGB(255, 105, 180),
    ColorBg = Color3.fromRGB(30, 20, 25),
}

local Highlights = {}
local Connection -- Для хранения соединения RenderStepped

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
Title.Text = "🌸 PASTA | CHAMS"
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

CreateToggle(MainFrame, "Chams (Wallhack)", 50, true, function(s) Settings.ESPEnabled = s end)
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
    -- 1. Отключаем цикл обновления
    if Connection then
        Connection:Disconnect()
        Connection = nil
    end
    
    -- 2. Удаляем все подсветки
    for player, hl in pairs(Highlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
        Highlights[player] = nil
    end
    
    -- 3. Возвращаем камеру в нормальное состояние (если она была изменена)
    Camera.CameraType = Enum.CameraType.Custom
    Camera.CameraSubject = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") or nil
    
    -- 4. Удаляем интерфейс
    ScreenGui:Destroy()
    
    -- 5. Восстанавливаем мышь (на случай, если игра ее заблокировала)
    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
    UserInputService.MouseIconEnabled = true
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

-- Сохраняем соединение в переменную, чтобы можно было его разорвать
Connection = RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    local hum = char:FindFirstChild("Humanoid")
    if not hrp or not hum or hum.Health <= 0 then return end

    -- 1. Aimbot
    if Settings.AimbotEnabled and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
        local target = GetClosestEnemy()
        if target then
            local targetPart = target:FindFirstChild("Head") or target:FindFirstChild("HumanoidRootPart")
            if targetPart then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, targetPart.Position), Settings.AimbotSmooth)
            end
        end
    end

    -- 2. Chams (Highlight)
    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        local pChar = player.Character
        local pHum = pChar and pChar:FindFirstChild("Humanoid")
        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
        
        if pChar and pHum and pHum.Health > 0 and pRoot then
            local distMeters = ((pRoot.Position - hrp.Position).Magnitude) / 3.28
            local isEnemy = player.Team ~= LocalPlayer.Team or player.Team == nil
            
            if Settings.ESPEnabled and distMeters <= Settings.MaxDistance then
                if not Highlights[player] then
                    local hl = Instance.new("Highlight")
                    hl.Name = "PastaHighlight"
                    hl.Parent = pChar
                    Highlights[player] = hl
                end
                
                local hl = Highlights[player]
                hl.FillColor = isEnemy and Settings.ColorEnemy or Settings.ColorAlly
                hl.OutlineColor = Color3.fromRGB(255, 255, 255)
                hl.FillTransparency = 0.5
                hl.OutlineTransparency = 0.5
                hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            else
                if Highlights[player] then
                    Highlights[player]:Destroy()
                    Highlights[player] = nil
                end
            end
        else
            if Highlights[player] then
                Highlights[player]:Destroy()
                Highlights[player] = nil
            end
        end
    end
end)
