-- [[ LiquidGlass UI Library for Roblox ]]
-- Native Luau Implementation

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local LiquidGlass = {
    Flags = {},
    Keybinds = {},
    Configs = {}
}

-- Создание защищенного контейнера GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiquidGlass_Runtime"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

pcall(function()
    if syn and syn.protect_gui then
        syn.protect_gui(ScreenGui)
        ScreenGui.Parent = CoreGui
    elseif gethui then
        ScreenGui.Parent = gethui()
    else
        ScreenGui.Parent = CoreGui
    end
end)
if not ScreenGui.Parent then 
    ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") 
end

-- Вспомогательная функция для эффекта Liquid Glass (Спекулярная обводка и градиент)
local function applyGlassSpecular(instance, cornerRadius, strokeTransparency)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = cornerRadius or UDim.new(0, 16)
    corner.Parent = instance

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Color = Color3.fromRGB(255, 255, 255)
    stroke.Transparency = strokeTransparency or 0.45
    stroke.Parent = instance

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Rotation = 45
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.4, Color3.fromRGB(180, 180, 200)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(40, 40, 55))
    })
    strokeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.2),
        NumberSequenceKeypoint.new(0.5, 0.6),
        NumberSequenceKeypoint.new(1, 0.95)
    })
    strokeGradient.Parent = stroke

    local innerGlow = Instance.new("UIGradient")
    innerGlow.Rotation = 90
    innerGlow.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.2, Color3.fromRGB(150, 150, 170)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 26))
    })
    innerGlow.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.3, 0.45),
        NumberSequenceKeypoint.new(1, 0.65)
    })
    innerGlow.Parent = instance

    return stroke
end

local function tween(object, properties, duration, style, direction)
    local info = TweenInfo.new(duration or 0.35, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

local function makeDraggable(frame, handle)
    local dragging = false
    local dragInput, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            tween(frame, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.06, Enum.EasingStyle.Linear)
        end
    end)
end

-- Воспроизведение звуков (Roblox Sound System)
local function playSound(soundId)
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = 0.5
    s.Parent = ScreenGui
    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- Уведомления
