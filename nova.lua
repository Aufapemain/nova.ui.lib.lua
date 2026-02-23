--[[
    ███╗   ██╗ ██████╗ ██╗   ██╗ █████╗ 
    ████╗  ██║██╔═══██╗██║   ██║██╔══██╗
    ██╔██╗ ██║██║   ██║██║   ██║███████║
    ██║╚██╗██║██║   ██║╚██╗ ██╔╝██╔══██║
    ██║ ╚████║╚██████╔╝ ╚████╔╝ ██║  ██║
    ╚═╝  ╚═══╝ ╚═════╝   ╚═══╝  ╚═╝  ╚═╝

    NOVA UI LIBRARY v1.0
    Designed for Executors
    Feat: Window, Tabs, Sections, Buttons, Toggles, Sliders,
          Dropdowns, Keybinds, ColorPickers, Inputs, Labels,
          Notifications, Config Saver, Themes, and more.
]]

local Nova = {}
Nova.__index = Nova

-- Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Utility functions
local function Create(className, props, children)
    local obj = Instance.new(className)
    for k, v in pairs(props or {}) do
        obj[k] = v
    end
    for _, child in ipairs(children or {}) do
        child.Parent = obj
    end
    return obj
end

local function AddShadow(frame, intensity, transparency)
    intensity = intensity or 5
    transparency = transparency or 0.7
    for i = 1, intensity do
        local shadow = Create("Frame", {
            Name = "Shadow",
            BackgroundColor3 = Color3.new(0,0,0),
            BackgroundTransparency = transparency - (i * 0.1),
            Size = frame.Size + UDim2.new(0, i*2, 0, i*2),
            Position = frame.Position - UDim2.new(0, i, 0, i),
            AnchorPoint = frame.AnchorPoint,
            BorderSizePixel = 0,
            ZIndex = frame.ZIndex - i,
            Parent = frame.Parent,
        }, {
            Create("UICorner", { CornerRadius = UDim.new(0, (frame:FindFirstChildOfClass("UICorner") and frame:FindFirstChildOfClass("UICorner").CornerRadius.Offset or 12) + i) })
        })
    end
end

-- Icon library (Lucide-like, using asset IDs)
local Icons = {
    home = "rbxassetid://10747319789",
    settings = "rbxassetid://10747319789",
    toggle = "rbxassetid://10747319789",
    slider = "rbxassetid://10747319789",
    dropdown = "rbxassetid://10747319789",
    keybind = "rbxassetid://10747319789",
    color = "rbxassetid://10747319789",
    input = "rbxassetid://10747319789",
    label = "rbxassetid://10747319789",
    button = "rbxassetid://10747319789",
    notify = "rbxassetid://10747319789",
    close = "rbxassetid://10747312666",
    minimize = "rbxassetid://10747308083",
    maximize = "rbxassetid://11036884234",
    search = "rbxassetid://10747319789",
    -- add more as needed
}

-- ========== THEMES ==========
Nova.Themes = {
    Dark = {
        Name = "Dark",
        Background = Color3.fromRGB(20,20,25),
        Surface = Color3.fromRGB(30,30,35),
        Primary = Color3.fromRGB(45,45,50),
        Secondary = Color3.fromRGB(55,55,60),
        Accent = Color3.fromRGB(100,150,255),
        AccentLight = Color3.fromRGB(130,180,255),
        Text = Color3.fromRGB(255,255,255),
        TextMuted = Color3.fromRGB(180,180,190),
        Danger = Color3.fromRGB(255,80,80),
        Success = Color3.fromRGB(80,255,80),
        Stroke = Color3.fromRGB(70,70,80),
        Shadow = Color3.new(0,0,0),
    },
    Light = {
        Name = "Light",
        Background = Color3.fromRGB(240,240,245),
        Surface = Color3.fromRGB(255,255,255),
        Primary = Color3.fromRGB(230,230,235),
        Secondary = Color3.fromRGB(220,220,225),
        Accent = Color3.fromRGB(0,100,200),
        AccentLight = Color3.fromRGB(50,150,250),
        Text = Color3.fromRGB(20,20,20),
        TextMuted = Color3.fromRGB(100,100,100),
        Danger = Color3.fromRGB(200,50,50),
        Success = Color3.fromRGB(50,180,50),
        Stroke = Color3.fromRGB(150,150,150),
        Shadow = Color3.fromRGB(100,100,100),
    },
    Midnight = {
        Name = "Midnight",
        Background = Color3.fromRGB(10,10,15),
        Surface = Color3.fromRGB(20,20,25),
        Primary = Color3.fromRGB(30,30,40),
        Secondary = Color3.fromRGB(40,40,50),
        Accent = Color3.fromRGB(80,180,255),
        AccentLight = Color3.fromRGB(120,210,255),
        Text = Color3.fromRGB(240,240,240),
        TextMuted = Color3.fromRGB(150,150,160),
        Danger = Color3.fromRGB(255,70,70),
        Success = Color3.fromRGB(70,255,70),
        Stroke = Color3.fromRGB(60,60,80),
        Shadow = Color3.new(0,0,0),
    }
}
Nova.SelectedTheme = Nova.Themes.Dark

