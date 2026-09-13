-- [[ LiquidGlass UI Library (1:1 HTML to Roblox Luau Port) ]]
-- Fully functional, Standalone Script Engine

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer

local LiquidGlass = {
    Flags = {},
    Keybinds = {
        ["Infinite Jump"] = { Key = Enum.KeyCode.Space, Toggle = nil },
        ["Noclip Mode"] = { Key = Enum.KeyCode.V, Toggle = nil },
        ["Aimbot Assistant"] = { Key = Enum.UserInputType.MouseButton2, Toggle = nil },
        ["Triggerbot"] = { Key = nil, Toggle = nil }
    },
    CurrentListening = nil,
    ActiveFeatureCount = 3
}

-- Инициализация защищенного контейнера GUI
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
if not ScreenGui.Parent then ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- Иконки Lucide (Roblox Asset IDs)
local Icons = {
    home = "rbxassetid://10723407389",
    swords = "rbxassetid://10734975486",
    palette = "rbxassetid://10734950309",
    folder = "rbxassetid://10723387563",
    appwindow = "rbxassetid://10734934585",
    sliders = "rbxassetid://10734949856",
    search = "rbxassetid://10734977012",
    check = "rbxassetid://10709790644",
    chevron = "rbxassetid://10709790948",
    alert = "rbxassetid://10709752996",
    keyboard = "rbxassetid://10734934585",
    activity = "rbxassetid://10709768644",
    play = "rbxassetid://10734923549",
    save = "rbxassetid://10723424838",
    trash = "rbxassetid://10747384394",
    grip = "rbxassetid://10709791437",
    bell = "rbxassetid://10709753149",
    pipette = "rbxassetid://10734950309"
}

-- Утилиты анимации и Liquid Glass
local function tween(object, properties, duration, style, direction)
    local info = TweenInfo.new(duration or 0.35, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local anim = TweenService:Create(object, info, properties)
    anim:Play()
    return anim
end

local function applyGlass(instance, cornerRadius, strokeTransparency)
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

    return stroke
end

-- Универсальная функция перетаскивания (только за заголовок)
local function makeDraggable(frame, handle, onDragStart, onDragEnd)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = frame.Position
            if onDragStart then onDragStart() end

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if onDragEnd then onDragEnd(hasMoved) end
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
            if math.abs(delta.X) > 4 or math.abs(delta.Y) > 4 then
                hasMoved = true
            end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- Универсальная функция растягивания (только за нижний правый угол)
local function makeResizable(frame, handle, minWidth, minHeight)
    minWidth = minWidth or 170
    minHeight = minHeight or 100
    local resizing, dragInput, dragStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            dragStart = input.Position
            startSize = frame.AbsoluteSize

            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    resizing = false
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
        if input == dragInput and resizing then
            local delta = input.Position - dragStart
            local newW = math.max(minWidth, startSize.X + delta.X)
            local newH = math.max(minHeight, startSize.Y + delta.Y)
            frame.Size = UDim2.new(0, newW, 0, newH)
        end
    end)
end

-- Звуковой движок (5-Bell ON, 3-Bell OFF, Chime, Intro)
local function playSound(type)
    local s = Instance.new("Sound")
    s.Volume = 0.5
    s.Parent = ScreenGui

    if type == "5Bell" then
        s.SoundId = "rbxassetid://9114223175"
        s.PlaybackSpeed = 1.05
    elseif type == "3Bell" then
        s.SoundId = "rbxassetid://9114223408"
        s.PlaybackSpeed = 0.95
    elseif type == "Intro" then
        s.SoundId = "rbxassetid://9114223686"
        s.Volume = 0.7
    elseif type == "Tap" then
        s.SoundId = "rbxassetid://9119713951"
    elseif type == "Island" then
        s.SoundId = "rbxassetid://6895079853"
        s.PlaybackSpeed = 1.3
    end

    s:Play()
    s.Ended:Connect(function() s:Destroy() end)
end

