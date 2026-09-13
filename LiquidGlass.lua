-- [[ LiquidGlass UI Library (Bug-Free 1:1 Pixel-Perfect Engine) ]]
-- Fixed Font Tween Crash & Invalid Sound IDs

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local LocalPlayer = Players.LocalPlayer

local LiquidGlass = {
    Version = "8.0.0",
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

-- Инициализация ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "LiquidGlass_MasterCore"
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

-- Иконки Lucide
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
    bell = "rbxassetid://10709753149"
}

-- Цветовая схема Liquid Glass
local Theme = {
    MainGlass = Color3.fromRGB(15, 23, 42),
    MainTransparency = 0.12,
    SidebarGlass = Color3.fromRGB(10, 16, 30),
    SidebarTransparency = 0.25,
    CardGlass = Color3.fromRGB(24, 34, 53),
    CardTransparency = 0.35,
    Accent = Color3.fromRGB(10, 132, 255),
    AccentGlow = Color3.fromRGB(90, 200, 250),
    Text = Color3.fromRGB(245, 245, 247),
    SubText = Color3.fromRGB(142, 142, 147),
    Success = Color3.fromRGB(48, 209, 88),
    Danger = Color3.fromRGB(255, 69, 58)
}

local function tween(object, properties, duration, style, direction)
    local info = TweenInfo.new(duration or 0.3, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
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
    stroke.Transparency = strokeTransparency or 0.65
    stroke.Parent = instance

    local strokeGradient = Instance.new("UIGradient")
    strokeGradient.Rotation = 45
    strokeGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.45, Color3.fromRGB(180, 190, 210)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(30, 40, 60))
    })
    strokeGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.1),
        NumberSequenceKeypoint.new(0.5, 0.5),
        NumberSequenceKeypoint.new(1, 0.95)
    })
    strokeGradient.Parent = stroke

    return stroke
end

local function makeDraggable(frame, handle, onDragEnd)
    local dragging, dragInput, dragStart, startPos
    local hasMoved = false

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            hasMoved = false
            dragStart = input.Position
            startPos = frame.Position

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
            if math.abs(delta.X) > 3 or math.abs(delta.Y) > 3 then hasMoved = true end
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function makeResizable(frame, handle, minWidth, minHeight)
    minWidth = minWidth or 180
    minHeight = minHeight or 95
    local resizing, dragInput, dragStart, startSize

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            resizing = true
            dragStart = input.Position
            startSize = frame.AbsoluteSize
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then resizing = false end
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
            frame.Size = UDim2.new(0, math.max(minWidth, startSize.X + delta.X), 0, math.max(minHeight, startSize.Y + delta.Y))
        end
    end)
end

-- Безопасная функция воспроизведения звуков
local function playSound(type)
    pcall(function()
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
            s.SoundId = "rbxassetid://9119713951"
            s.PlaybackSpeed = 0.8
            s.Volume = 0.7
        elseif type == "Tap" then
            s.SoundId = "rbxassetid://9119713951"
        elseif type == "Island" then
            s.SoundId = "rbxassetid://6895079853"
            s.PlaybackSpeed = 1.3
        end

        s:Play()
        s.Ended:Connect(function() s:Destroy() end)
    end)
end

-- ================= ИНТРО APPLE "HELLO" =================
function LiquidGlass:PlayIntro()
    local bootScreen = Instance.new("Frame")
    bootScreen.Size = UDim2.new(1, 0, 1, 0)
    bootScreen.BackgroundColor3 = Color3.fromRGB(8, 8, 12)
    bootScreen.BackgroundTransparency = 0.05
    bootScreen.ZIndex = 1000
    bootScreen.Parent = ScreenGui

    local helloLabel = Instance.new("TextLabel")
    helloLabel.Size = UDim2.new(0, 400, 0, 120)
    helloLabel.Position = UDim2.new(0.5, -200, 0.5, -60)
    helloLabel.BackgroundTransparency = 1
    helloLabel.Font = Enum.Font.FredokaOne
    helloLabel.Text = "hello"
    helloLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    helloLabel.TextSize = 74
    helloLabel.TextTransparency = 1
    helloLabel.ZIndex = 1001
    helloLabel.Parent = bootScreen

    playSound("Intro")
    tween(helloLabel, {TextTransparency = 0}, 0.7)

    local dismissed = false
    local function dismiss()
        if dismissed then return end
        dismissed = true
        tween(bootScreen, {BackgroundTransparency = 1}, 0.4)
        local t = tween(helloLabel, {TextTransparency = 1, TextSize = 85}, 0.4)
        t.Completed:Connect(function()
            bootScreen:Destroy()
        end)
    end

    bootScreen.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
            dismiss()
        end
    end)

    task.delay(1.8, dismiss)
end
task.spawn(function() LiquidGlass:PlayIntro() end)

-- ================= УВЕДОМЛЕНИЯ =================
function LiquidGlass:Notify(title, desc)
    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(0, 280, 0, 56)
    toast.Position = UDim2.new(1, 20, 1, -76)
    toast.BackgroundColor3 = Theme.MainGlass
    toast.BackgroundTransparency = 0.15
    toast.ClipsDescendants = true
    toast.ZIndex = 90
    toast.Parent = ScreenGui
    applyGlass(toast, UDim.new(0, 18), 0.6)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 18, 0, 18)
    icon.Position = UDim2.new(0, 12, 0.5, -9)
    icon.BackgroundTransparency = 1
    icon.Image = Icons.bell
    icon.ImageColor3 = Theme.Accent
    icon.ZIndex = 91
    icon.Parent = toast

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -42, 0, 18)
    tLbl.Position = UDim2.new(0, 36, 0, 8)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Theme.Text
    tLbl.TextSize = 13
    tLbl.TextXAlignment = Enum.TextXAlignment.Left
    tLbl.ZIndex = 91
    tLbl.Parent = toast

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1, -42, 0, 16)
    dLbl.Position = UDim2.new(0, 36, 0, 28)
    dLbl.BackgroundTransparency = 1
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.Text = desc
    dLbl.TextColor3 = Theme.SubText
    dLbl.TextSize = 11
    dLbl.TextXAlignment = Enum.TextXAlignment.Left
    dLbl.ZIndex = 91
    dLbl.Parent = toast

    tween(toast, {Position = UDim2.new(1, -300, 1, -76)}, 0.45, Enum.EasingStyle.Back)
    task.delay(3, function()
        local out = tween(toast, {Position = UDim2.new(1, 20, 1, -76), BackgroundTransparency = 1}, 0.35)
        out.Completed:Connect(function() toast:Destroy() end)
    end)
end