-- Configuration storage
Nova.Flags = {}
Nova.ConfigFolder = "NovaConfigs"
Nova.ConfigEnabled = false
Nova.ConfigName = ""

-- ========== WINDOW CREATION ==========
function Nova:CreateWindow(config)
    config = config or {}
    local self = setmetatable({}, Nova)

    self.Title = config.Title or "Nova UI"
    self.Size = config.Size or UDim2.new(0, 600, 0, 400)
    self.Theme = config.Theme and Nova.Themes[config.Theme] or Nova.SelectedTheme
    self.Keybind = config.Keybind or "RightShift"
    self.ConfigEnabled = config.ConfigurationSaving and config.ConfigurationSaving.Enabled or false
    self.ConfigName = config.ConfigurationSaving and config.ConfigurationSaving.FileName or tostring(game.PlaceId)
    self.ConfigFolder = config.ConfigurationSaving and config.ConfigurationSaving.FolderName or Nova.ConfigFolder
    self.DiscordInvite = config.Discord and config.Discord.Invite
    self.DiscordEnabled = config.Discord and config.Discord.Enabled
    self.KeySystem = config.KeySystem or false
    self.KeySettings = config.KeySettings or {}

    self.Flags = {}
    self.Tabs = {}
    self.CurrentTab = nil
    self.Minimized = false
    self.Hidden = false
    self.Debounce = false

    -- Main GUI
    self.Gui = Create("ScreenGui", {
        Name = "NovaUI_" .. math.random(1000,9999),
        Parent = (gethui and gethui()) or game:GetService("CoreGui"),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 100
    })

    -- Protect GUI if possible
    if syn and syn.protect_gui then
        syn.protect_gui(self.Gui)
    end

    -- Main Window Frame
    self.Window = Create("Frame", {
        BackgroundColor3 = self.Theme.Background,
        Size = self.Size,
        Position = UDim2.new(0.5, -self.Size.X.Offset/2, 0.5, -self.Size.Y.Offset/2),
        AnchorPoint = Vector2.new(0,0),
        BorderSizePixel = 0,
        ClipsDescendants = true,
        Parent = self.Gui,
        ZIndex = 10,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,16) })
    })
    AddShadow(self.Window, 6, 0.8)

    -- Title Bar
    self.TitleBar = Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        Size = UDim2.new(1,0,0,45),
        BorderSizePixel = 0,
        Parent = self.Window,
        ZIndex = 11,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,16) })
    })

    -- Title
    self.TitleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-90,1,0),
        Position = UDim2.new(0,20,0,0),
        Text = self.Title,
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = self.TitleBar,
        ZIndex = 12
    })

    -- Window Controls
    self.ControlFrame = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,90,1,0),
        Position = UDim2.new(1,-90,0,0),
        Parent = self.TitleBar,
        ZIndex = 12
    })

    -- Minimize Button
    self.MinBtn = Create("ImageButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,30,0,30),
        Position = UDim2.new(0,10,0.5,-15),
        Image = Icons.minimize,
        ImageColor3 = self.Theme.Text,
        Parent = self.ControlFrame,
        ZIndex = 13
    })

    -- Close Button
    self.CloseBtn = Create("ImageButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,30,0,30),
        Position = UDim2.new(0,50,0.5,-15),
        Image = Icons.close,
        ImageColor3 = self.Theme.Text,
        Parent = self.ControlFrame,
        ZIndex = 13
    })

    -- Tab Container
    self.TabContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,45),
        Position = UDim2.new(0,10,0,50),
        Parent = self.Window,
        ZIndex = 11,
    }, {
        Create("UIListLayout", {
            FillDirection = Enum.FillDirection.Horizontal,
            HorizontalAlignment = Enum.HorizontalAlignment.Left,
            VerticalAlignment = Enum.VerticalAlignment.Center,
            Padding = UDim.new(0,8)
        }),
        Create("UIPadding", { PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5) })
    })

    -- Page Container
    self.PageContainer = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,1,-105),
        Position = UDim2.new(0,10,0,100),
        Parent = self.Window,
        ZIndex = 11,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,12) })
    })

    -- ===== DRAGGABLE =====
    local dragging = false
    local dragInput, dragStart, startPos

    self.TitleBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = self.Window.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)

    self.TitleBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(self.Window, TweenInfo.new(0.45, Enum.EasingStyle.Quint), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
            AddShadow(self.Window, 6, 0.8)
        end
    end)

    -- ===== CLOSE & MINIMIZE =====
    self.CloseBtn.MouseButton1Click:Connect(function()
        self:Destroy()
    end)

    self.MinBtn.MouseButton1Click:Connect(function()
        self.Minimized = not self.Minimized
        if self.Minimized then
            self.Window:TweenSize(UDim2.new(0, self.Window.Size.X.Offset, 0, 45), "Out", "Quint", 0.3)
            self.PageContainer.Visible = false
            self.TabContainer.Visible = false
        else
            self.Window:TweenSize(self.Size, "Out", "Quint", 0.3)
            task.wait(0.3)
            self.PageContainer.Visible = true
            self.TabContainer.Visible = true
        end
        AddShadow(self.Window, 6, 0.8)
    end)

    -- Hover effects on buttons
    for _, btn in pairs({self.MinBtn, self.CloseBtn}) do
        btn.MouseEnter:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {ImageColor3 = self.Theme.Accent}):Play()
        end)
        btn.MouseLeave:Connect(function()
            TweenService:Create(btn, TweenInfo.new(0.2), {ImageColor3 = self.Theme.Text}):Play()
        end)
    end

    -- Toggle UI with keybind
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode[self.Keybind] then
            self.Hidden = not self.Hidden
            self.Window.Visible = not self.Window.Visible
        end
    end)

    -- Handle key system if enabled
    if self.KeySystem then
        self:HandleKeySystem()
    end

    return self