-- ================= УВЕДОМЛЕНИЯ =================
function LiquidGlass:Notify(title, desc)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 280, 0, 56)
    toast.Position = UDim2.new(1, 20, 1, -76)
    toast.BackgroundColor3 = Color3.fromRGB(25, 25, 34)
    toast.BackgroundTransparency = 0.3
    toast.ClipsDescendants = true
    toast.Parent = ScreenGui
    applyGlass(toast, UDim.new(0, 18), 0.35)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 12, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = Icons.bell
    icon.ImageColor3 = Color3.fromRGB(10, 132, 255)
    icon.Parent = toast

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -40, 0, 18)
    tLbl.Position = UDim2.new(0, 36, 0, 8)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Color3.fromRGB(245, 245, 247)
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.Parent = toast

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1, -40, 0, 16)
    dLbl.Position = UDim2.new(0, 36, 0, 28)
    dLbl.BackgroundTransparency = 1
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.Text = desc
    dLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
    dLbl.TextSize = 11
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.Parent = toast

    tween(toast, {Position = UDim2.new(1, -300, 1, -76)}, 0.45, Enum.EasingStyle.Back)
    task.delay(3, function()
        local out = tween(toast, {Position = UDim2.new(1, 20, 1, -76), BackgroundTransparency = 1}, 0.35)
        out.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- ================= ИНТРО APPLE "HELLO" =================
local function playBootIntro()
    local bootScreen = Instance.new("Frame")
    bootScreen.Size = UDim2.new(1, 0, 1, 0)
    bootScreen.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    bootScreen.BackgroundTransparency = 0.05
    bootScreen.ZIndex = 100
    bootScreen.Parent = ScreenGui

    local helloLabel = Instance.new("TextLabel")
    helloLabel.Size = UDim2.new(0, 400, 0, 120)
    helloLabel.Position = UDim2.new(0.5, -200, 0.5, -60)
    helloLabel.BackgroundTransparency = 1
    helloLabel.Font = Enum.Font.FredokaOne
    helloLabel.Text = "hello"
    helloLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    helloLabel.TextSize = 72
    helloLabel.TextTransparency = 1
    helloLabel.ZIndex = 101
    helloLabel.Parent = bootScreen

    playSound("Intro")
    tween(helloLabel, {TextTransparency = 0}, 0.8)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        tween(bootScreen, {BackgroundTransparency = 1}, 0.5)
        tween(helloLabel, {TextTransparency = 1, TextSize = 85}, 0.5).Completed:Connect(function()
            bootScreen:Destroy()
        end)
    end

    bootScreen.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    task.delay(1.9, dismiss)
end
task.spawn(playBootIntro)

-- ================= ДИАЛОГОВОЕ ОКНО ПРЕДУПРЕЖДЕНИЯ =================
local function openConfirmDialog(title, desc, onConfirm)
    playSound("3Bell")
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.ZIndex = 50
    backdrop.Parent = ScreenGui

    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 360, 0, 200)
    modal.Position = UDim2.new(0.5, -180, 0.5, -100)
    modal.BackgroundColor3 = Color3.fromRGB(22, 22, 30)
    modal.BackgroundTransparency = 0.35
    modal.ClipsDescendants = true
    modal.ZIndex = 51
    modal.Parent = backdrop
    applyGlass(modal, UDim.new(0, 26), 0.3)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 32, 0, 32)
    icon.Position = UDim2.new(0.5, -16, 0, 16)
    icon.BackgroundTransparency = 1
    icon.Image = Icons.alert
    icon.ImageColor3 = Color3.fromRGB(255, 69, 58)
    icon.ZIndex = 52
    icon.Parent = modal

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -32, 0, 20)
    tLbl.Position = UDim2.new(0, 16, 0, 56)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Color3.fromRGB(245, 245, 247)
    tLbl.TextSize = 16
    tLbl.ZIndex = 52
    tLbl.Parent = modal

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1, -32, 0, 36)
    dLbl.Position = UDim2.new(0, 16, 0, 80)
    dLbl.BackgroundTransparency = 1
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.Text = desc
    dLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
    dLbl.TextSize = 12
    dLbl.TextWrapped = true
    dLbl.ZIndex = 52
    dLbl.Parent = modal

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.5, -22, 0, 36)
    cancelBtn.Position = UDim2.new(0, 16, 1, -50)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 52)
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Text = "Cancel"
    cancelBtn.TextColor3 = Color3.fromRGB(245, 245, 247)
    cancelBtn.TextSize = 13
    cancelBtn.ZIndex = 52
    cancelBtn.Parent = modal
    applyGlass(cancelBtn, UDim.new(0, 12), 0.4)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0.5, -22, 0, 36)
    confirmBtn.Position = UDim2.new(0.5, 6, 1, -50)
    confirmBtn.BackgroundColor3 = Color3.fromRGB(255, 69, 58)
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.Text = "Confirm"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.TextSize = 13
    confirmBtn.ZIndex = 52
    confirmBtn.Parent = modal
    applyGlass(confirmBtn, UDim.new(0, 12), 0.3)

    cancelBtn.MouseButton1Click:Connect(function()
        playSound("Tap")
        backdrop:Destroy()
    end)

    confirmBtn.MouseButton1Click:Connect(function()
        playSound("Tap")
        backdrop:Destroy()
        if onConfirm then onConfirm() end
    end)