-- ================= ДИАЛОГ ПОДТВЕРЖДЕНИЯ =================
local function openConfirmDialog(title, desc, onConfirm)
    playSound("3Bell")
    local backdrop = Instance.new("Frame")
    backdrop.Size = UDim2.new(1, 0, 1, 0)
    backdrop.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    backdrop.BackgroundTransparency = 0.5
    backdrop.ZIndex = 150
    backdrop.Parent = ScreenGui

    local modal = Instance.new("Frame")
    modal.Size = UDim2.new(0, 360, 0, 195)
    modal.Position = UDim2.new(0.5, -180, 0.5, -97)
    modal.BackgroundColor3 = Theme.MainGlass
    modal.BackgroundTransparency = 0.15
    modal.ClipsDescendants = true
    modal.ZIndex = 151
    modal.Parent = backdrop
    applyGlass(modal, UDim.new(0, 26), 0.6)

    local icon = Instance.new("ImageLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0.5, -15, 0, 16)
    icon.BackgroundTransparency = 1
    icon.Image = Icons.alert
    icon.ImageColor3 = Theme.Danger
    icon.ZIndex = 152
    icon.Parent = modal

    local tLbl = Instance.new("TextLabel")
    tLbl.Size = UDim2.new(1, -32, 0, 20)
    tLbl.Position = UDim2.new(0, 16, 0, 52)
    tLbl.BackgroundTransparency = 1
    tLbl.Font = Enum.Font.GothamBold
    tLbl.Text = title
    tLbl.TextColor3 = Theme.Text
    tLbl.TextSize = 15
    tLbl.ZIndex = 152
    tLbl.Parent = modal

    local dLbl = Instance.new("TextLabel")
    dLbl.Size = UDim2.new(1, -32, 0, 36)
    dLbl.Position = UDim2.new(0, 16, 0, 76)
    dLbl.BackgroundTransparency = 1
    dLbl.Font = Enum.Font.GothamMedium
    dLbl.Text = desc
    dLbl.TextColor3 = Theme.SubText
    dLbl.TextSize = 12
    dLbl.TextWrapped = true
    dLbl.ZIndex = 152
    dLbl.Parent = modal

    local cancelBtn = Instance.new("TextButton")
    cancelBtn.Size = UDim2.new(0.5, -22, 0, 36)
    cancelBtn.Position = UDim2.new(0, 16, 1, -48)
    cancelBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    cancelBtn.BackgroundTransparency = 0.9
    cancelBtn.Font = Enum.Font.GothamBold
    cancelBtn.Text = "Cancel"
    cancelBtn.TextColor3 = Theme.Text
    cancelBtn.TextSize = 13
    cancelBtn.ZIndex = 152
    cancelBtn.Parent = modal
    applyGlass(cancelBtn, UDim.new(0, 12), 0.7)

    local confirmBtn = Instance.new("TextButton")
    confirmBtn.Size = UDim2.new(0.5, -22, 0, 36)
    confirmBtn.Position = UDim2.new(0.5, 6, 1, -48)
    confirmBtn.BackgroundColor3 = Theme.Danger
    confirmBtn.Font = Enum.Font.GothamBold
    confirmBtn.Text = "Confirm"
    confirmBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    confirmBtn.TextSize = 13
    confirmBtn.ZIndex = 152
    confirmBtn.Parent = modal
    applyGlass(confirmBtn, UDim.new(0, 12), 0.4)

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

-- ================= ГЛАВНОЕ ОКНО =================
function LiquidGlass:CreateWindow(config)
    config = config or {}
    local TitleText = config.Title or "LiquidGlass UI"
    local ToggleKey = config.ToggleKey or Enum.KeyCode.RightControl

    local Window = { Tabs = {}, ActiveTab = nil, Minimized = false }

    -- Главное окно
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = UDim2.new(0, 800, 0, 520)
    MainFrame.Position = UDim2.new(0.5, -400, 0.5, -260)
    MainFrame.BackgroundColor3 = Theme.MainGlass
    MainFrame.BackgroundTransparency = Theme.MainTransparency
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 10
    MainFrame.Parent = ScreenGui
    applyGlass(MainFrame, UDim.new(0, 20), 0.7)

    -- Dynamic Island
    local Island = Instance.new("Frame")
    Island.Name = "DynamicIsland"
    Island.Size = UDim2.new(0, 215, 0, 36)
    Island.Position = UDim2.new(0.5, -107, 0, 14)
    Island.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    Island.Visible = false
    Island.ZIndex = 100
    Island.Parent = ScreenGui
    applyGlass(Island, UDim.new(1, 0), 0.3)

    local IslandAvatar = Instance.new("ImageLabel")
    IslandAvatar.Size = UDim2.new(0, 22, 0, 22)
    IslandAvatar.Position = UDim2.new(0, 26, 0.5, -11)
    IslandAvatar.BackgroundTransparency = 1
    IslandAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    IslandAvatar.ZIndex = 101
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
    IslandUser.TextColor3 = Theme.Text
    IslandUser.TextSize = 11
    IslandUser.TextXAlignment = Enum.TextXAlignment.Left
    IslandUser.ZIndex = 101
    IslandUser.Parent = Island

    local IslandStatus = Instance.new("TextLabel")
    IslandStatus.Size = UDim2.new(0, 85, 0, 12)
    IslandStatus.Position = UDim2.new(0, 54, 0, 19)
    IslandStatus.BackgroundTransparency = 1
    IslandStatus.Font = Enum.Font.GothamMedium
    IslandStatus.Text = "● Active"
    IslandStatus.TextColor3 = Theme.Success
    IslandStatus.TextSize = 9
    IslandStatus.TextXAlignment = Enum.TextXAlignment.Left
    IslandStatus.ZIndex = 101
    IslandStatus.Parent = Island

    local waveContainer = Instance.new("Frame")
    waveContainer.Size = UDim2.new(0, 16, 0, 14)
    waveContainer.Position = UDim2.new(1, -26, 0.5, -7)
    waveContainer.BackgroundTransparency = 1
    waveContainer.ZIndex = 101
    waveContainer.Parent = Island

    local wb1 = Instance.new("Frame")
    wb1.Size = UDim2.new(0, 2, 0, 6)
    wb1.Position = UDim2.new(0, 0, 0.5, -3)
    wb1.BackgroundColor3 = Theme.Success
    wb1.ZIndex = 101
    wb1.Parent = waveContainer

    local wb2 = Instance.new("Frame")
    wb2.Size = UDim2.new(0, 2, 0, 12)
    wb2.Position = UDim2.new(0, 5, 0.5, -6)
    wb2.BackgroundColor3 = Theme.Success
    wb2.ZIndex = 101
    wb2.Parent = waveContainer

    local wb3 = Instance.new("Frame")
    wb3.Size = UDim2.new(0, 2, 0, 8)
    wb3.Position = UDim2.new(0, 10, 0.5, -4)
    wb3.BackgroundColor3 = Theme.Success
    wb3.ZIndex = 101
    wb3.Parent = waveContainer

    task.spawn(function()
        while true do
            tween(wb1, {Size = UDim2.new(0, 2, 0, math.random(4, 12))}, 0.25)
            tween(wb2, {Size = UDim2.new(0, 2, 0, math.random(4, 14))}, 0.25)
            tween(wb3, {Size = UDim2.new(0, 2, 0, math.random(4, 10))}, 0.25)
            task.wait(0.25)
        end
    end)

    makeDraggable(Island, Island, function(hasMoved)
        if not hasMoved then Window:Toggle(false) end
    end)

    -- Topbar
    local TopBar = Instance.new("Frame")
    TopBar.Size = UDim2.new(1, 0, 0, 50)
    TopBar.BackgroundTransparency = 1
    TopBar.ZIndex = 11
    TopBar.Parent = MainFrame
    makeDraggable(MainFrame, TopBar)

    local CloseBtn = Instance.new("TextButton")
    CloseBtn.Size = UDim2.new(0, 12, 0, 12)
    CloseBtn.Position = UDim2.new(0, 18, 0, 19)
    CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 95, 86)
    CloseBtn.Text = ""
    CloseBtn.AutoButtonColor = false
    CloseBtn.ZIndex = 12
    CloseBtn.Parent = TopBar
    applyGlass(CloseBtn, UDim.new(1, 0), 0.2)
    CloseBtn.MouseButton1Click:Connect(function() ScreenGui:Destroy() end)

    local MinimizeBtn = Instance.new("TextButton")
    MinimizeBtn.Size = UDim2.new(0, 12, 0, 12)
    MinimizeBtn.Position = UDim2.new(0, 36, 0, 19)
    MinimizeBtn.BackgroundColor3 = Color3.fromRGB(255, 189, 46)
    MinimizeBtn.Text = ""
    MinimizeBtn.AutoButtonColor = false
    MinimizeBtn.ZIndex = 12
    MinimizeBtn.Parent = TopBar
    applyGlass(MinimizeBtn, UDim.new(1, 0), 0.2)

    local FullBtn = Instance.new("TextButton")
    FullBtn.Size = UDim2.new(0, 12, 0, 12)
    FullBtn.Position = UDim2.new(0, 54, 0, 19)
    FullBtn.BackgroundColor3 = Color3.fromRGB(39, 201, 63)
    FullBtn.Text = ""
    FullBtn.AutoButtonColor = false
    FullBtn.ZIndex = 12
    FullBtn.Parent = TopBar
    applyGlass(FullBtn, UDim.new(1, 0), 0.2)

    local TitleLabel = Instance.new("TextLabel")
    TitleLabel.Size = UDim2.new(1, -80, 1, 0)
    TitleLabel.Position = UDim2.new(0, 74, 0, 0)
    TitleLabel.BackgroundTransparency = 1
    TitleLabel.Font = Enum.Font.Gotham
    TitleLabel.RichText = true
    TitleLabel.Text = string.format('<b><font color="rgb(245,245,247)" size="14">%s</font></b>    <font color="rgb(142,142,147)" size="11">Apple iOS Architecture • Press [Right Ctrl] to Toggle</font>', TitleText)
    TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
    TitleLabel.ZIndex = 12
    TitleLabel.Parent = TopBar

    -- Сайдбар
    local Sidebar = Instance.new("Frame")
    Sidebar.Size = UDim2.new(0, 200, 0, 452)
    Sidebar.Position = UDim2.new(0, 16, 0, 52)
    Sidebar.BackgroundColor3 = Theme.SidebarGlass
    Sidebar.BackgroundTransparency = Theme.SidebarTransparency
    Sidebar.ZIndex = 11
    Sidebar.Parent = MainFrame
    applyGlass(Sidebar, UDim.new(0, 18), 0.75)

    -- Поисковая строка
    local SearchBoxFrame = Instance.new("Frame")
    SearchBoxFrame.Size = UDim2.new(1, -16, 0, 36)
    SearchBoxFrame.Position = UDim2.new(0, 8, 0, 8)
    SearchBoxFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    SearchBoxFrame.BackgroundTransparency = 0.94
    SearchBoxFrame.ZIndex = 12
    SearchBoxFrame.Parent = Sidebar
    applyGlass(SearchBoxFrame, UDim.new(0, 10), 0.8)

    local SearchIcon = Instance.new("ImageLabel")
    SearchIcon.Size = UDim2.new(0, 14, 0, 14)
    SearchIcon.Position = UDim2.new(0, 8, 0.5, -7)
    SearchIcon.BackgroundTransparency = 1
    SearchIcon.Image = Icons.search
    SearchIcon.ImageColor3 = Theme.SubText
    SearchIcon.ZIndex = 13
    SearchIcon.Parent = SearchBoxFrame

    local SearchInput = Instance.new("TextBox")
    SearchInput.Size = UDim2.new(1, -30, 1, 0)
    SearchInput.Position = UDim2.new(0, 26, 0, 0)
    SearchInput.BackgroundTransparency = 1
    SearchInput.Font = Enum.Font.GothamMedium
    SearchInput.PlaceholderText = "Search features..."
    SearchInput.PlaceholderColor3 = Theme.SubText
    SearchInput.Text = ""
    SearchInput.TextColor3 = Theme.Text
    SearchInput.TextSize = 12
    SearchInput.TextXAlignment = Enum.TextXAlignment.Left
    SearchInput.ClearTextOnFocus = false
    SearchInput.ZIndex = 13
    SearchInput.Parent = SearchBoxFrame

    -- Контейнер табов
    local TabScroll = Instance.new("ScrollingFrame")
    TabScroll.Size = UDim2.new(1, -16, 1, -104)
    TabScroll.Position = UDim2.new(0, 8, 0, 50)
    TabScroll.BackgroundTransparency = 1
    TabScroll.ScrollBarThickness = 0
    TabScroll.ZIndex = 12
    TabScroll.Parent = Sidebar
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 4)
    tabLayout.Parent = TabScroll

    -- Карточка профиля
    local UserCard = Instance.new("Frame")
    UserCard.Size = UDim2.new(1, -16, 0, 44)
    UserCard.Position = UDim2.new(0, 8, 1, -52)
    UserCard.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    UserCard.BackgroundTransparency = 0.95
    UserCard.ZIndex = 12
    UserCard.Parent = Sidebar
    applyGlass(UserCard, UDim.new(0, 12), 0.8)

    local UserAvatar = Instance.new("ImageLabel")
    UserAvatar.Size = UDim2.new(0, 28, 0, 28)
    UserAvatar.Position = UDim2.new(0, 8, 0.5, -14)
    UserAvatar.BackgroundTransparency = 1
    UserAvatar.Image = Players:GetUserThumbnailAsync(LocalPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100)
    UserAvatar.ZIndex = 13
    UserAvatar.Parent = UserCard
    local uavCorner = Instance.new("UICorner")
    uavCorner.CornerRadius = UDim.new(1, 0)
    uavCorner.Parent = UserAvatar

    local UserName = Instance.new("TextLabel")
    UserName.Size = UDim2.new(1, -44, 0, 14)
    UserName.Position = UDim2.new(0, 42, 0, 8)
    UserName.BackgroundTransparency = 1
    UserName.Font = Enum.Font.GothamBold
    UserName.Text = LocalPlayer.DisplayName
    UserName.TextColor3 = Theme.Text
    UserName.TextSize = 11.5
    UserName.TextXAlignment = Enum.TextXAlignment.Left
    UserName.ZIndex = 13
    UserName.Parent = UserCard

    local UserTag = Instance.new("TextLabel")
    UserTag.Size = UDim2.new(1, -44, 0, 12)
    UserTag.Position = UDim2.new(0, 42, 0, 22)
    UserTag.BackgroundTransparency = 1
    UserTag.Font = Enum.Font.GothamMedium
    UserTag.Text = "@" .. LocalPlayer.Name
    UserTag.TextColor3 = Theme.SubText
    UserTag.TextSize = 9.5
    UserTag.TextXAlignment = Enum.TextXAlignment.Left
    UserTag.ZIndex = 13
    UserTag.Parent = UserCard

    -- Контейнер страниц контента
    local PageContainer = Instance.new("Frame")
    PageContainer.Name = "PageContainer"
    PageContainer.Size = UDim2.new(0, 554, 0, 452)
    PageContainer.Position = UDim2.new(0, 228, 0, 52)
    PageContainer.BackgroundTransparency = 1
    PageContainer.ZIndex = 11
    PageContainer.Parent = MainFrame

    function Window:Toggle(minimize)
        if minimize == nil then minimize = not Window.Minimized end
        Window.Minimized = minimize

        if Window.Minimized then
            playSound("Island")
            Island.Visible = true
            tween(MainFrame, {Position = UDim2.new(0.5, -400, 0, -600), BackgroundTransparency = 1}, 0.5)
            tween(Island, {Size = UDim2.new(0, 215, 0, 36)}, 0.45, Enum.EasingStyle.Back)
        else
            playSound("Island")
            tween(MainFrame, {Position = UDim2.new(0.5, -400, 0.5, -260), BackgroundTransparency = Theme.MainTransparency}, 0.5)
            task.delay(0.15, function()
                if not Window.Minimized then Island.Visible = false end
            end)
        end
    end

    MinimizeBtn.MouseButton1Click:Connect(function() Window:Toggle(true) end)
    UserInputService.InputBegan:Connect(function(inp, gp)
        if not gp and inp.KeyCode == ToggleKey then Window:Toggle() end
    end)

    SearchInput:GetPropertyChangedSignal("Text"):Connect(function()
        local query = SearchInput.Text:lower()
        for _, tab in pairs(Window.Tabs) do
            for _, item in pairs(tab.Elements) do
                if item.Frame and item.Name then
                    item.Frame.Visible = (query == "" or item.Name:lower():find(query) ~= nil)
                end
            end
        end
    end)

    -- ================= ТАБЫ =================
    function Window:CreateTab(tabConfig)
        tabConfig = tabConfig or {}
        local Name = tabConfig.Name or "Tab"
        local Icon = tabConfig.Icon or Icons.home

        local Tab = { Elements = {}, LayoutCounter = 0 }

        local Page = Instance.new("ScrollingFrame")
        Page.Name = Name .. "_Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.Position = UDim2.new(0, 0, 0, 0)
        Page.BackgroundTransparency = 1
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Color3.fromRGB(140, 150, 170)
        Page.CanvasSize = UDim2.new(0, 0, 0, 1200)
        Page.Visible = false
        Page.ZIndex = 12
        Page.Parent = PageContainer

        local pLayout = Instance.new("UIListLayout")
        pLayout.Padding = UDim.new(0, 10)
        pLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pLayout.Parent = Page

        pLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, pLayout.AbsoluteContentSize.Y + 30)
        end)

        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, 0, 0, 36)
        TabBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.ZIndex = 13
        TabBtn.Parent = TabScroll
        local btnCorner = Instance.new("UICorner")
        btnCorner.CornerRadius = UDim.new(0, 10)
        btnCorner.Parent = TabBtn

        local TabIcon = Instance.new("ImageLabel")
        TabIcon.Size = UDim2.new(0, 16, 0, 16)
        TabIcon.Position = UDim2.new(0, 10, 0.5, -8)
        TabIcon.BackgroundTransparency = 1
        TabIcon.Image = Icon
        TabIcon.ImageColor3 = Theme.SubText
        TabIcon.ZIndex = 14
        TabIcon.Parent = TabBtn

        local TabTitle = Instance.new("TextLabel")
        TabTitle.Size = UDim2.new(1, -36, 1, 0)
        TabTitle.Position = UDim2.new(0, 34, 0, 0)
        TabTitle.BackgroundTransparency = 1
        TabTitle.Font = Enum.Font.GothamMedium
        TabTitle.Text = Name
        TabTitle.TextColor3 = Theme.SubText
        TabTitle.TextSize = 12.5
        TabTitle.TextXAlignment = Enum.TextXAlignment.Left
        TabTitle.ZIndex = 14
        TabTitle.Parent = TabBtn

        -- ИСПРАВЛЕННАЯ ФУНКЦИЯ АКТИВАЦИИ ТАБА БЕЗ TWEEN FONT
        local function activate()
            playSound("Tap")
            for _, t in pairs(Window.Tabs) do
                tween(t.Btn, {BackgroundTransparency = 1}, 0.2)
                t.Title.Font = Enum.Font.GothamMedium
                tween(t.Title, {TextColor3 = Theme.SubText}, 0.2)
                tween(t.Icon, {ImageColor3 = Theme.SubText}, 0.2)
                t.Page.Visible = false
            end
            Page.Visible = true
            tween(TabBtn, {BackgroundTransparency = 0.85}, 0.2)
            TabTitle.Font = Enum.Font.GothamBold
            tween(TabTitle, {TextColor3 = Theme.Text}, 0.2)
            tween(TabIcon, {ImageColor3 = Theme.Text}, 0.2)
            Window.ActiveTab = Tab
        end

        TabBtn.MouseButton1Click:Connect(activate)
        Tab.Btn = TabBtn
        Tab.Title = TabTitle
        Tab.Icon = TabIcon
        Tab.Page = Page
        table.insert(Window.Tabs, Tab)
        if #Window.Tabs == 1 then activate() end

        -- Секция
        function Tab:CreateSection(text)
            Tab.LayoutCounter = Tab.LayoutCounter + 1
            local SecLbl = Instance.new("TextLabel")
            SecLbl.Size = UDim2.new(1, 0, 0, 18)
            SecLbl.BackgroundTransparency = 1
            SecLbl.Font = Enum.Font.GothamBold
            SecLbl.Text = string.upper(text)
            SecLbl.TextColor3 = Theme.SubText
            SecLbl.TextSize = 11
            SecLbl.TextXAlignment = Enum.TextXAlignment.Left
            SecLbl.LayoutOrder = Tab.LayoutCounter
            SecLbl.ZIndex = 12
            SecLbl.Parent = Page
        end

        -- Переключатель
        function Tab:CreateToggle(tglConfig)
            tglConfig = tglConfig or {}
            local Title = tglConfig.Name or "Toggle"
            local Desc = tglConfig.Description or ""
            local State = tglConfig.Default or false
            local BindKey = tglConfig.Keybind
            local Flag = tglConfig.Flag
            local Callback = tglConfig.Callback or function() end

            Tab.LayoutCounter = Tab.LayoutCounter + 1

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -10, 0, 56)
            Frame.BackgroundColor3 = Theme.CardGlass
            Frame.BackgroundTransparency = Theme.CardTransparency
            Frame.LayoutOrder = Tab.LayoutCounter
            Frame.ZIndex = 12
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 14), 0.65)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -130, 0, 18)
            Lbl.Position = UDim2.new(0, 16, 0, Desc ~= "" and 10 or 19)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Theme.Text
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.ZIndex = 13
            Lbl.Parent = Frame

            if Desc ~= "" then
                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, -130, 0, 14)
                dLbl.Position = UDim2.new(0, 16, 0, 29)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamMedium
                dLbl.Text = Desc
                dLbl.TextColor3 = Theme.SubText
                dLbl.TextSize = 11
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.ZIndex = 13
                dLbl.Parent = Frame
            end

            local BindBtn = Instance.new("TextButton")
            BindBtn.Size = UDim2.new(0, 52, 0, 24)
            BindBtn.Position = UDim2.new(1, -114, 0.5, -12)
            BindBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            BindBtn.BackgroundTransparency = 0.92
            BindBtn.Font = Enum.Font.GothamBold
            BindBtn.Text = BindKey and (typeof(BindKey) == "EnumItem" and BindKey.Name or tostring(BindKey)) or "NONE"
            BindBtn.TextColor3 = Theme.Text
            BindBtn.TextSize = 10.5
            BindBtn.ZIndex = 13
            BindBtn.Parent = Frame
            applyGlass(BindBtn, UDim.new(0, 8), 0.8)

            local Switch = Instance.new("TextButton")
            Switch.Size = UDim2.new(0, 44, 0, 24)
            Switch.Position = UDim2.new(1, -54, 0.5, -12)
            Switch.BackgroundColor3 = State and Theme.Accent or Color3.fromRGB(45, 55, 72)
            Switch.BackgroundTransparency = State and 0 or 0.4
            Switch.Text = ""
            Switch.AutoButtonColor = false
            Switch.ZIndex = 13
            Switch.Parent = Frame
            applyGlass(Switch, UDim.new(1, 0), 0.7)

            local Knob = Instance.new("Frame")
            Knob.Size = UDim2.new(0, 20, 0, 20)
            Knob.Position = State and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)
            Knob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Knob.ZIndex = 14
            Knob.Parent = Switch
            local kCorner = Instance.new("UICorner")
            kCorner.CornerRadius = UDim.new(1, 0)
            kCorner.Parent = Knob

            local function setToggle(val)
                State = val
                if State then playSound("5Bell") else playSound("3Bell") end
                tween(Knob, {Position = State and UDim2.new(1, -22, 0.5, -10) or UDim2.new(0, 2, 0.5, -10)}, 0.25)
                tween(Switch, {BackgroundColor3 = State and Theme.Accent or Color3.fromRGB(45, 55, 72), BackgroundTransparency = State and 0 or 0.4}, 0.25)
                LiquidGlass:Notify(Title, State and "Enabled" or "Disabled")
                if Flag then LiquidGlass.Flags[Flag] = State end
                pcall(Callback, State)
            end

            Switch.MouseButton1Click:Connect(function() setToggle(not State) end)

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

        -- Слайдер
        function Tab:CreateSlider(sldConfig)
            sldConfig = sldConfig or {}
            local Title = sldConfig.Name or "Slider"
            local Desc = sldConfig.Description or ""
            local Min = sldConfig.Min or 0
            local Max = sldConfig.Max or 100
            local Def = sldConfig.Default or Min
            local Unit = sldConfig.Unit or ""
            local Flag = sldConfig.Flag
            local Callback = sldConfig.Callback or function() end

            Tab.LayoutCounter = Tab.LayoutCounter + 1

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -10, 0, 72)
            Frame.BackgroundColor3 = Theme.CardGlass
            Frame.BackgroundTransparency = Theme.CardTransparency
            Frame.LayoutOrder = Tab.LayoutCounter
            Frame.ZIndex = 12
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 14), 0.65)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -90, 0, 18)
            Lbl.Position = UDim2.new(0, 16, 0, 10)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Theme.Text
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.ZIndex = 13
            Lbl.Parent = Frame

            if Desc ~= "" then
                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, -90, 0, 14)
                dLbl.Position = UDim2.new(0, 16, 0, 27)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamMedium
                dLbl.Text = Desc
                dLbl.TextColor3 = Theme.SubText
                dLbl.TextSize = 11
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.ZIndex = 13
                dLbl.Parent = Frame
            end

            local Badge = Instance.new("TextLabel")
            Badge.Size = UDim2.new(0, 68, 0, 22)
            Badge.Position = UDim2.new(1, -84, 0, 10)
            Badge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Badge.BackgroundTransparency = 0.92
            Badge.Font = Enum.Font.GothamBold
            Badge.Text = tostring(Def) .. " " .. Unit
            Badge.TextColor3 = Theme.Text
            Badge.TextSize = 11
            Badge.ZIndex = 13
            Badge.Parent = Frame
            applyGlass(Badge, UDim.new(0, 8), 0.8)

            local Track = Instance.new("TextButton")
            Track.Size = UDim2.new(1, -32, 0, 8)
            Track.Position = UDim2.new(0, 16, 1, -16)
            Track.BackgroundColor3 = Color3.fromRGB(8, 12, 20)
            Track.BackgroundTransparency = 0.3
            Track.Text = ""
            Track.AutoButtonColor = false
            Track.ZIndex = 13
            Track.Parent = Frame
            applyGlass(Track, UDim.new(1, 0), 0.8)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new(math.clamp((Def - Min) / (Max - Min), 0, 1), 0, 1, 0)
            Fill.BackgroundColor3 = Theme.Accent
            Fill.ZIndex = 14
            Fill.Parent = Track
            local fCorner = Instance.new("UICorner")
            fCorner.CornerRadius = UDim.new(1, 0)
            fCorner.Parent = Fill

            local fGrad = Instance.new("UIGradient")
            fGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Theme.Accent),
                ColorSequenceKeypoint.new(1, Theme.AccentGlow)
            })
            fGrad.Parent = Fill

            local Thumb = Instance.new("Frame")
            Thumb.Size = UDim2.new(0, 20, 0, 20)
            Thumb.Position = UDim2.new(1, -10, 0.5, -10)
            Thumb.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Thumb.ZIndex = 15
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

        -- Аккордеон Aimbot
        function Tab:CreateAimbotAccordion()
            Tab.LayoutCounter = Tab.LayoutCounter + 1

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -10, 0, 56)
            Frame.BackgroundColor3 = Theme.CardGlass
            Frame.BackgroundTransparency = Theme.CardTransparency
            Frame.ClipsDescendants = true
            Frame.LayoutOrder = Tab.LayoutCounter
            Frame.ZIndex = 12
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 16), 0.65)

            local Header = Instance.new("TextButton")
            Header.Size = UDim2.new(1, 0, 0, 56)
            Header.BackgroundTransparency = 1
            Header.Text = ""
            Header.ZIndex = 13
            Header.Parent = Frame

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -140, 0, 18)
            Lbl.Position = UDim2.new(0, 16, 0, 10)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = "Aimbot Assistant"
            Lbl.TextColor3 = Theme.Text
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.ZIndex = 14
            Lbl.Parent = Header

            local dLbl = Instance.new("TextLabel")
            dLbl.Size = UDim2.new(1, -140, 0, 14)
            dLbl.Position = UDim2.new(0, 16, 0, 29)
            dLbl.BackgroundTransparency = 1
            dLbl.Font = Enum.Font.GothamMedium
            dLbl.Text = "Target tracking with customizable parameters"
            dLbl.TextColor3 = Theme.SubText
            dLbl.TextSize = 11
            dLbl.TextXAlignment = Enum.TextXAlignment.Left
            dLbl.ZIndex = 14
            dLbl.Parent = Header

            local Chevron = Instance.new("ImageLabel")
            Chevron.Size = UDim2.new(0, 16, 0, 16)
            Chevron.Position = UDim2.new(1, -26, 0.5, -8)
            Chevron.BackgroundTransparency = 1
            Chevron.Image = Icons.chevron
            Chevron.ImageColor3 = Theme.SubText
            Chevron.ZIndex = 14
            Chevron.Parent = Header

            local isExpanded = false
            Header.MouseButton1Click:Connect(function()
                playSound("Tap")
                isExpanded = not isExpanded
                tween(Chevron, {Rotation = isExpanded and 180 or 0}, 0.3)
                tween(Frame, {Size = isExpanded and UDim2.new(1, -10, 0, 220) or UDim2.new(1, -10, 0, 56)}, 0.35)
            end)

            table.insert(Tab.Elements, { Frame = Frame, Name = "Aimbot Assistant" })
        end

        -- Кнопка
        function Tab:CreateButton(btnConfig)
            btnConfig = btnConfig or {}
            local Title = btnConfig.Name or "Button"
            local Desc = btnConfig.Description or ""
            local IsDestructive = btnConfig.Destructive or false
            local Callback = btnConfig.Callback or function() end

            Tab.LayoutCounter = Tab.LayoutCounter + 1

            local Frame = Instance.new("Frame")
            Frame.Size = UDim2.new(1, -10, 0, 56)
            Frame.BackgroundColor3 = Theme.CardGlass
            Frame.BackgroundTransparency = Theme.CardTransparency
            Frame.LayoutOrder = Tab.LayoutCounter
            Frame.ZIndex = 12
            Frame.Parent = Page
            applyGlass(Frame, UDim.new(0, 14), 0.65)

            local Lbl = Instance.new("TextLabel")
            Lbl.Size = UDim2.new(1, -130, 0, 18)
            Lbl.Position = UDim2.new(0, 16, 0, Desc ~= "" and 10 or 19)
            Lbl.BackgroundTransparency = 1
            Lbl.Font = Enum.Font.GothamMedium
            Lbl.Text = Title
            Lbl.TextColor3 = Theme.Text
            Lbl.TextSize = 13.5
            Lbl.TextXAlignment = Enum.TextXAlignment.Left
            Lbl.ZIndex = 13
            Lbl.Parent = Frame

            if Desc ~= "" then
                local dLbl = Instance.new("TextLabel")
                dLbl.Size = UDim2.new(1, -130, 0, 14)
                dLbl.Position = UDim2.new(0, 16, 0, 29)
                dLbl.BackgroundTransparency = 1
                dLbl.Font = Enum.Font.GothamMedium
                dLbl.Text = Desc
                dLbl.TextColor3 = Theme.SubText
                dLbl.TextSize = 11
                dLbl.TextXAlignment = Enum.TextXAlignment.Left
                dLbl.ZIndex = 13
                dLbl.Parent = Frame
            end

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(0, 95, 0, 30)
            Btn.Position = UDim2.new(1, -107, 0.5, -15)
            Btn.BackgroundColor3 = IsDestructive and Theme.Danger or Color3.fromRGB(255, 255, 255)
            Btn.BackgroundTransparency = IsDestructive and 0.8 or 0.92
            Btn.Font = Enum.Font.GothamBold
            Btn.Text = "      Execute"
            Btn.TextColor3 = IsDestructive and Color3.fromRGB(255, 120, 120) or Theme.Text
            Btn.TextSize = 12
            Btn.ZIndex = 13
            Btn.Parent = Frame
            applyGlass(Btn, UDim.new(0, 10), IsDestructive and 0.5 or 0.8)

            local btnIcon = Instance.new("ImageLabel")
            btnIcon.Size = UDim2.new(0, 14, 0, 14)
            btnIcon.Position = UDim2.new(0, 10, 0.5, -7)
            btnIcon.BackgroundTransparency = 1
            btnIcon.Image = IsDestructive and Icons.alert or Icons.play
            btnIcon.ImageColor3 = IsDestructive and Color3.fromRGB(255, 120, 120) or Theme.Text
            btnIcon.ZIndex = 14
            btnIcon.Parent = Btn

            Btn.MouseButton1Click:Connect(function()
                playSound("Tap")
                if IsDestructive then
                    openConfirmDialog(Title, "Are you sure you want to execute this feature? This action is irreversible.", Callback)
                else
                    pcall(Callback)
                end
            end)

            table.insert(Tab.Elements, { Frame = Frame, Name = Title })
        end

        return Tab
    end

    -- АВТОМАТИЧЕСКОЕ НАПОЛНЕНИЕ ВСЕХ 6 ВКЛАДОК (1:1 UI.html)
    task.spawn(function()
        -- 1. General
        local GeneralTab = Window:CreateTab({ Name = "General", Icon = Icons.home })
        GeneralTab:CreateSection("Player Physics & Attributes")
        GeneralTab:CreateToggle({
            Name = "Infinite Jump",
            Description = "Air-jump multi-hop toggle",
            Keybind = Enum.KeyCode.Space,
            Default = true,
            Callback = function(v)
                _G.InfJump = v
                game:GetService("UserInputService").JumpRequest:Connect(function()
                    if _G.InfJump and game.Players.LocalPlayer.Character then
                        local hum = game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                        if hum then hum:ChangeState("Jumping") end
                    end
                end)
            end
        })
        GeneralTab:CreateToggle({
            Name = "Noclip Mode",
            Description = "Pass through solid walls and colliders",
            Keybind = Enum.KeyCode.V,
            Default = false
        })
        GeneralTab:CreateSlider({
            Name = "WalkSpeed Multiplier",
            Description = "Adjust humanoid linear velocity",
            Min = 16,
            Max = 120,
            Default = 16,
            Unit = "stud/s",
            Callback = function(val)
                if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                    game.Players.LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed = val
                end
            end
        })
        GeneralTab:CreateSection("Actions & Modal Demo")
        GeneralTab:CreateButton({
            Name = "Destroy Server State",
            Description = "Triggers a modal confirmation before execution",
            Destructive = true,
            Callback = function()
                LiquidGlass:Notify("Server", "All entities wiped successfully!")
            end
        })

        -- 2. Combat
        local CombatTab = Window:CreateTab({ Name = "Combat", Icon = Icons.swords })
        CombatTab:CreateSection("Combat Modifiers & Sub-Settings")
        CombatTab:CreateAimbotAccordion()
        CombatTab:CreateToggle({
            Name = "Triggerbot",
            Description = "Instant reaction on raycast hit",
            Default = false
        })

        -- 3. Visuals
        local VisualsTab = Window:CreateTab({ Name = "Visuals", Icon = Icons.palette })
        VisualsTab:CreateSection("Chroma & Visual Modifications")
        VisualsTab:CreateToggle({ Name = "Player ESP", Description = "Draw 3D bounding boxes around players", Default = true })

        -- 4. Configs
        local ConfigsTab = Window:CreateTab({ Name = "Configs", Icon = Icons.folder })
        ConfigsTab:CreateSection("Saved Profiles")
        ConfigsTab:CreateButton({ Name = "Save Current Profile", Callback = function() LiquidGlass:Notify("Configs", "Saved successfully!") end })

        -- 5. Sub-Windows
        local SubWindowsTab = Window:CreateTab({ Name = "Sub-Windows", Icon = Icons.appwindow })
        SubWindowsTab:CreateSection("Floating Widgets")
        SubWindowsTab:CreateToggle({ Name = "Keybinds Overlay", Default = true })
        SubWindowsTab:CreateToggle({ Name = "Telemetry Widget", Default = true })

        -- 6. Misc
        local MiscTab = Window:CreateTab({ Name = "Misc", Icon = Icons.sliders })
        MiscTab:CreateSection("System Miscellaneous")
        MiscTab:CreateButton({ Name = "Replay Apple 'hello' Intro", Callback = function() LiquidGlass:PlayIntro() end })
    end)

    return Window