end

-- ========== KEY SYSTEM ==========
function Nova:HandleKeySystem()
    -- Implementation of key system (simplified, can be expanded)
    local keyUI = Instance.new("ScreenGui")
    keyUI.Parent = self.Gui.Parent
    keyUI.Name = "NovaKeyUI"
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0,400,0,200)
    frame.Position = UDim2.new(0.5,-200,0.5,-100)
    frame.BackgroundColor3 = self.Theme.Surface
    frame.BorderSizePixel = 0
    frame.Parent = keyUI
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,12)
    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-20,0,30)
    title.Position = UDim2.new(0,10,0,10)
    title.Text = self.KeySettings.Title or "Key System"
    title.TextColor3 = self.Theme.Text
    title.Font = Enum.Font.GothamBold
    title.TextSize = 20
    title.BackgroundTransparency = 1
    local input = Instance.new("TextBox", frame)
    input.Size = UDim2.new(1,-40,0,35)
    input.Position = UDim2.new(0,20,0,50)
    input.PlaceholderText = "Enter key"
    input.Text = ""
    input.BackgroundColor3 = self.Theme.Primary
    input.TextColor3 = self.Theme.Text
    Instance.new("UICorner", input).CornerRadius = UDim.new(0,6)
    local button = Instance.new("TextButton", frame)
    button.Size = UDim2.new(0,120,0,35)
    button.Position = UDim2.new(0.5,-60,0,100)
    button.Text = "Submit"
    button.BackgroundColor3 = self.Theme.Accent
    button.TextColor3 = self.Theme.Text
    Instance.new("UICorner", button).CornerRadius = UDim.new(0,6)
    button.MouseButton1Click:Connect(function()
        -- Check key
        for _, validKey in ipairs(self.KeySettings.Key or {}) do
            if input.Text == validKey then
                keyUI:Destroy()
                return
            end
        end
        -- Failed
        input.Text = ""
    end)
    -- Wait until keyUI is destroyed
    repeat task.wait() until keyUI.Parent == nil