end

-- ================= СОЗДАНИЕ ГЛАВНОГО ОКНА =================
function LiquidGlass:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "LiquidGlass UI"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

    local Window = { Tabs = {}, ActiveTab = nil, Minimized = false }

    -- Главный контейнер
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 840, 0, 550)
    MainFrame.Position = UDim2.new(0.5, -420, 0.5, -275)
    MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
    MainFrame.BackgroundTransparency = 0.45
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui
    applyGlass(MainFrame, UDim.new(0, 28), 0.35)

    -- Dynamic Island (Перетаскиваемый)
    local Island = Instance.new("Frame")
    Island.Name = "DynamicIsland"
    Island.Size = UDim2.new(0, 215, 0, 36)
    Island.Position = UDim2.new(0.5, -107, 0, 14)
    Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Island.Visible = false
    Island.Parent = ScreenGui
    applyGlass(Island, UDim.new(1, 0), 0.25)

    local IslandAvatar = Instance.new("ImageLabel")
    IslandAvatar.Size = UDim2.new(0, 22, 0, 22)
    IslandAvatar.Position = UDim2.new(0, 26, 0.5, -11)
    IslandAvatar.BackgroundTransparency = 1
    IslandAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    IslandAvatar.Parent = Island
    local avCorner = Instance.new("UICorner")
    avCorner.CornerRadius = UDim.new(1, 0)
    avCorner.Parent = IslandAvatar

    local IslandUser = Instance.new("TextLabel")
    IslandUser.Size = UDim2.new(0, 85, 0, 14)
    IslandUser.Position = UDim2.new(0, 54, 0, 5)
    IslandUser.BackgroundTransparency = 1
    IslandUser.Font = Enum.Font.GothamBold
    IslandUser.Text = "@" .. LocalPlayer.Name
    IslandUser.TextColor3 = Color3.fromRGB(245, 245, 247)
    IslandUser.TextSize = 11
    IslandUser.TextXAlignment = Enum.TextXAlignment.Left
    IslandUser.Parent = Island

    local IslandStatus = Instance.new("TextLabel")
    IslandStatus.Size = UDim2.new(0, 85, 0, 12)
    IslandStatus.Position = UDim2.new(0, 54, 0, 19)
    IslandStatus.BackgroundTransparency = 1
    IslandStatus.Font = Enum.Font.GothamMedium
    IslandStatus.Text = "● " .. tostring(LiquidGlass.ActiveFeatureCount) .. " Active"
    IslandStatus.TextColor3 = Color3.fromRGB(48, 209, 88)
    IslandStatus.TextSize = 9
    IslandStatus.TextXAlignment = Enum.TextXAlignment.Left
    IslandStatus.Parent = Island

    -- Анимация звуковой волны в Dynamic Island
    local waveContainer = Instance.new("Frame")
    waveContainer.Size = UDim2.new(0, 16, 0, 14)
    waveContainer.Position = UDim2.new(1, -26, 0.5, -7)
    waveContainer.BackgroundTransparency = 1
    waveContainer.Parent = Island

    local wb1 = Instance.new("Frame")
    wb1.Size = UDim2.new(0, 2, 0, 6)
    wb1.Position = UDim2.new(0, 0, 0.5, -3)
    wb1.BackgroundColor3 = Color3.fromRGB(48, 209, 88)
    wb1.Parent = waveContainer

    local wb2 = Instance.new("Frame")
    wb2.Size = UDim2.new(0, 2, 0, 12)
    wb2.Position = UDim2.new(0, 5, 0.5, -6)
    wb2.BackgroundColor3 = Color3.fromRGB(48, 209, 88)
    wb2.Parent = waveContainer

    local wb3 = Instance.new("Frame")
    wb3.Size = UDim2.new(0, 2, 0, 8)
    wb3.Position = UDim2.new(0, 10, 0.5, -4)
    wb3.BackgroundColor3 = Color3.fromRGB(48, 209, 88)
    wb3.Parent = waveContainer

    task.spawn(function()
        while true do
            tween(wb1, {Size = UDim2.new(0, 2, 0, math.random(4, 12))}, 0.25)
            tween(wb2, {Size = UDim2.new(0, 2, 0, math.random(4, 14))}, 0.25)
            tween(wb3, {Size = UDim2.new(0, 2, 0, math.random(4, 10))}, 0.25)
            task.wait(0.25)
        end
    end)

    -- Перетаскивание и клик Dynamic Island
    makeDraggable(Island, Island, nil, function(hasMoved)
        if not hasMoved then
            Window:Toggle(false)
        end
    end)

    -- Topbar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 54)
    TopBar.BackgroundTransparency = 1
    TopBar.Parent = MainFrame
    makeDraggable(MainFrame, TopBar)

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 12, 0, 12)
    MinimizeBtn.Position = UDim2.new(0, 36, 0, 21)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(254, 188, 46)
    MinimizeBtn.Text = ""
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.Parent = TopBar
    applyGlass(MinimizeBtn, UDim.new(1, 0), 0.2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(0, 400, 1, 0)
    TitleLabel.Position = UDim2.new(0, 68, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.GothamBold
    TitleLabel.Text = TitleText .. "  •  Press [Right Ctrl] to Toggle"
    TitleLabel.TextColor3 = Color3.fromRGB(245, 245, 247)
    TitleLabel.TextSize = 13
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.Parent = TopBar

    -- Sidebar
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 215, 1, -70)
    Sidebar.Position = UDim2.new(0, 14, 0, 54)
    Sidebar.BackgroundColor3 = Color3.fromRGB(12, 12, 18)
    Sidebar.BackgroundTransparency = 0.5
    Sidebar.Parent = MainFrame
    applyGlass(Sidebar, UDim.new(0, 20), 0.4)

    -- Live Search Box
    local SearchBox = Instance.new("TextBox")
    SearchBox.Size = UDim2.new(1, -16, 0, 34)
    SearchBox.Position = UDim2.new(0, 8, 0, 8)
    SearchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    SearchBox.BackgroundTransparency = 0.6
    SearchBox.Font = Enum.Font.GothamMedium
    SearchBox.PlaceholderText = "Search features..."
    SearchBox.PlaceholderColor3 = Color3.fromRGB(142, 142, 147)
    SearchBox.Text = ""
    SearchBox.TextColor3 = Color3.fromRGB(245, 245, 247)
    SearchBox.TextSize = 12
    SearchBox.Parent = Sidebar
    applyGlass(SearchBox, UDim.new(0, 12), 0.4)

    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(1, -12, 1, -104)
    TabScroll.Position = UDim2.new(0, 6, 0, 48)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 0
    TabScroll.Parent = Sidebar
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = TabScroll

    -- Profile Card
    local UserCard = Instance.new("Frame")
    UserCard.Size = UDim2.new(1, -12, 0, 46)
    UserCard.Position = UDim2.new(0, 6, 1, -50)
    UserCard.BackgroundColor3 = Color3.fromRGB(30, 30, 42)
    UserCard.BackgroundTransparency = 0.6
    UserCard.Parent = Sidebar
    applyGlass(UserCard, UDim.new(0, 14), 0.5)

    local UserAvatar = Instance.new("ImageLabel")
    UserAvatar.Size = UDim2.new(0, 30, 0, 30)
    UserAvatar.Position = UDim2.new(0, 8, 0.5, -15)
    UserAvatar.BackgroundTransparency = 1
    UserAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    UserAvatar.Parent = UserCard
    local uavCorner = Instance.new("UICorner")
    uavCorner.CornerRadius = UDim.new(1, 0)
    uavCorner.Parent = UserAvatar

    local UserName = Instance.new("TextLabel")
    UserName.Size = UDim2.new(1, -50, 0, 14)
    UserName.Position = UDim2.new(0, 46, 0, 8)
    UserName.BackgroundTransparency = 1
    UserName.Font = Enum.Font.GothamBold
    UserName.Text = LocalPlayer.DisplayName
    UserName.TextColor3 = Color3.fromRGB(245, 245, 247)
    UserName.TextSize = 11.5
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.Parent = UserCard

    local UserTag = Instance.new("TextLabel")
    UserTag.Size = UDim2.new(1, -50, 0, 12)
    UserTag.Position = UDim2.new(0, 46, 0, 24)
    UserTag.BackgroundTransparency = 1
    UserTag.Font = Enum.Font.GothamMedium
    UserTag.Text = "@" .. LocalPlayer.Name
    UserTag.TextColor3 = Color3.fromRGB(142, 142, 147)
    UserTag.TextSize = 9.5
    UserTag.TextXAlignment = Enum.TextXAlignment.Left
    UserTag.Parent = UserCard

    -- Page Container
    local PageContainer = Instance.new("Frame")
    PageContainer.Size = UDim2.new(1, -255, 1, -70)
    PageContainer.Position = UDim2.new(0, 241, 0, 54)
    PageContainer.BackgroundTransparency = 1
    PageContainer.Parent = MainFrame

    -- Механика Сворачивания / Разворачивания
    function Window:Toggle(minimize)
        if minimize == nil then minimize = not Window.Minimized end
        Window.Minimized = minimize

        if Window.Minimized then
            playSound("Island")
            Island.Visible = true
            tween(MainFrame, {Position = UDim2.new(0.5, -420, 0, -600), BackgroundTransparency = 1}, 0.5)
            tween(Island, {Size = UDim2.new(0, 215, 0, 36)}, 0.45, Enum.EasingStyle.Back)
        else
            playSound("Island")
            tween(MainFrame, {Position = UDim2.new(0.5, -420, 0.5, -275), BackgroundTransparency = 0.45}, 0.5)
            task.delay(0.15, function()
                if not Window.Minimized then Island.Visible = false end
            end)
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(function() Window:Toggle(true) end)

    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == ToggleKey then
            Window:Toggle()
        end
    end)

    -- Live Поиск по компонентам
    SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchBox.Text:lower()
        for _, tab in pairs(Window.Tabs) do
            for _, item in pairs(tab.Elements) do
                if item.Frame and item.Name then
                    if query == "" or item.Name:lower():find(query) then
                        item.Frame.Visible = true
                    else
                        item.Frame.Visible = false
                    end
                end
            end
        end
    end)

    -- ================= ТАБЫ =================
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local Name = tabConfig.Name or "Tab"
        local Icon = tabConfig.Icon or Icons.home

        local Tab = { Elements = {} }

        local Page = Instance.new("ScrollingFrame")
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(140, 140, 160)
        Page.Visible = false
        Page.Parent = PageContainer

        local pLayout = Instance.new("UIListLayout")
        pLayout.Padding = UDim.new(0, 10)
        pLayout.Parent = Page
        pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 20)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Font = Enum.Font.GothamMedium
        TabBtn.Text = "      " .. Name
        TabBtn.TextColor3 = Color3.fromRGB(142, 142, 147)
        TabBtn.TextSize = 12.5
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabScroll
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 12)
        btnCorner.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 10, 0.5, -8)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = Icon
        TabIcon.ImageColor3 = Color3.fromRGB(142, 142, 147)
        TabIcon.Parent = TabBtn

        local function activate()
            playSound("Tap")
            for _, t in pairs(Window.Tabs) do
                tween(t.Btn, {BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(142, 142, 147)}, 0.2)
                tween(t.Icon, {ImageColor3 = Color3.fromRGB(142, 142, 147)}, 0.2)
                t.Page.Visible = false
            end
            Page.Visible = true
            tween(TabBtn, {BackgroundTransparency = 0.6, TextColor3 = Color3.fromRGB(245, 245, 247)}, 0.2)
            tween(TabIcon, {ImageColor3 = Color3.fromRGB(245, 245, 247)}, 0.2)
            Window.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(activate)
        Tab.Btn = TabBtn
        Tab.Icon = TabIcon
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        -- Секция
        function Tab:CreateSection(text)
            local SecLbl = Instance.new("TextLabel")
            SecLbl.Size = UDim2.new(1, 0, 0, 20)
            SecLbl.BackgroundTransparency = 1
            SecLbl.Font = Enum.Font.GothamBold
            SecLbl.Text = string.upper(text)
            SecLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
            SecLbl.TextSize = 11
            SecLbl.TextXAlignment = Enum.TextXAlignment.Left
            SecLbl.Parent = Page
        end

        -- Toggle с Кейбиндом
        function Tab:CreateToggle(tglConfig)
            tglConfig = tglConfig or {}
            local Title = tglConfig.Name or "Toggle"
            local Desc = tglConfig.Description or ""
            local State = tglConfig.Default or false
            local BindKey = tglConfig.Keybind
            local Flag = tglConfig.Flag
            local Callback = tglConfig.Callback or function() end

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -6, 0, 46)
            Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Frame.BackgroundTransparency = 0.55
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 16), 0.5)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -120, 0, 18)
            Lbl.Position = UDim2.new(0, 14, 0, Desc ~= "" and 6 or 14)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Color3.fromRGB(245, 245, 247)
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Frame

            if Desc ~= "" then
                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, -120, 0, 14)
                dLbl.Position = UDim2.new(0, 14, 0, 24)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamMedium
                dLbl.Text = Desc
                dLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
                dLbl.TextSize = 11
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.Parent = Frame
            end

            -- Keybind Button
            local BindBtn = Instance.new("TextButton")
            BindBtn.Size = UDim2.new(0, 48, 0, 24)
            BindBtn.Position = UDim2.new(1, -112, 0.5, -12)
            BindBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.Text = BindKey and (typeof(BindKey) == "EnumItem" and BindKey.Name or tostring(BindKey)) or "NONE"
            BindBtn.TextColor3 = Color3.fromRGB(245, 245, 247)
            BindBtn.TextSize = 10.5
            BindBtn.Parent = Frame
            applyGlass(BindBtn, UDim.new(0, 8), 0.4)

            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -56, 0.5, -12)
            Switch.BackgroundColor3 = State and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 72)
            Switch.Text = ""
            Switch.AutoButtonColor = false
            Switch.Parent = Frame
            applyGlass(Switch, UDim.new(1, 0), 0.3)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 20, 0, 20)
            Knob.Position = State and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.Parent = Switch
            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = UDim.new(1, 0)
            kCorner.Parent = Knob

            local function setToggle(val)
                State = val
                if State then playSound("5Bell") else playSound("3Bell") end
                tween(Knob, {Position = State and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.25)
                tween(Switch, {BackgroundColor3 = State and Color3.fromRGB(10, 132, 255) or Color3.fromRGB(60, 60, 72)}, 0.25)
                LiquidGlass:Notify(Title, State and "Enabled" or "Disabled")
                if Flag then LiquidGlass.Flags[Flag] = State end
                pcall(Callback, State)
            end

            Switch.MouseButton1Click:Connect(function() setToggle(not State) end)

            -- Keybind Assignment
            BindBtn.MouseButton1Click:Connect(function()
                playSound("Tap")
                BindBtn.Text = "..."
                LiquidGlass.CurrentListening = {
                    Button = BindBtn,
                    Feature = Title,
                    SetCallback = function(key)
                        LiquidGlass.Keybinds[Title] = { Key = key, Toggle = setToggle, State = function() return State end }
                        BindBtn.Text = key and key.Name or "NONE"
                    end
                }
            end)

            if BindKey then
                LiquidGlass.Keybinds[Title] = { Key = BindKey, Toggle = setToggle, State = function() return State end }
            end

            table.insert(Tab.Elements, { Frame = Frame, Name = Title })
        end

        -- Liquid Slider
        function Tab:CreateSlider(sldConfig)
            sldConfig = sldConfig or {}
            local Title = sldConfig.Name or "Slider"
            local Min = sldConfig.Min or 0
            local Max = sldConfig.Max or 100
            local Def = sldConfig.Default or Min
            local Unit = sldConfig.Unit or ""
            local Flag = sldConfig.Flag
            local Callback = sldConfig.Callback or function() end

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -6, 0, 56)
            Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Frame.BackgroundTransparency = 0.55
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 16), 0.5)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -80, 0, 20)
            Lbl.Position = UDim2.new(0, 14, 0, 8)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Color3.fromRGB(245, 245, 247)
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Frame

            local Badge = Instance.new("TextLabel")
            Badge.Size = UDim2.new(0, 70, 0, 20)
            Badge.Position = UDim2.new(1, -84, 0, 8)
            Badge.BackgroundColor3 = Color3.fromRGB(40, 40, 56)
            Badge.Font = Enum.Font.GothamBold
            Badge.Text = tostring(Def) .. " " .. Unit
            Badge.TextColor3 = Color3.fromRGB(245, 245, 247)
            Badge.TextSize = 11
            Badge.Parent = Frame
            applyGlass(Badge, UDim.new(0, 8), 0.4)

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(1, -28, 0, 10)
            Track.Position = UDim2.new(0, 14, 0, 36)
            Track.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
            Track.BackgroundTransparency = 0.45
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.Parent = Frame
            applyGlass(Track, UDim.new(1, 0), 0.5)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((Def - Min) / (Max - Min), 0, 1, 0)
            Fill.BackgroundColor3 = Color3.fromRGB(10, 132, 255)
            Fill.Parent = Track
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(1, 0)
            fCorner.Parent = Fill

            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.new(0, 20, 0, 20)
            Thumb.Position = UDim2.new(1, -10, 0.5, -10)
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.Parent = Fill
            local tCorner = Instance.new("UICorner")
            tCorner.CornerRadius = UDim.new(1, 0)
            tCorner.Parent = Thumb

            local dragging = false
            local function updateSlider(input)
                local pct = math.clamp((input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                local val = math.floor(Min + (Max - Min) * pct)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                Badge.Text = tostring(val) .. " " .. Unit
                if Flag then LiquidGlass.Flags[Flag] = val end
                pcall(Callback, val)
            end

            Track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    updateSlider(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    updateSlider(input)
                end
            end)

            table.insert(Tab.Elements, { Frame = Frame, Name = Title })
        end

        -- Accordion с Sub-Settings (как в HTML Combat -> Aimbot)
        function Tab:CreateAimbotAccordion()
            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -6, 0, 46)
            Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Frame.BackgroundTransparency = 0.55
            Frame.ClipsDescendants = true
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 16), 0.5)

            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, 46)
            Header.BackgroundTransparency = 1
            Header.Text = ""
            Header.Parent = Frame

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -120, 0, 18)
            Lbl.Position = UDim2.new(0, 14, 0, 6)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = "Aimbot Assistant"
            Lbl.TextColor3 = Color3.fromRGB(245, 245, 247)
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Header

            local dLbl = Instance.new("TextLabel")
            dLbl.Size = UDim2.new(1, -120, 0, 14)
            dLbl.Position = UDim2.new(0, 14, 0, 24)
            dLbl.BackgroundTransparency = 1
            dLbl.Font = Enum.Font.GothamMedium
            dLbl.Text = "Target tracking with customizable parameters"
            dLbl.TextColor3 = Color3.fromRGB(142, 142, 147)
            dLbl.TextSize = 11
            dLbl.TextXAlignment = Enum.TextXAlignment.Left
            dLbl.Parent = Header

            local Chevron = Instance.new("ImageLabel")
            Chevron.Size = UDim2.new(0, 16, 0, 16)
            Chevron.Position = UDim2.new(1, -26, 0.5, -8)
            Chevron.BackgroundTransparency = 1
            Chevron.Image = Icons.chevron
            Chevron.ImageColor3 = Color3.fromRGB(142, 142, 147)
            Chevron.Parent = Header

            local isExpanded = false
            Header.MouseButton1Click:Connect(function()
                playSound("Tap")
                isExpanded = not isExpanded
                tween(Chevron, {Rotation = isExpanded and 180 or 0}, 0.3)
                tween(Frame, {Size = isExpanded and UDim2.new(1, -6, 0, 210) or UDim2.new(1, -6, 0, 46)}, 0.35)
            end)

            table.insert(Tab.Elements, { Frame = Frame, Name = "Aimbot Assistant" })
        end

        -- Button
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local Title = btnConfig.Name or "Button"
            local IsDestructive = btnConfig.Destructive or false
            local Callback = btnConfig.Callback or function() end

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -6, 0, 46)
            Frame.BackgroundColor3 = Color3.fromRGB(28, 28, 38)
            Frame.BackgroundTransparency = 0.55
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 16), 0.5)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -120, 1, 0)
            Lbl.Position = UDim2.new(0, 14, 0, 0)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Color3.fromRGB(245, 245, 247)
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.Parent = Frame

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 80, 0, 28)
            Btn.Position = UDim2.new(1, -94, 0.5, -14)
            Btn.BackgroundColor3 = IsDestructive and Color3.fromRGB(255, 69, 58) or Color3.fromRGB(40, 40, 56)
            Btn.Font = Enum.Font.GothamBold
            Btn.Text = "Execute"
            Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            Btn.TextSize = 12
            Btn.Parent = Frame
            applyGlass(Btn, UDim.new(0, 10), 0.4)

            Btn.MouseButton1Click:Connect(function()
                playSound("Tap")
                if IsDestructive then
                    openConfirmDialog(Title, "Are you sure you want to execute this action? It cannot be undone.", Callback)
                else
                    pcall(Callback)
                end
            end)

            table.insert(Tab.Elements, { Frame = Frame, Name = Title })
        end

        return Tab
    end

    return Window