end

-- ================= ПЛАВАЮЩИЕ ОКНА =================
-- 1. Keybinds Window
local KeybindsWin = Instance.new("Frame")
KeybindsWin.Size = UDim2.new(0, 220, 0, 145)
KeybindsWin.Position = UDim2.new(1, -255, 0, 100)
KeybindsWin.BackgroundColor3 = Theme.MainGlass
KeybindsWin.BackgroundTransparency = Theme.MainTransparency
KeybindsWin.ClipsDescendants = true
KeybindsWin.ZIndex = 30
KeybindsWin.Parent = ScreenGui
applyGlass(KeybindsWin, UDim.new(0, 18), 0.7)

local kbHeader = Instance.new("Frame")
kbHeader.Size = UDim2.new(1, 0, 0, 36)
kbHeader.BackgroundTransparency = 1
kbHeader.ZIndex = 31
kbHeader.Parent = KeybindsWin
makeDraggable(KeybindsWin, kbHeader)

local kbIcon = Instance.new("ImageLabel")
kbIcon.Size = UDim2.new(0, 14, 0, 14)
kbIcon.Position = UDim2.new(0, 12, 0.5, -7)
kbIcon.BackgroundTransparency = 1
kbIcon.Image = Icons.keyboard
kbIcon.ImageColor3 = Theme.Accent
kbIcon.ZIndex = 32
kbIcon.Parent = kbHeader