function LiquidGlass:Notify(title, desc)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 260, 0, 55)
    toast.Position = UDim2.new(1, 20, 1, -75)
    toast.BackgroundColor3 = Color3.fromRGB(20, 20, 26)
    toast.BackgroundTransparency = 0.35
    toast.Parent = ScreenGui
    applyGlassSpecular(toast, UDim.new(0, 14), 0.4)

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -20, 0, 18)
    tLbl.Position = UDim2.new(0, 10, 0, 8)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Color3.fromRGB(245, 245, 247)
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = toast

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1, -20, 0, 16)
    dLbl.Position = UDim2.new(0, 10, 0, 28)
    dLbl.BackgroundTransparency = 1
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.Text = desc
    dLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
    dLbl.TextSize = 11
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.Parent = toast

    tween(toast, {Position = UDim2.new(1, -280, 1, -75)}, 0.4, Enum.EasingStyle.Back)
    task.delay(3, function()
        local out = tween(toast, {Position = UDim2.new(1, 20, 1, -75), BackgroundTransparency = 1}, 0.35)
        out.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- Главное окно
function LiquidGlass:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "LiquidGlass UI"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

    local Window = { Tabs = {}, Minimized = false }

    -- Main Container
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 720, 0, 480)
    MainFrame.Position = UDim2.new(0.5, -360, 0.5, -240)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BackgroundTransparency = 0.45
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    applyGlassSpecular(MainFrame, UDim.new(0, 24), 0.35)

    -- Dynamic Island Frame
    local Island = Instance.new("Frame")
    Island.Name = "DynamicIsland"
    Island.Size = UDim2.new(0, 215, 0, 36)
    Island.Position = UDim2.new(0.5, -107, 0, 14)
    Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Island.Visible = false
    Island.Parent = ScreenGui
    applyGlassSpecular(Island, UDim.new(1, 0), 0.2)
    makeDraggable(Island, Island)

    local IslandAvatar = Instance.new("ImageLabel")
    IslandAvatar.Size = UDim2.new(0, 22, 0, 22)
    IslandAvatar.Position = UDim2.new(0, 28, 0.5, -11)
    IslandAvatar.BackgroundTransparency = 1
    IslandAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    IslandAvatar.Parent = Island
    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(1, 0)
    avCorner.Parent = IslandAvatar

    local IslandUser = Instance.new("TextLabel")
    IslandUser.Size = UDim2.new(0, 100, 1, 0)
    IslandUser.Position = UDim2.new(0, 56, 0, 0)
    IslandUser.BackgroundTransparency = 1
    IslandUser.Font = Enum.Font.GothamBold
    IslandUser.Text = "@" .. LocalPlayer.Name
    IslandUser.TextColor3 = Color3.fromRGB(245, 245, 247)
    IslandUser.TextSize = 11
    IslandUser.TextXAlignment = Enum.TextXAlignment.Left
    IslandUser.Parent = Island

    -- TopBar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame
    makeDraggable(MainFrame, TopBar)

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 12, 0, 12)
    MinimizeBtn.Position = UDim2.new(0, 36, 0, 19)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(254, 188, 46)
    MinimizeBtn.Text = ""
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.Parent = TopBar
    applyGlassSpecular(MinimizeBtn, UDim.new(1, 0), 0.2)

    local TitleLbl = Instance.new("TextLabel")
    TitleLbl.Size = UDim2.new(0, 300, 1, 0)
    TitleLbl.Position = UDim2.new(0, 70, 0, 0)
    TitleLbl.BackgroundTransparency = 1
    TitleLbl.Font = Enum.Font.GothamBold
    TitleLbl.Text = TitleText
    TitleLbl.TextColor3 = Color3.fromRGB(245, 245, 247)
    TitleLbl.TextSize = 14
    TitleLbl.TextXAlignment = Enum.TextXAlignment.Left
    TitleLbl.Parent = TopBar

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 190, 1, -66)
    Sidebar.Position = UDim2.new(0, 14, 0, 52)
    Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Sidebar.BackgroundTransparency = 0.5
    Sidebar.Parent = MainFrame
    applyGlassSpecular(Sidebar, UDim.new(0, 18), 0.4)

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Size = UDim2.new(1, -12, 1, -16)
    TabContainer.Position = UDim2.new(0, 6, 0, 8)
    TabContainer.BackgroundTransparency = 1
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = Sidebar
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = TabContainer

    -- Page Container
    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -230, 1, -66)
    PageContainer.Position = UDim2.new(0, 216, 0, 52)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    -- Механика сворачивания в Dynamic Island
    local function toggleWindow(minimize)
        if minimize == nil then minimize = not Window.Minimized end
        Window.Minimized = minimize

        if Window.Minimized then
            Island.Visible = true
            tween(MainFrame, {
                Position = UDim2.new(0.5, -360, 0, -500),
                BackgroundTransparency = 1
            }, 0.45, Enum.EasingStyle.Quart)
            tween(Island, {Size = UDim2.new(0, 215, 0, 36)}, 0.4, Enum.EasingStyle.Back)
        else
            tween(MainFrame, {
                Position = UDim2.new(0.5, -360, 0.5, -240),
                BackgroundTransparency = 0.45
            }, 0.45, Enum.EasingStyle.Quart)
            task.delay(0.2, function()
                if not Window.Minimized then Island.Visible = false end
            end)
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(function() toggleWindow(true) end)
    Island.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 then
            toggleWindow(false)
        end
    end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == ToggleKey then
            toggleWindow()
        end
    end)

    -- Tab Builder
    function Window:CreateTab(name)
        local Tab = {}
        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 2
        Page.Visible = false
        Page.Parent = PageContainer

        local pLayout = Instance.new("UIListLayout")
        pLayout.Padding = UDim.new(0, 10)
        pLayout.Parent = Page

        pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 15)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 34)
        TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.Text = "  " .. name
        TabBtn.TextColor3 = Color3.fromRGB(142, 142, 147)
        TabBtn.TextSize = 13
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = TabBtn

        local function activate()
            for _, t in pairs(Window.Tabs) do
                tween(t.Btn, {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(142, 142, 147)}, 0.2)
                t.Page.Visible = false
            end
            Page.Visible = true
            tween(TabBtn, {BackgroundTransparency = 0.7, TextColor3 = Color3.fromRGB(245, 245, 247)}, 0.2)
        end

        TabBtn.MouseButton1Click:Connect(activate)
        Tab.Btn = TabBtn
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        -- Переключатель (Toggle)
        function Tab:CreateToggle(tglConfig)
            tglConfig = tglConfig or {}
            local Title = tglConfig.Name or "Toggle"
            local State = tglConfig.Default or false
            local Callback = tglConfig.Callback or function() end

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -6, 0, 44)
            Frame.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
            Frame.BackgroundTransparency = 0.5
            Frame.Parent = Page
            applyGlassSpecular(Frame, UDim.new(0, 12), 0.5)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -60, 1, 0)
            Lbl.Position = UDim2.new(0, 14, 0, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Color3.fromRGB(245, 245, 247)
            Lbl.TextSize = 13
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Frame

            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 42, 0, 22)
            Switch.Position = UDim2.new(1, -54, 0.5, -11)
            Switch.BackgroundColor3 = State and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 70)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            Switch.Parent = Frame
            applyGlassSpecular(Switch, UDim.new(1, 0), 0.3)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 18, 0, 18)
            Knob.Position = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Parent = Switch
            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = UDim.new(1, 0)
            kCorner.Parent = Knob

            Switch.MouseButton1Click:Connect(function()
                State = not State
                local targetPos = State and UDim2.new(1, -20, 0.5, -9) or UDim2.new(0, 2, 0.5, -9)
                local targetColor = State and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 70)
                tween(Knob, {Position = targetPos}, 0.25, Enum.EasingStyle.Quart)
                tween(Switch, {BackgroundColor3 = targetColor}, 0.25)
                pcall(Callback, State)
            end)
        end

        return Tab
    end

    return Window
end

return LiquidGlass