end

-- ================= ПЛАВАЮЩИЕ ОКНА (KEYBINDS & TELEMETRY) =================
local KeybindsWin = Instance.new("Frame")
KeybindsWin.Size = UDim2.new(0, 220, 0, 140)
KeybindsWin.Position = UDim2.new(1, -260, 0, 120)
KeybindsWin.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
KeybindsWin.BackgroundTransparency = 0.45
KeybindsWin.ClipsDescendants = true
KeybindsWin.Parent = ScreenGui
applyGlass(KeybindsWin, UDim.new(0, 18), 0.35)

local kbHeader = Instance.new("Frame")
kbHeader.Size = UDim2.new(1, 0, 0, 36)
kbHeader.BackgroundTransparency = 1
kbHeader.Parent = KeybindsWin
makeDraggable(KeybindsWin, kbHeader)

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(1, -20, 1, 0)
kbTitle.Position = UDim2.new(0, 12, 0, 0)
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamBold
kbTitle.Text = "Keybinds"
kbTitle.TextColor3 = Color3.fromRGB(245, 245, 247)
kbTitle.TextSize = 12
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.Parent = kbHeader

local kbResizeGrip = Instance.new("ImageLabel")
kbResizeGrip.Size = UDim2.new(0, 14, 0, 14)
kbResizeGrip.Position = UDim2.new(1, -14, 1, -14)
kbResizeGrip.BackgroundTransparency = 1
kbResizeGrip.Image = Icons.grip
kbResizeGrip.Parent = KeybindsWin
makeResizable(KeybindsWin, kbResizeGrip, 180, 100)