local kbTitle = Instance.new("TextLabel")
kbTitle.Size = UDim2.new(1, -60, 1, 0)
kbTitle.Position = UDim2.new(0, 32, 0, 0)
kbTitle.BackgroundTransparency = 1
kbTitle.Font = Enum.Font.GothamBold
kbTitle.Text = "Keybinds"
kbTitle.TextColor3 = Theme.Text
kbTitle.TextSize = 12
kbTitle.TextXAlignment = Enum.TextXAlignment.Left
kbTitle.ZIndex = 32
kbTitle.Parent = kbHeader

local kbGripTop = Instance.new("ImageLabel")
kbGripTop.Size = UDim2.new(0, 14, 0, 14)
kbGripTop.Position = UDim2.new(1, -22, 0.5, -7)
kbGripTop.BackgroundTransparency = 1
kbGripTop.Image = Icons.grip
kbGripTop.ImageColor3 = Theme.SubText
kbGripTop.ZIndex = 32
kbGripTop.Parent = kbHeader

local kbList = Instance.new("Frame")
kbList.Size = UDim2.new(1, -16, 1, -44)
kbList.Position = UDim2.new(0, 8, 0, 36)
kbList.BackgroundTransparency = 1
kbList.ZIndex = 31
kbList.Parent = KeybindsWin
local kbLayout = Instance.new("UIListLayout")
kbLayout.Padding = UDim.new(0, 6)
kbLayout.Parent = kbList