end

-- ========== TAB CREATION ==========
function Nova:CreateTab(name, icon)
    local self = self -- closure
    local tabBtn = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        BackgroundTransparency = 0.7,
        Size = UDim2.new(0,120,0,35),
        Parent = self.TabContainer,
        ZIndex = 12,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,10) })
    })

    local interact = Create("TextButton", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        Text = "",
        Parent = tabBtn,
        ZIndex = 13
    })

    local iconImg
    if icon and icon ~= "" then
        iconImg = Create("ImageLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(0,20,0,20),
            Position = UDim2.new(0,8,0.5,-10),
            Image = icon,
            ImageColor3 = self.Theme.TextMuted,
            Parent = tabBtn,
            ZIndex = 13
        })
    end

    local tabText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1, - (icon and 35 or 10), 1,0),
        Position = UDim2.new(0, icon and 35 or 10, 0,0),
        Text = name,
        TextColor3 = self.Theme.TextMuted,
        Font = Enum.Font.Gotham,
        TextSize = 15,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = tabBtn,
        ZIndex = 13
    })

    -- Page
    local page = Create("ScrollingFrame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,1,0),
        CanvasSize = UDim2.new(0,0,0,0),
        ScrollBarThickness = 5,
        ScrollBarImageColor3 = self.Theme.Accent,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Visible = false,
        Parent = self.PageContainer,
        ZIndex = 12,
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,10) }),
        Create("UIPadding", { PaddingTop = UDim.new(0,10), PaddingBottom = UDim.new(0,10), PaddingLeft = UDim.new(0,10), PaddingRight = UDim.new(0,10) })
    })

    local tabData = {
        Name = name,
        Button = tabBtn,
        Page = page,
        Text = tabText,
        Icon = iconImg
    }
    table.insert(self.Tabs, tabData)

    -- Select first tab automatically
    if #self.Tabs == 1 then
        self:SelectTab(tabData)
    end

    -- Tab selection
    interact.MouseButton1Click:Connect(function()
        self:SelectTab(tabData)
    end)

    -- Hover
    tabBtn.MouseEnter:Connect(function()
        if self.CurrentTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.3}):Play()
            TweenService:Create(tabText, TweenInfo.new(0.2), {TextColor3 = self.Theme.Text}):Play()
            if iconImg then
                TweenService:Create(iconImg, TweenInfo.new(0.2), {ImageColor3 = self.Theme.Text}):Play()
            end
        end
    end)

    tabBtn.MouseLeave:Connect(function()
        if self.CurrentTab ~= tabData then
            TweenService:Create(tabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.7}):Play()
            TweenService:Create(tabText, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextMuted}):Play()
            if iconImg then
                TweenService:Create(iconImg, TweenInfo.new(0.2), {ImageColor3 = self.Theme.TextMuted}):Play()
            end
        end
    end)

    return page
end

function Nova:SelectTab(tab)
    if self.CurrentTab then
        TweenService:Create(self.CurrentTab.Button, TweenInfo.new(0.2), {BackgroundTransparency = 0.7}):Play()
        TweenService:Create(self.CurrentTab.Text, TweenInfo.new(0.2), {TextColor3 = self.Theme.TextMuted}):Play()
        if self.CurrentTab.Icon then
            TweenService:Create(self.CurrentTab.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Theme.TextMuted}):Play()
        end
        self.CurrentTab.Page.Visible = false
    end

    self.CurrentTab = tab
    TweenService:Create(tab.Button, TweenInfo.new(0.2), {BackgroundTransparency = 0, BackgroundColor3 = self.Theme.Accent}):Play()
    TweenService:Create(tab.Text, TweenInfo.new(0.2), {TextColor3 = self.Theme.Text}):Play()
    if tab.Icon then
        TweenService:Create(tab.Icon, TweenInfo.new(0.2), {ImageColor3 = self.Theme.Text}):Play()
    end
    tab.Page.Visible = true
end