-- Telemetry Window
local TelemetryWin = Instance.new("Frame")
TelemetryWin.Size = UDim2.new(0, 180, 0, 95)
TelemetryWin.Position = UDim2.new(0, 40, 1, -135)
TelemetryWin.BackgroundColor3 = Color3.fromRGB(18, 18, 24)
TelemetryWin.BackgroundTransparency = 0.45
TelemetryWin.ClipsDescendants = true
TelemetryWin.Parent = ScreenGui
applyGlass(TelemetryWin, UDim.new(0, 18), 0.35)

local telHeader = Instance.new("Frame")
telHeader.Size = UDim2.new(1, 0, 0, 30)
telHeader.BackgroundTransparency = 1
telHeader.Parent = TelemetryWin
makeDraggable(TelemetryWin, telHeader)

local telTitle = Instance.new("TextLabel")
telTitle.Size = UDim2.new(1, -20, 1, 0)
telTitle.Position = UDim2.new(0, 12, 0, 0)
telTitle.BackgroundTransparency = 1
telTitle.Font = Enum.Font.GothamBold
telTitle.Text = "Telemetry"
telTitle.TextColor3 = Color3.fromRGB(48, 209, 88)
telTitle.TextSize = 12
telTitle.TextXAlignment = Enum.TextXAlignment.Left
telTitle.Parent = telHeader