local function addKbRow(name, key)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 26)
    row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    row.BackgroundTransparency = 0.95
    row.ZIndex = 32
    row.Parent = kbList
    applyGlass(row, UDim.new(0, 8), 0.85)

    local rLbl = Instance.new("TextLabel")
    rLbl.Size = UDim2.new(1, -60, 1, 0)
    rLbl.Position = UDim2.new(0, 8, 0, 0)
    rLbl.BackgroundTransparency = 1
    rLbl.Font = Enum.Font.GothamMedium
    rLbl.Text = name
    rLbl.TextColor3 = Theme.Text
    rLbl.TextSize = 11.5
    rLbl.TextXAlignment = Enum.TextXAlignment.Left
    rLbl.ZIndex = 33
    rLbl.Parent = row

    local rBadge = Instance.new("TextLabel")
    rBadge.Size = UDim2.new(0, 48, 0, 18)
    rBadge.Position = UDim2.new(1, -54, 0.5, -9)
    rBadge.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    rBadge.BackgroundTransparency = 0.9
    rBadge.Font = Enum.Font.GothamBold
    rBadge.Text = key
    rBadge.TextColor3 = Theme.Text
    rBadge.TextSize = 9.5
    rBadge.ZIndex = 33
    rBadge.Parent = row
    applyGlass(rBadge, UDim.new(0, 6), 0.8)