-- ========== SECTION ==========
function Nova:CreateSection(parent, title)
    local section = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
        ZIndex = 13
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,5) }),
        Create("UIPadding", { PaddingLeft = UDim.new(0,5), PaddingRight = UDim.new(0,5), PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,5) })
    })

    local titleLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,25),
        Text = title,
        TextColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 18,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = section,
        ZIndex = 14
    })

    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = section,
        ZIndex = 14,
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,8) })
    })

    return container
end

-- ========== BUTTON ==========
function Nova:CreateButton(parent, config)
    local btn = Create("TextButton", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,40),
        Text = "",
        AutoButtonColor = false,
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,1,0),
        Position = UDim2.new(0,10,0,0),
        Text = config.Name or "Button",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = btn,
        ZIndex = 16
    })

    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Secondary}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Primary}):Play()
    end)

    btn.MouseButton1Click:Connect(function()
        config.Callback and pcall(config.Callback)
    end)

    return btn
end

-- ========== TOGGLE ==========
function Nova:CreateToggle(parent, config)
    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,40),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local text = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-70,1,0),
        Position = UDim2.new(0,12,0,0),
        Text = config.Name or "Toggle",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local switch = Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        Size = UDim2.new(0,50,0,24),
        Position = UDim2.new(1,-60,0.5,-12),
        BorderSizePixel = 0,
        Parent = frame,
        ZIndex = 16,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1,0) })
    })

    local knob = Create("Frame", {
        BackgroundColor3 = self.Theme.Text,
        Size = UDim2.new(0,20,0,20),
        Position = UDim2.new(0,2,0.5,-10),
        BorderSizePixel = 0,
        Parent = switch,
        ZIndex = 17,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1,0) })
    })

    local state = config.Default or false
    local flag = config.Flag

    local function setState(newState)
        state = newState
        if state then
            TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Accent}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(1,-22,0.5,-10), BackgroundColor3 = self.Theme.Text}):Play()
        else
            TweenService:Create(switch, TweenInfo.new(0.2), {BackgroundColor3 = self.Theme.Secondary}):Play()
            TweenService:Create(knob, TweenInfo.new(0.2), {Position = UDim2.new(0,2,0.5,-10), BackgroundColor3 = self.Theme.TextMuted}):Play()
        end
        if flag then self.Flags[flag] = state end
        if config.Callback then config.Callback(state) end
    end

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            setState(not state)
        end
    end)

    setState(state)

    return { Set = setState, Get = function() return state end }
end

-- ========== SLIDER ==========
function Nova:CreateSlider(parent, config)
    local min = config.Min or 0
    local max = config.Max or 100
    local default = config.Default or min
    local suffix = config.Suffix or ""
    local decimals = config.Decimals or 0

    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,70),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,25),
        Position = UDim2.new(0,12,0,8),
        Text = config.Name or "Slider",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local valueLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,25),
        Position = UDim2.new(0,12,0,30),
        Text = tostring(default) .. " " .. suffix,
        TextColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local track = Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        Size = UDim2.new(1,-24,0,6),
        Position = UDim2.new(0,12,0,55),
        BorderSizePixel = 0,
        Parent = frame,
        ZIndex = 16,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1,0) })
    })

    local fill = Create("Frame", {
        BackgroundColor3 = self.Theme.Accent,
        Size = UDim2.new(0,0,1,0),
        BorderSizePixel = 0,
        Parent = track,
        ZIndex = 17,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1,0) })
    })

    local knob = Create("Frame", {
        BackgroundColor3 = self.Theme.Text,
        Size = UDim2.new(0,20,0,20),
        Position = UDim2.new(0,-10,0.5,-10),
        BorderSizePixel = 0,
        Parent = track,
        ZIndex = 18,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(1,0) })
    })

    local value = default
    local dragging = false
    local flag = config.Flag

    local function updateFromMouse(inputPos)
        local trackPos = track.AbsolutePosition
        local trackSize = track.AbsoluteSize
        local relX = math.clamp(inputPos.X - trackPos.X, 0, trackSize.X)
        local percent = relX / trackSize.X
        value = min + percent * (max - min)
        if decimals > 0 then
            local mult = 10^decimals
            value = math.round(value * mult) / mult
        else
            value = math.round(value)
        end
        value = math.clamp(value, min, max)

        local fillWidth = (value - min) / (max - min) * trackSize.X
        fill.Size = UDim2.new(0, fillWidth, 1, 0)
        knob.Position = UDim2.new(0, fillWidth - 10, 0.5, -10)
        valueLabel.Text = tostring(value) .. " " .. suffix

        if flag then self.Flags[flag] = value end
        if config.Callback then config.Callback(value) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromMouse(input.Position)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromMouse(input.Position)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)

    -- Initialize
    updateFromMouse({Position = Vector2.new(
        track.AbsolutePosition.X + ((default - min) / (max - min) * track.AbsoluteSize.X),
        track.AbsolutePosition.Y
    )})

    return { Set = function(v) value = v; updateFromMouse({Position = Vector2.new(
        track.AbsolutePosition.X + ((v - min) / (max - min) * track.AbsoluteSize.X),
        track.AbsolutePosition.Y
    )}) end, Get = function() return value end }