local fpsLbl = Instance.new("TextLabel")
fpsLbl.Size = UDim2.new(1, -24, 0, 18)
fpsLbl.Position = UDim2.new(0, 12, 0, 36)
fpsLbl.BackgroundTransparency = 1
fpsLbl.Font = Enum.Font.GothamMedium
fpsLbl.Text = "Frame Rate: 60 FPS"
fpsLbl.TextColor3 = Color3.fromRGB(245, 245, 247)
fpsLbl.TextSize = 11.5
fpsLbl.TextXAlignment = Enum.TextXAlignment.Left
fpsLbl.Parent = TelemetryWin

local pingLbl = Instance.new("TextLabel")
pingLbl.Size = UDim2.new(1, -24, 0, 18)
pingLbl.Position = UDim2.new(0, 12, 0, 58)
pingLbl.BackgroundTransparency = 1
pingLbl.Font = Enum.Font.GothamMedium
pingLbl.Text = "Latency: 20 ms"
pingLbl.TextColor3 = Color3.fromRGB(10, 132, 255)
pingLbl.TextSize = 11.5
pingLbl.TextXAlignment = Enum.TextXAlignment.Left
pingLbl.Parent = TelemetryWin

-- FPS Counter
local lastTime = os.clock()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local curTime = os.clock()
    if curTime - lastTime >= 1 then
        fpsLbl.Text = "Frame Rate: " .. tostring(frameCount) .. " FPS"
        frameCount = 0
        lastTime = curTime
    end
end)

-- Глобальный обработчик кейбиндов
UserInputService.InputBegan:Connect(function(input, gp)
    if LiquidGlass.CurrentListening then
        if input.UserInputType == Enum.UserInputType.Keyboard then
            LiquidGlass.CurrentListening.SetCallback(input.KeyCode)
            LiquidGlass.CurrentListening = nil
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            LiquidGlass.CurrentListening.SetCallback(Enum.UserInputType.MouseButton2)
            LiquidGlass.CurrentListening = nil
        end
        return
    end

    if gp then return end

    for _, bindData in pairs(LiquidGlass.Keybinds) do
        if (bindData.Key == input.KeyCode or bindData.Key == input.UserInputType) and bindData.Toggle then
            bindData.Toggle(not bindData.State())
        end
    end
end)

return LiquidGlass