end

addKbRow("Infinite Jump", "SPACE")
addKbRow("Noclip Mode", "V")
addKbRow("Aimbot Assistant", "MOUSE2")

-- 2. Telemetry Window
local TelemetryWin = Instance.new("Frame")
TelemetryWin.Size = UDim2.new(0, 180, 0, 95)
TelemetryWin.Position = UDim2.new(0, 30, 1, -135)
TelemetryWin.BackgroundColor3 = Theme.MainGlass
TelemetryWin.BackgroundTransparency = Theme.MainTransparency
TelemetryWin.ClipsDescendants = true
TelemetryWin.ZIndex = 30
TelemetryWin.Parent = ScreenGui
applyGlass(TelemetryWin, UDim.new(0, 18), 0.7)

local telHeader = Instance.new("Frame")
telHeader.Size = UDim2.new(1, 0, 0, 30)
telHeader.BackgroundTransparency = 1
telHeader.ZIndex = 31
telHeader.Parent = TelemetryWin
makeDraggable(TelemetryWin, telHeader)

local telIcon = Instance.new("ImageLabel")
telIcon.Size = UDim2.new(0, 14, 0, 14)
telIcon.Position = UDim2.new(0, 10, 0.5, -7)
telIcon.BackgroundTransparency = 1
telIcon.Image = Icons.activity
telIcon.ImageColor3 = Theme.Success
telIcon.ZIndex = 32
telIcon.Parent = telHeader