end

-- ========== DROPDOWN ==========
function Nova:CreateDropdown(parent, config)
    local items = config.Items or {}
    local default = config.Default or items[1]
    local multi = config.Multi or false
    local flag = config.Flag

    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,45),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-100,1,0),
        Position = UDim2.new(0,12,0,0),
        Text = config.Name or "Dropdown",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local selectedText = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,100,1,0),
        Position = UDim2.new(1,-120,0,0),
        Text = multi and (default and table.concat(default, ", ") or "None") or (default or "None"),
        TextColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame,
        ZIndex = 16
    })

    local arrow = Create("ImageLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,20,0,20),
        Position = UDim2.new(1,-30,0.5,-10),
        Image = "rbxassetid://10747302107", -- down arrow
        ImageColor3 = self.Theme.TextMuted,
        Parent = frame,
        ZIndex = 16
    })

    local menu = Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        Size = UDim2.new(0,200,0,0),
        Position = UDim2.new(0, frame.AbsolutePosition.X + 10, 0, frame.AbsolutePosition.Y + 50),
        BorderSizePixel = 0,
        Visible = false,
        Parent = self.Gui,
        ZIndex = 20,
        ClipsDescendants = true,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,10) }),
        Create("UIListLayout", { Padding = UDim.new(0,2) }),
        Create("UIPadding", { PaddingTop = UDim.new(0,5), PaddingBottom = UDim.new(0,5) })
    })

    local selected = multi and (default or {}) or (default or nil)
    local isOpen = false

    -- Create option buttons
    local function refreshOptions()
        for _, child in ipairs(menu:GetChildren()) do
            if child:IsA("TextButton") then child:Destroy() end
        end
        for _, item in ipairs(items) do
            local optBtn = Create("TextButton", {
                BackgroundColor3 = self.Theme.Primary,
                BackgroundTransparency = 0.5,
                Size = UDim2.new(1,-10,0,35),
                Text = "",
                AutoButtonColor = false,
                Parent = menu,
                ZIndex = 21,
            }, {
                Create("UICorner", { CornerRadius = UDim.new(0,6) }),
                Create("TextLabel", {
                    BackgroundTransparency = 1,
                    Size = UDim2.new(1,-10,1,0),
                    Position = UDim2.new(0,5,0,0),
                    Text = item,
                    TextColor3 = self.Theme.Text,
                    Font = Enum.Font.Gotham,
                    TextSize = 14,
                    TextXAlignment = Enum.TextXAlignment.Left,
                    ZIndex = 22
                })
            })
            optBtn.MouseButton1Click:Connect(function()
                if multi then
                    if selected[item] then
                        selected[item] = nil
                    else
                        selected[item] = true
                    end
                    -- Update selected text
                    local keys = {}
                    for k in pairs(selected) do table.insert(keys, k) end
                    selectedText.Text = #keys > 0 and table.concat(keys, ", ") or "None"
                else
                    selected = item
                    selectedText.Text = item
                    -- Close menu
                    TweenService:Create(menu, TweenInfo.new(0.2), {Size = UDim2.new(0,200,0,0)}):Play()
                    wait(0.2)
                    menu.Visible = false
                    isOpen = false
                    arrow.Image = "rbxassetid://10747302107"
                end
                if flag then self.Flags[flag] = selected end
                if config.Callback then config.Callback(selected) end
            end)
        end
        -- Update menu size
        local count = #items
        menu.Size = UDim2.new(0,200,0,0)
        if count > 0 then
            menu.Size = UDim2.new(0,200,0, count * 37 + 10)
        end
    end
    refreshOptions()

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            if isOpen then
                TweenService:Create(menu, TweenInfo.new(0.2), {Size = UDim2.new(0,200,0,0)}):Play()
                wait(0.2)
                menu.Visible = false
                arrow.Image = "rbxassetid://10747302107"
            else
                menu.Position = UDim2.new(0, frame.AbsolutePosition.X + 10, 0, frame.AbsolutePosition.Y + 50)
                menu.Size = UDim2.new(0,200,0,0)
                menu.Visible = true
                TweenService:Create(menu, TweenInfo.new(0.2), {Size = UDim2.new(0,200,0, #items * 37 + 10)}):Play()
                arrow.Image = "rbxassetid://10747299867" -- up arrow
            end
            isOpen = not isOpen
        end
    end)

    -- Update menu position if window moves
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if menu.Visible then
            menu.Position = UDim2.new(0, frame.AbsolutePosition.X + 10, 0, frame.AbsolutePosition.Y + 50)
        end
    end)
    frame.Destroying:Connect(function() if connection then connection:Disconnect() end end)

    return { Set = function(val) selected = val; selectedText.Text = multi and (val and table.concat(val, ", ") or "None") or val end, Get = function() return selected end }
end

-- ========== KEYBIND ==========
function Nova:CreateKeybind(parent, config)
    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,45),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-120,1,0),
        Position = UDim2.new(0,12,0,0),
        Text = config.Name or "Keybind",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local keyLabel = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(0,100,1,0),
        Position = UDim2.new(1,-120,0,0),
        Text = config.Default or "None",
        TextColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Right,
        Parent = frame,
        ZIndex = 16
    })

    local listening = false
    local currentKey = config.Default or "None"
    local flag = config.Flag

    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            listening = true
            keyLabel.Text = "..."
        end
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if listening then
            if input.KeyCode ~= Enum.KeyCode.Unknown then
                currentKey = input.KeyCode.Name
                keyLabel.Text = currentKey
                listening = false
                if flag then self.Flags[flag] = currentKey end
                if config.Callback then config.Callback(currentKey) end
            elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                currentKey = "Mouse1"
                keyLabel.Text = currentKey
                listening = false
                if flag then self.Flags[flag] = currentKey end
                if config.Callback then config.Callback(currentKey) end
            end
        end
    end)

    return { Get = function() return currentKey end }
