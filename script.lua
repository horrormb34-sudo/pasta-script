-- language: Luau (Roblox), executor compatible
-- *PASTA: Restored Drawing ESP*

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Settings = {
    ESPEnabled = true,
    MaxDistance = 1000, -- Метры
    ColorEnemy = Color3.fromRGB(255, 50, 50),
    ColorAlly = Color3.fromRGB(0, 255, 170),
    MenuOpen = true,
    Keybind = Enum.KeyCode.RightShift,
}

local ESP_Objects = {}

-- ==========================================
-- UI
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "PastaUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 20, 25)
MainFrame.Position = UDim2.new(0, 20, 0, 100)
MainFrame.Size = UDim2.new(0, 280, 0, 120)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 12)

local Title = Instance.new("TextLabel", MainFrame)
Title.BackgroundTransparency = 1
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Font = Enum.Font.GothamBold
Title.Text = "🌸 PASTA"
Title.TextColor3 = Color3.fromRGB(255, 105, 180)
Title.TextSize = 16

local function CreateToggle(parent, name, posY, defaultState, callback)
    local Btn = Instance.new("TextButton", parent)
    Btn.BackgroundColor3 = Color3.fromRGB(45, 25, 30)
    Btn.Position = UDim2.new(0, 10, 0, posY)
    Btn.Size = UDim2.new(1, -20, 0, 30)
    Btn.Text = ""
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
    Ind.BackgroundColor3 = defaultState and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(70, 50, 55)
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
        Ind.BackgroundColor3 = state and Color3.fromRGB(255, 105, 180) or Color3.fromRGB(70, 50, 55)
        Dot:TweenPosition(state and UDim2.new(1, -12, 0, 2) or UDim2.new(0, 2, 0, 2), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        callback(state)
    end)
end

CreateToggle(MainFrame, "Wallhack (ESP)", 50, true, function(s) Settings.ESPEnabled = s end)

local CloseBtn = Instance.new("TextButton", MainFrame)
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 51, 102)
CloseBtn.Position = UDim2.new(0, 10, 0, 90)
CloseBtn.Size = UDim2.new(1, -20, 0, 25)
CloseBtn.Text = "CLOSE"
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.TextSize = 12
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
Instance.new("UICorner", CloseBtn).CornerRadius = UDim.new(0, 6)

CloseBtn.MouseButton1Click:Connect(function()
    for _, esp in pairs(ESP_Objects) do
        if esp.box then for _, l in pairs(esp.box) do l:Remove() end end
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
-- ЛОГИКА (ОТРИСОВКА ЛИНИЙ)
-- ==========================================
RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    for _, player in pairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        
        local pChar = player.Character
        local pHum = pChar and pChar:FindFirstChild("Humanoid")
        local pRoot = pChar and pChar:FindFirstChild("HumanoidRootPart")
        
        -- Если игрок умер или вышел, удаляем линии
        if not pChar or not pHum or pHum.Health <= 0 or not pRoot then
            if ESP_Objects[player] then
                for _, l in pairs(ESP_Objects[player]) do l:Remove() end
                ESP_Objects[player] = nil
            end
            continue
        end
        
        local distMeters = math.floor(((pRoot.Position - hrp.Position).Magnitude) / 3.28)
        
        -- Если включено и в дистанции
        if Settings.ESPEnabled and distMeters <= Settings.MaxDistance then
            -- Создаем 4 линии (бокс) один раз
            if not ESP_Objects[player] then
                ESP_Objects[player] = {}
                for i = 1, 4 do
                    local line = Drawing.new("Line")
                    line.Thickness = 2
                    line.Transparency = 1
                    line.Visible = false
                    table.insert(ESP_Objects[player], line)
                end
            end
            
            local lines = ESP_Objects[player]
            local pos, onScreen = Camera:WorldToViewportPoint(pRoot.Position)
            
            if onScreen then
                local height = 100 / pos.Z * 5
                local width = height / 2
                local x, y = pos.X, pos.Y
                
                -- Цвет
                local isEnemy = player.Team ~= LocalPlayer.Team or player.Team == nil
                local color = isEnemy and Settings.ColorEnemy or Settings.ColorAlly
                
                -- Координаты
                lines[1].From = Vector2.new(x - width, y - height)
                lines[1].To = Vector2.new(x + width, y - height)
                
                lines[2].From = Vector2.new(x + width, y - height)
                lines[2].To = Vector2.new(x + width, y + height)
                
                lines[3].From = Vector2.new(x + width, y + height)
                lines[3].To = Vector2.new(x - width, y + height)
                
                lines[4].From = Vector2.new(x - width, y + height)
                lines[4].To = Vector2.new(x - width, y - height)
                
                -- Включаем и красим
                for i = 1, 4 do
                    lines[i].Color = color
                    lines[i].Visible = true
                end
            else
                -- Если игрок за экраном, выключаем
                for i = 1, 4 do
                    lines[i].Visible = false
                end
            end
        else
            -- Если далеко или выключено
            if ESP_Objects[player] then
                for i = 1, 4 do
                    ESP_Objects[player][i].Visible = false
                end
            end
        end
    end
end)