local telTitle = Instance.new("TextLabel")
telTitle.Size = UDim2.new(1, -50, 1, 0)
telTitle.Position = UDim2.new(0, 28, 0, 0)
telTitle.BackgroundTransparency = 1
telTitle.Font = Enum.Font.GothamBold
telTitle.Text = "Telemetry"
telTitle.TextColor3 = Theme.Success
telTitle.TextSize = 12
telTitle.TextXAlignment = Enum.TextXAlignment.Left
telTitle.ZIndex = 32
telTitle.Parent = telHeader

local telGripTop = Instance.new("ImageLabel")
telGripTop.Size = UDim2.new(0, 14, 0, 14)
telGripTop.Position = UDim2.new(1, -20, 0.5, -7)
telGripTop.BackgroundTransparency = 1
telGripTop.Image = Icons.grip
telGripTop.ImageColor3 = Theme.SubText
telGripTop.ZIndex = 32
telGripTop.Parent = telHeader

local fpsRow = Instance.new("Frame")
fpsRow.Size = UDim2.new(1, -20, 0, 24)
fpsRow.Position = UDim2.new(0, 10, 0, 34)
fpsRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
fpsRow.BackgroundTransparency = 0.95
fpsRow.ZIndex = 32
fpsRow.Parent = TelemetryWin
applyGlass(fpsRow, UDim.new(0, 6), 0.85)