end

-- ========== COLORPICKER (simplified) ==========
function Nova:CreateColorPicker(parent, config)
    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,45),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-60,1,0),
        Position = UDim2.new(0,12,0,0),
        Text = config.Name or "Color",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local display = Create("Frame", {
        BackgroundColor3 = config.Default or Color3.new(1,0,0),
        Size = UDim2.new(0,30,0,30),
        Position = UDim2.new(1,-40,0.5,-15),
        BorderSizePixel = 0,
        Parent = frame,
        ZIndex = 16,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,6) }),
        Create("UIStroke", { Color = self.Theme.Text, Thickness = 1, Transparency = 0.5 })
    })

    local currentColor = config.Default or Color3.new(1,0,0)
    local flag = config.Flag

    display.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            -- Open a simple color picker (for demo, just random)
            local r = math.random()
            local g = math.random()
            local b = math.random()
            currentColor = Color3.new(r,g,b)
            display.BackgroundColor3 = currentColor
            if flag then self.Flags[flag] = currentColor end
            if config.Callback then config.Callback(currentColor) end
        end
    end)

    return { Set = function(c) currentColor = c; display.BackgroundColor3 = c end, Get = function() return currentColor end }
end

-- ========== INPUT ==========
function Nova:CreateInput(parent, config)
    local frame = Create("Frame", {
        BackgroundColor3 = self.Theme.Primary,
        Size = UDim2.new(1,0,0,70),
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,25),
        Position = UDim2.new(0,12,0,8),
        Text = config.Name or "Input",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = frame,
        ZIndex = 16
    })

    local inputFrame = Create("Frame", {
        BackgroundColor3 = self.Theme.Secondary,
        Size = UDim2.new(1,-24,0,35),
        Position = UDim2.new(0,12,0,35),
        BorderSizePixel = 0,
        Parent = frame,
        ZIndex = 16,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,8) })
    })

    local textbox = Create("TextBox", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-10,1,0),
        Position = UDim2.new(0,5,0,0),
        PlaceholderText = config.Placeholder or "Type...",
        PlaceholderColor3 = self.Theme.TextMuted,
        Text = config.Default or "",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 15,
        ClearTextOnFocus = false,
        Parent = inputFrame,
        ZIndex = 17
    })

    local flag = config.Flag
    textbox.FocusLost:Connect(function(enter)
        if flag then self.Flags[flag] = textbox.Text end
        if config.Callback then config.Callback(textbox.Text, enter) end
    end)

    return { Set = function(t) textbox.Text = t end, Get = function() return textbox.Text end }