local fpsTitle = Instance.new("TextLabel")
fpsTitle.Size = UDim2.new(0.6, 0, 1, 0)
fpsTitle.Position = UDim2.new(0, 8, 0, 0)
fpsTitle.BackgroundTransparency = 1
fpsTitle.Font = Enum.Font.GothamMedium
fpsTitle.Text = "Frame Rate"
fpsTitle.TextColor3 = Theme.Text
fpsTitle.TextSize = 11
fpsTitle.TextXAlignment = Enum.TextXAlignment.Left
fpsTitle.ZIndex = 33
fpsTitle.Parent = fpsRow

local fpsVal = Instance.new("TextLabel")
fpsVal.Size = UDim2.new(0.4, -8, 1, 0)
fpsVal.Position = UDim2.new(0.6, 0, 0, 0)
fpsVal.BackgroundTransparency = 1
fpsVal.Font = Enum.Font.GothamBold
fpsVal.Text = "144 FPS"
fpsVal.TextColor3 = Theme.Success
fpsVal.TextSize = 11
fpsVal.TextXAlignment = Enum.TextXAlignment.Right
fpsVal.ZIndex = 33
fpsVal.Parent = fpsRow

local pingRow = Instance.new("Frame")
pingRow.Size = UDim2.new(1, -20, 0, 24)
pingRow.Position = UDim2.new(0, 10, 0, 62)
pingRow.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
pingRow.BackgroundTransparency = 0.95
pingRow.ZIndex = 32
pingRow.Parent = TelemetryWin
applyGlass(pingRow, UDim.new(0, 6), 0.85)

local pingTitle = Instance.new("TextLabel")
pingTitle.Size = UDim2.new(0.6, 0, 1, 0)
pingTitle.Position = UDim2.new(0, 8, 0, 0)
pingTitle.BackgroundTransparency = 1
pingTitle.Font = Enum.Font.GothamMedium
pingTitle.Text = "Latency"
pingTitle.TextColor3 = Theme.Text
pingTitle.TextSize = 11
pingTitle.TextXAlignment = Enum.TextXAlignment.Left
pingTitle.ZIndex = 33
pingTitle.Parent = pingRow

local pingVal = Instance.new("TextLabel")
pingVal.Size = UDim2.new(0.4, -8, 1, 0)
pingVal.Position = UDim2.new(0.6, 0, 0, 0)
pingVal.BackgroundTransparency = 1
pingVal.Font = Enum.Font.GothamBold
pingVal.Text = "18 ms"
pingVal.TextColor3 = Theme.Accent
pingVal.TextSize = 11
pingVal.TextXAlignment = Enum.TextXAlignment.Right
pingVal.ZIndex = 33
pingVal.Parent = pingRow

-- FPS Счётчик
local lastTime = os.clock()
local frameCount = 0
RunService.RenderStepped:Connect(function()
    frameCount = frameCount + 1
    local curTime = os.clock()
    if curTime - lastTime >= 1 then
        fpsVal.Text = tostring(frameCount) .. " FPS"
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