end

-- ========== LABEL ==========
function Nova:CreateLabel(parent, text, color, size)
    color = color or self.Theme.Text
    size = size or 16
    local label = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,30),
        Text = text,
        TextColor3 = color,
        Font = Enum.Font.Gotham,
        TextSize = size,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = parent,
        ZIndex = 15
    })
    return label
end

-- ========== PARAGRAPH ==========
function Nova:CreateParagraph(parent, lines, color, size)
    color = color or self.Theme.TextMuted
    size = size or 14
    local container = Create("Frame", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,0,0,0),
        AutomaticSize = Enum.AutomaticSize.Y,
        Parent = parent,
        ZIndex = 15,
    }, {
        Create("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0,4) })
    })
    for _, line in ipairs(lines) do
        Create("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1,0,0,20),
            Text = line,
            TextColor3 = color,
            Font = Enum.Font.Gotham,
            TextSize = size,
            TextXAlignment = Enum.TextXAlignment.Left,
            Parent = container,
            ZIndex = 16
        })
    end
    return container
end

-- ========== NOTIFICATION ==========
function Nova:Notify(config)
    config = config or {}
    local notif = Create("Frame", {
        BackgroundColor3 = self.Theme.Surface,
        Size = UDim2.new(0,300,0,80),
        Position = UDim2.new(1,20,1,-20),
        AnchorPoint = Vector2.new(1,1),
        BorderSizePixel = 0,
        Parent = self.Gui,
        ZIndex = 200,
    }, {
        Create("UICorner", { CornerRadius = UDim.new(0,12) }),
        Create("UIStroke", { Color = self.Theme.Accent, Thickness = 2, Transparency = 0.3 })
    })

    local title = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,25),
        Position = UDim2.new(0,10,0,8),
        Text = config.Title or "Notification",
        TextColor3 = self.Theme.Accent,
        Font = Enum.Font.GothamBold,
        TextSize = 16,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
        ZIndex = 201
    })

    local content = Create("TextLabel", {
        BackgroundTransparency = 1,
        Size = UDim2.new(1,-20,0,40),
        Position = UDim2.new(0,10,0,35),
        Text = config.Content or "",
        TextColor3 = self.Theme.Text,
        Font = Enum.Font.Gotham,
        TextSize = 14,
        TextWrapped = true,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = notif,
        ZIndex = 201
    })

    notif.Position = UDim2.new(1,20,1,-20)
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(1,-320,1,-20)}):Play()
    task.wait(config.Duration or 5)
    TweenService:Create(notif, TweenInfo.new(0.4, Enum.EasingStyle.Exponential), {Position = UDim2.new(1,20,1,-20)}):Play()
    task.wait(0.4)
    notif:Destroy()
end

-- ========== CONFIGURATION SAVING ==========
function Nova:SaveConfig()
    if not self.ConfigEnabled then return end
    local data = {}
    for flag, value in pairs(self.Flags) do
        data[flag] = value
    end
    if not isfolder then return end
    if not isfolder(self.ConfigFolder) then
        makefolder(self.ConfigFolder)
    end
    writefile(self.ConfigFolder .. "/" .. self.ConfigName .. ".json", HttpService:JSONEncode(data))
end

function Nova:LoadConfig()
    if not self.ConfigEnabled then return end
    local path = self.ConfigFolder .. "/" .. self.ConfigName .. ".json"
    if isfile and isfile(path) then
        local data = HttpService:JSONDecode(readfile(path))
        for flag, value in pairs(data) do
            if self.Flags[flag] and self.Flags[flag].Set then
                self.Flags[flag]:Set(value)
            end
        end
    end
end

-- ========== DESTROY ==========
function Nova:Destroy()
    self.Gui:Destroy()
end

return Nova
