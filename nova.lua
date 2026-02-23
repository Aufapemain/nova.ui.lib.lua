--[[
    NOVA UI LIBRARY
    Version: 2.0.0
    Author: Nova Team
    License: MIT
    Description: Professional UI Library for Roblox with advanced features
--]]

local Nova = {}
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local HttpService = game:GetService("HttpService")

-- =============================================
-- CORE SYSTEM
-- =============================================

local GUI = Instance.new("ScreenGui")
GUI.Name = "NovaUI"
GUI.ResetOnSpawn = false
GUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
GUI.Parent = (syn and syn.protect_gui and (syn.protect_gui(GUI) or game:GetService("CoreGui"))) or 
             (gethui and gethui()) or 
             game:GetService("CoreGui")

-- Protect GUI from being removed
if syn and syn.protect_gui then
    syn.protect_gui(GUI)
end

-- =============================================
-- UTILITY FUNCTIONS
-- =============================================

local function SafeCallback(callback, ...)
    if not callback then return end
    local success, result = pcall(callback, ...)
    if not success then
        Nova:Notify({
            Title = "Callback Error",
            Content = tostring(result),
            Duration = 5,
            Icon = "alert-triangle"
        })
    end
    return result
end

local function Round(number, decimals)
    decimals = decimals or 0
    local mult = 10^decimals
    return math.floor(number * mult + 0.5) / mult
end

local function CloneTable(t)
    local clone = {}
    for k, v in pairs(t) do
        if type(v) == "table" then
            clone[k] = CloneTable(v)
        else
            clone[k] = v
        end
    end
    return clone
end

local function MergeTables(t1, t2)
    local merged = CloneTable(t1)
    for k, v in pairs(t2) do
        if type(v) == "table" and type(merged[k]) == "table" then
            merged[k] = MergeTables(merged[k], v)
        else
            merged[k] = v
        end
    end
    return merged
end

-- =============================================
-- ANIMATION ENGINE (NOVA MOTOR)
-- =============================================

local Motor = {}
Motor.__index = Motor

function Motor.new(initialValue, config)
    config = config or {}
    return setmetatable({
        _value = initialValue,
        _target = initialValue,
        _velocity = 0,
        _frequency = config.frequency or 5,
        _damping = config.damping or 0.8,
        _callback = nil,
        _connections = {}
    }, Motor)
end

function Motor:OnStep(callback)
    self._callback = callback
    callback(self._value)
end

function Motor:SetTarget(target)
    self._target = target
    if not self._connections.step then
        self._connections.step = RunService.RenderStepped:Connect(function(dt)
            self:Step(dt)
        end)
    end
end

function Motor:Step(dt)
    local freq = self._frequency * 2 * math.pi
    local damping = self._damping
    local error = self._target - self._value
    local acceleration = (error * freq * freq) - (2 * damping * freq * self._velocity)
    
    self._velocity = self._velocity + acceleration * dt
    self._value = self._value + self._velocity * dt
    
    if math.abs(error) < 0.001 and math.abs(self._velocity) < 0.001 then
        self._value = self._target
        self._velocity = 0
        if self._connections.step then
            self._connections.step:Disconnect()
            self._connections.step = nil
        end
    end
    
    if self._callback then
        self._callback(self._value)
    end
end

function Motor:Stop()
    if self._connections.step then
        self._connections.step:Disconnect()
        self._connections.step = nil
    end
end

-- =============================================
-- ICON SYSTEM (Lucide Icons + Custom)
-- =============================================

local Icons = {
    -- Navigation
    ["home"] = "rbxassetid://10723407389",
    ["settings"] = "rbxassetid://10734950309",
    ["menu"] = "rbxassetid://10734887784",
    ["chevron-down"] = "rbxassetid://10709790948",
    ["chevron-up"] = "rbxassetid://10709791523",
    ["chevron-left"] = "rbxassetid://10709791281",
    ["chevron-right"] = "rbxassetid://10709791437",
    ["x"] = "rbxassetid://10747384394",
    ["minimize"] = "rbxassetid://10734895698",
    ["maximize"] = "rbxassetid://10734886735",
    
    -- Common
    ["check"] = "rbxassetid://10709790644",
    ["check-circle"] = "rbxassetid://10709790387",
    ["alert-circle"] = "rbxassetid://10709752996",
    ["alert-triangle"] = "rbxassetid://10709753149",
    ["info"] = "rbxassetid://10723415903",
    ["question"] = "rbxassetid://10747365484",
    ["search"] = "rbxassetid://10734943674",
    ["edit"] = "rbxassetid://10734883598",
    ["trash"] = "rbxassetid://10747362393",
    ["copy"] = "rbxassetid://10709812159",
    ["save"] = "rbxassetid://10734941499",
    ["download"] = "rbxassetid://10723344270",
    ["upload"] = "rbxassetid://10747366434",
    ["refresh"] = "rbxassetid://10734933222",
    
    -- Media
    ["play"] = "rbxassetid://10734923549",
    ["pause"] = "rbxassetid://10734919336",
    ["stop"] = "rbxassetid://10734972621",
    ["volume"] = "rbxassetid://10747376008",
    ["volume-2"] = "rbxassetid://10747375679",
    ["mute"] = "rbxassetid://10747375880",
    
    -- Social
    ["user"] = "rbxassetid://10747373176",
    ["users"] = "rbxassetid://10747373426",
    ["heart"] = "rbxassetid://10723406885",
    ["star"] = "rbxassetid://10734966248",
    ["bell"] = "rbxassetid://10709775704",
    
    -- Files
    ["file"] = "rbxassetid://10723374641",
    ["folder"] = "rbxassetid://10723387563",
    ["image"] = "rbxassetid://10723415040",
    ["music"] = "rbxassetid://10734905958",
    ["video"] = "rbxassetid://10747374938",
    
    -- Time
    ["clock"] = "rbxassetid://10709805144",
    ["calendar"] = "rbxassetid://10709789505",
    ["timer"] = "rbxassetid://10734984606",
    
    -- Misc
    ["lock"] = "rbxassetid://10723434711",
    ["unlock"] = "rbxassetid://10747366027",
    ["key"] = "rbxassetid://10723416652",
    ["link"] = "rbxassetid://10723426722",
    ["mail"] = "rbxassetid://10734885430",
    ["phone"] = "rbxassetid://10734921524",
    ["camera"] = "rbxassetid://10709789686",
    ["code"] = "rbxassetid://10709810463",
    ["terminal"] = "rbxassetid://10734982144",
    
    -- Nova custom
    ["nova"] = "rbxassetid://18374563984",
    ["sparkle"] = "rbxassetid://18374564012",
    ["crown"] = "rbxassetid://10709818626",
    ["diamond"] = "rbxassetid://10709819149",
    ["trophy"] = "rbxassetid://10747363809",
}

function Nova:GetIcon(name)
    return Icons[name:lower()] or "rbxassetid://0"
end

-- =============================================
-- THEME SYSTEM
-- =============================================

local Themes = {
    Default = {
        Name = "Default",
        
        -- Core colors
        Background = Color3.fromRGB(20, 20, 25),
        Surface = Color3.fromRGB(30, 30, 35),
        Element = Color3.fromRGB(40, 40, 45),
        ElementHover = Color3.fromRGB(50, 50, 55),
        ElementPressed = Color3.fromRGB(35, 35, 40),
        
        -- Accent colors
        Primary = Color3.fromRGB(0, 120, 255),
        PrimaryDark = Color3.fromRGB(0, 90, 200),
        Secondary = Color3.fromRGB(100, 100, 110),
        Success = Color3.fromRGB(40, 200, 80),
        Warning = Color3.fromRGB(255, 170, 0),
        Danger = Color3.fromRGB(255, 70, 70),
        Info = Color3.fromRGB(0, 180, 255),
        
        -- Text colors
        Text = Color3.fromRGB(240, 240, 245),
        TextDark = Color3.fromRGB(160, 160, 170),
        TextInverse = Color3.fromRGB(20, 20, 25),
        
        -- Borders
        Border = Color3.fromRGB(60, 60, 70),
        BorderLight = Color3.fromRGB(80, 80, 90),
        BorderDark = Color3.fromRGB(40, 40, 45),
        
        -- Status
        Disabled = Color3.fromRGB(80, 80, 85),
        DisabledText = Color3.fromRGB(140, 140, 145),
        
        -- Special
        Shadow = Color3.fromRGB(0, 0, 0),
        Glow = Color3.fromRGB(0, 120, 255),
        
        -- Transparency levels
        BackgroundTransparency = 0,
        SurfaceTransparency = 0,
        ElementTransparency = 0,
        BorderTransparency = 0,
        ShadowTransparency = 0.7,
        GlowTransparency = 0.8,
        
        -- Sizes
        BorderSize = 1,
        CornerRadius = UDim.new(0, 8),
        SmallCorner = UDim.new(0, 4),
        LargeCorner = UDim.new(0, 12),
    },
    
    Dark = {
        Name = "Dark",
        Background = Color3.fromRGB(10, 10, 12),
        Surface = Color3.fromRGB(18, 18, 22),
        Element = Color3.fromRGB(25, 25, 30),
        ElementHover = Color3.fromRGB(35, 35, 42),
        ElementPressed = Color3.fromRGB(20, 20, 25),
        
        Primary = Color3.fromRGB(100, 150, 255),
        Secondary = Color3.fromRGB(60, 60, 70),
        
        Text = Color3.fromRGB(230, 230, 235),
        TextDark = Color3.fromRGB(120, 120, 130),
        
        Border = Color3.fromRGB(40, 40, 45),
        BorderLight = Color3.fromRGB(60, 60, 65),
    },
    
    Light = {
        Name = "Light",
        Background = Color3.fromRGB(245, 245, 250),
        Surface = Color3.fromRGB(255, 255, 255),
        Element = Color3.fromRGB(235, 235, 240),
        ElementHover = Color3.fromRGB(225, 225, 230),
        ElementPressed = Color3.fromRGB(215, 215, 220),
        
        Primary = Color3.fromRGB(0, 100, 230),
        Secondary = Color3.fromRGB(140, 140, 150),
        
        Text = Color3.fromRGB(30, 30, 35),
        TextDark = Color3.fromRGB(100, 100, 110),
        
        Border = Color3.fromRGB(200, 200, 210),
        BorderLight = Color3.fromRGB(220, 220, 225),
        
        ShadowTransparency = 0.85,
    },
    
    Midnight = {
        Name = "Midnight",
        Background = Color3.fromRGB(5, 5, 15),
        Surface = Color3.fromRGB(12, 12, 25),
        Element = Color3.fromRGB(18, 18, 35),
        ElementHover = Color3.fromRGB(25, 25, 48),
        ElementPressed = Color3.fromRGB(15, 15, 30),
        
        Primary = Color3.fromRGB(120, 80, 255),
        Secondary = Color3.fromRGB(45, 45, 65),
        
        Text = Color3.fromRGB(220, 220, 255),
        TextDark = Color3.fromRGB(130, 130, 180),
        
        Border = Color3.fromRGB(35, 35, 55),
        BorderLight = Color3.fromRGB(50, 50, 75),
    },
    
    Forest = {
        Name = "Forest",
        Background = Color3.fromRGB(15, 25, 15),
        Surface = Color3.fromRGB(22, 35, 22),
        Element = Color3.fromRGB(30, 48, 30),
        ElementHover = Color3.fromRGB(40, 62, 40),
        ElementPressed = Color3.fromRGB(25, 40, 25),
        
        Primary = Color3.fromRGB(70, 200, 70),
        Secondary = Color3.fromRGB(50, 70, 50),
        
        Text = Color3.fromRGB(220, 240, 220),
        TextDark = Color3.fromRGB(140, 170, 140),
        
        Border = Color3.fromRGB(50, 70, 50),
        BorderLight = Color3.fromRGB(70, 95, 70),
    },
    
    Ocean = {
        Name = "Ocean",
        Background = Color3.fromRGB(10, 20, 30),
        Surface = Color3.fromRGB(15, 30, 45),
        Element = Color3.fromRGB(20, 40, 60),
        ElementHover = Color3.fromRGB(28, 52, 78),
        ElementPressed = Color3.fromRGB(18, 35, 52),
        
        Primary = Color3.fromRGB(0, 150, 220),
        Secondary = Color3.fromRGB(35, 65, 90),
        
        Text = Color3.fromRGB(210, 230, 250),
        TextDark = Color3.fromRGB(130, 160, 190),
        
        Border = Color3.fromRGB(40, 70, 100),
        BorderLight = Color3.fromRGB(60, 95, 130),
    },
    
    Sunset = {
        Name = "Sunset",
        Background = Color3.fromRGB(30, 15, 20),
        Surface = Color3.fromRGB(45, 22, 28),
        Element = Color3.fromRGB(60, 30, 38),
        ElementHover = Color3.fromRGB(78, 40, 50),
        ElementPressed = Color3.fromRGB(52, 26, 33),
        
        Primary = Color3.fromRGB(255, 120, 80),
        Secondary = Color3.fromRGB(90, 45, 55),
        
        Text = Color3.fromRGB(255, 230, 220),
        TextDark = Color3.fromRGB(200, 140, 130),
        
        Border = Color3.fromRGB(100, 50, 60),
        BorderLight = Color3.fromRGB(130, 70, 85),
    },
    
    Galaxy = {
        Name = "Galaxy",
        Background = Color3.fromRGB(8, 5, 20),
        Surface = Color3.fromRGB(15, 10, 35),
        Element = Color3.fromRGB(22, 15, 50),
        ElementHover = Color3.fromRGB(30, 22, 68),
        ElementPressed = Color3.fromRGB(19, 13, 43),
        
        Primary = Color3.fromRGB(140, 70, 255),
        Secondary = Color3.fromRGB(45, 30, 70),
        
        Text = Color3.fromRGB(230, 210, 255),
        TextDark = Color3.fromRGB(150, 120, 200),
        
        Border = Color3.fromRGB(50, 35, 80),
        BorderLight = Color3.fromRGB(70, 50, 110),
        
        Glow = Color3.fromRGB(140, 70, 255),
    }
}

-- Theme registry for live updates
local ThemeRegistry = {}
local CurrentTheme = "Default"

function Nova:RegisterThemeObject(object, properties)
    if not object or not properties then return end
    table.insert(ThemeRegistry, {
        Object = object,
        Properties = properties
    })
    self:ApplyThemeToObject(object, properties)
end

function Nova:ApplyThemeToObject(object, properties)
    local theme = Themes[CurrentTheme]
    for propName, themeKey in pairs(properties) do
        if theme[themeKey] then
            pcall(function()
                object[propName] = theme[themeKey]
            end)
        end
    end
end

function Nova:SetTheme(themeName)
    if not Themes[themeName] then return end
    CurrentTheme = themeName
    
    -- Update all registered objects
    for _, entry in ipairs(ThemeRegistry) do
        self:ApplyThemeToObject(entry.Object, entry.Properties)
    end
    
    -- Update window colors if exists
    if Nova.Windows then
        for _, window in pairs(Nova.Windows) do
            window:UpdateTheme()
        end
    end
    
    self:Notify({
        Title = "Theme Changed",
        Content = "Theme set to " .. themeName,
        Duration = 3,
        Icon = "sparkle"
    })
end

function Nova:GetTheme(property)
    return Themes[CurrentTheme][property] or Themes.Default[property]
end

-- =============================================
-- NOTIFICATION SYSTEM
-- =============================================

local NotificationHolder = Instance.new("Frame")
NotificationHolder.Name = "NotificationHolder"
NotificationHolder.Size = UDim2.new(1, -40, 1, -40)
NotificationHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
NotificationHolder.AnchorPoint = Vector2.new(0.5, 0.5)
NotificationHolder.BackgroundTransparency = 1
NotificationHolder.Parent = GUI

local NotificationList = Instance.new("UIListLayout")
NotificationList.Parent = NotificationHolder
NotificationList.HorizontalAlignment = Enum.HorizontalAlignment.Center
NotificationList.VerticalAlignment = Enum.VerticalAlignment.Bottom
NotificationList.Padding = UDim.new(0, 10)

function Nova:Notify(config)
    config = config or {}
    config.Title = config.Title or "Notification"
    config.Content = config.Content or ""
    config.Duration = config.Duration or 5
    config.Icon = config.Icon and self:GetIcon(config.Icon) or self:GetIcon("info")
    config.Type = config.Type or "info" -- info, success, warning, error
    
    -- Color based on type
    local accentColor
    if config.Type == "success" then
        accentColor = self:GetTheme("Success")
    elseif config.Type == "warning" then
        accentColor = self:GetTheme("Warning")
    elseif config.Type == "error" then
        accentColor = self:GetTheme("Danger")
    else
        accentColor = self:GetTheme("Primary")
    end
    
    local notification = Instance.new("Frame")
    notification.Name = "Notification"
    notification.Size = UDim2.new(0, 350, 0, 0)
    notification.BackgroundColor3 = self:GetTheme("Surface")
    notification.BackgroundTransparency = 0.1
    notification.BorderSizePixel = 0
    notification.Parent = NotificationHolder
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = self:GetTheme("CornerRadius")
    corner.Parent = notification
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = self:GetTheme("Border")
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = notification
    
    -- Accent line
    local accent = Instance.new("Frame")
    accent.Name = "Accent"
    accent.Size = UDim2.new(0, 4, 1, 0)
    accent.BackgroundColor3 = accentColor
    accent.BorderSizePixel = 0
    accent.Parent = notification
    
    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 4)
    accentCorner.Parent = accent
    
    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 24, 0, 24)
    icon.Position = UDim2.new(0, 20, 0.5, 0)
    icon.AnchorPoint = Vector2.new(0, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = config.Icon
    icon.ImageColor3 = accentColor
    icon.Parent = notification
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -70, 0, 20)
    title.Position = UDim2.new(0, 50, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.Text = config.Title
    title.TextColor3 = self:GetTheme("Text")
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = notification
    
    -- Content
    local content = Instance.new("TextLabel")
    content.Name = "Content"
    content.Size = UDim2.new(1, -70, 0, 18)
    content.Position = UDim2.new(0, 50, 0, 32)
    content.BackgroundTransparency = 1
    content.Font = Enum.Font.Gotham
    content.Text = config.Content
    content.TextColor3 = self:GetTheme("TextDark")
    content.TextSize = 13
    content.TextXAlignment = Enum.TextXAlignment.Left
    content.TextWrapped = true
    content.Parent = notification
    
    -- Close button
    local close = Instance.new("ImageButton")
    close.Name = "Close"
    close.Size = UDim2.new(0, 20, 0, 20)
    close.Position = UDim2.new(1, -30, 0, 12)
    close.BackgroundTransparency = 1
    close.Image = self:GetIcon("x")
    close.ImageColor3 = self:GetTheme("TextDark")
    close.Parent = notification
    
    -- Adjust height based on content
    local contentHeight = content.TextBounds.Y
    notification.Size = UDim2.new(0, 350, 0, 50 + contentHeight)
    content.Size = UDim2.new(1, -70, 0, contentHeight)
    
    -- Animation
    notification.Position = UDim2.new(0.5, 0, 1, 50)
    notification.AnchorPoint = Vector2.new(0.5, 1)
    
    TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
        Position = UDim2.new(0.5, 0, 1, -10)
    }):Play()
    
    -- Auto close
    local timer = config.Duration
    local countdown
    countdown = RunService.Heartbeat:Connect(function()
        timer = timer - 0.016
        if timer <= 0 then
            countdown:Disconnect()
            closeNotification()
        end
    end)
    
    -- Close function
    function closeNotification()
        if countdown then countdown:Disconnect() end
        TweenService:Create(notification, TweenInfo.new(0.3, Enum.EasingStyle.Exponential), {
            Position = UDim2.new(0.5, 0, 1, 50),
            BackgroundTransparency = 1,
            TextTransparency = 1
        }):Play()
        
        for _, child in ipairs(notification:GetChildren()) do
            if child:IsA("TextLabel") or child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {
                    TextTransparency = 1,
                    ImageTransparency = 1
                }):Play()
            end
        end
        
        task.wait(0.3)
        notification:Destroy()
    end
    
    close.MouseButton1Click:Connect(closeNotification)
    
    return notification
end

-- =============================================
-- DRAG SYSTEM
-- =============================================

local function MakeDraggable(dragBar, object, callback)
    local dragging = false
    local dragStart
    local objectStart
    
    dragBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            objectStart = object.Position
            
            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                    if connection then connection:Disconnect() end
                end
            end)
        end
    end)
    
    dragBar.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
            local delta = input.Position - dragStart
            local newPos = UDim2.new(
                objectStart.X.Scale,
                objectStart.X.Offset + delta.X,
                objectStart.Y.Scale,
                objectStart.Y.Offset + delta.Y
            )
            
            -- Boundary check
            local viewport = workspace.CurrentCamera.ViewportSize
            if newPos.X.Offset < 0 then
                newPos = UDim2.new(0, 0, newPos.Y.Scale, newPos.Y.Offset)
            elseif newPos.X.Offset + object.AbsoluteSize.X > viewport.X then
                newPos = UDim2.new(0, viewport.X - object.AbsoluteSize.X, newPos.Y.Scale, newPos.Y.Offset)
            end
            
            if newPos.Y.Offset < 0 then
                newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, 0)
            elseif newPos.Y.Offset + object.AbsoluteSize.Y > viewport.Y then
                newPos = UDim2.new(newPos.X.Scale, newPos.X.Offset, 0, viewport.Y - object.AbsoluteSize.Y)
            end
            
            object:TweenPosition(newPos, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.1, true)
            
            if callback then
                callback(newPos)
            end
        end
    end)
end

-- =============================================
-- ELEMENT CREATOR
-- =============================================

local Element = {}
Element.__index = Element

function Element.new(config)
    config = config or {}
    return setmetatable({
        Type = config.Type or "Element",
        Title = config.Title or "",
        Description = config.Description or "",
        Icon = config.Icon,
        Value = config.Default,
        Locked = config.Locked or false,
        Callback = config.Callback or function() end,
        Changed = config.Changed or function() end,
        Parent = nil,
        Container = nil,
        Objects = {},
        Nova = Nova
    }, Element)
end

function Element:CreateBase(parent, hasValue)
    local frame = Instance.new("Frame")
    frame.Name = self.Type .. "_" .. self.Title
    frame.Size = UDim2.new(1, -20, 0, 50)
    frame.BackgroundColor3 = Nova:GetTheme("Element")
    frame.BackgroundTransparency = Nova:GetTheme("ElementTransparency")
    frame.BorderSizePixel = 0
    frame.Parent = parent or self.Container
    
    Nova:RegisterThemeObject(frame, {
        BackgroundColor3 = "Element"
    })
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = Nova:GetTheme("CornerRadius")
    corner.Parent = frame
    
    local stroke = Instance.new("UIStroke")
    stroke.Color = Nova:GetTheme("Border")
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = frame
    
    Nova:RegisterThemeObject(stroke, {
        Color = "Border"
    })
    
    -- Icon
    if self.Icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 15, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = Nova:GetIcon(self.Icon)
        icon.ImageColor3 = Nova:GetTheme("TextDark")
        icon.Parent = frame
        
        Nova:RegisterThemeObject(icon, {
            ImageColor3 = "TextDark"
        })
        
        self.Objects.Icon = icon
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -100, 0, 16)
    title.Position = UDim2.new(0, self.Icon and 45 or 15, 0, 10)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.Text = self.Title
    title.TextColor3 = Nova:GetTheme("Text")
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    Nova:RegisterThemeObject(title, {
        TextColor3 = "Text"
    })
    
    self.Objects.Title = title
    
    -- Description
    if self.Description and self.Description ~= "" then
        local desc = Instance.new("TextLabel")
        desc.Name = "Description"
        desc.Size = UDim2.new(1, -100, 0, 14)
        desc.Position = UDim2.new(0, self.Icon and 45 or 15, 0, 27)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.Text = self.Description
        desc.TextColor3 = Nova:GetTheme("TextDark")
        desc.TextSize = 12
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = frame
        
        Nova:RegisterThemeObject(desc, {
            TextColor3 = "TextDark"
        })
        
        self.Objects.Description = desc
        frame.Size = UDim2.new(1, -20, 0, 68)
    end
    
    -- Locked overlay
    if self.Locked then
        local lockOverlay = Instance.new("Frame")
        lockOverlay.Name = "LockOverlay"
        lockOverlay.Size = UDim2.new(1, 0, 1, 0)
        lockOverlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        lockOverlay.BackgroundTransparency = 0.7
        lockOverlay.BorderSizePixel = 0
        lockOverlay.Parent = frame
        
        local lockIcon = Instance.new("ImageLabel")
        lockIcon.Name = "LockIcon"
        lockIcon.Size = UDim2.new(0, 20, 0, 20)
        lockIcon.Position = UDim2.new(1, -35, 0.5, 0)
        lockIcon.AnchorPoint = Vector2.new(0, 0.5)
        lockIcon.BackgroundTransparency = 1
        lockIcon.Image = Nova:GetIcon("lock")
        lockIcon.ImageColor3 = Nova:GetTheme("TextDark")
        lockIcon.Parent = lockOverlay
        
        Nova:RegisterThemeObject(lockIcon, {
            ImageColor3 = "TextDark"
        })
        
        local lockCorner = Instance.new("UICorner")
        lockCorner.CornerRadius = Nova:GetTheme("CornerRadius")
        lockCorner.Parent = lockOverlay
        
        self.Objects.Lock = lockOverlay
    end
    
    -- Hover effect
    local hoverMotor = Motor.new(0, {frequency = 8, damping = 0.7})
    hoverMotor:OnStep(function(value)
        frame.BackgroundColor3 = Nova:GetTheme("Element"):Lerp(Nova:GetTheme("ElementHover"), value)
    end)
    
    frame.MouseEnter:Connect(function()
        if not self.Locked then
            hoverMotor:SetTarget(1)
        end
    end)
    
    frame.MouseLeave:Connect(function()
        if not self.Locked then
            hoverMotor:SetTarget(0)
        end
    end)
    
    frame.MouseButton1Down:Connect(function()
        if not self.Locked then
            frame.BackgroundColor3 = Nova:GetTheme("ElementPressed")
        end
    end)
    
    frame.MouseButton1Up:Connect(function()
        if not self.Locked then
            frame.BackgroundColor3 = Nova:GetTheme("Element"):Lerp(Nova:GetTheme("ElementHover"), hoverMotor._value)
        end
    end)
    
    self.Objects.Frame = frame
    
    return frame
end

-- =============================================
-- BUTTON ELEMENT
-- =============================================

local Button = setmetatable({}, Element)
Button.__index = Button

function Nova:Button(config)
    config = config or {}
    config.Type = "Button"
    local self = setmetatable(Element.new(config), Button)
    
    return self
end

function Button:Create(parent)
    local frame = self:CreateBase(parent, false)
    
    -- Button styling
    frame.BackgroundColor3 = Nova:GetTheme("Primary")
    Nova:RegisterThemeObject(frame, {
        BackgroundColor3 = "Primary"
    })
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 100, 0, 30)
    valueLabel.Position = UDim2.new(1, -15, 0.5, 0)
    valueLabel.AnchorPoint = Vector2.new(1, 0.5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamSemibold
    valueLabel.Text = self.Title
    valueLabel.TextColor3 = Nova:GetTheme("TextInverse")
    valueLabel.TextSize = 14
    valueLabel.Parent = frame
    
    Nova:RegisterThemeObject(valueLabel, {
        TextColor3 = "TextInverse"
    })
    
    self.Objects.Value = valueLabel
    self.Objects.Frame = frame
    
    -- Click event
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            Nova:SafeCallback(self.Callback)
        end
    end)
    
    return self
end

-- =============================================
-- TOGGLE ELEMENT
-- =============================================

local Toggle = setmetatable({}, Element)
Toggle.__index = Toggle

function Nova:Toggle(config)
    config = config or {}
    config.Type = "Toggle"
    config.Default = config.Default or false
    local self = setmetatable(Element.new(config), Toggle)
    
    return self
end

function Toggle:Create(parent)
    local frame = self:CreateBase(parent, true)
    
    -- Toggle switch
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Name = "Toggle"
    toggleFrame.Size = UDim2.new(0, 50, 0, 24)
    toggleFrame.Position = UDim2.new(1, -20, 0.5, 0)
    toggleFrame.AnchorPoint = Vector2.new(1, 0.5)
    toggleFrame.BackgroundColor3 = self.Value and Nova:GetTheme("Primary") or Nova:GetTheme("Secondary")
    toggleFrame.BackgroundTransparency = 0
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = frame
    
    Nova:RegisterThemeObject(toggleFrame, {
        BackgroundColor3 = self.Value and "Primary" or "Secondary"
    })
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(1, 0)
    toggleCorner.Parent = toggleFrame
    
    local toggleKnob = Instance.new("Frame")
    toggleKnob.Name = "Knob"
    toggleKnob.Size = UDim2.new(0, 20, 0, 20)
    toggleKnob.Position = UDim2.new(0, self.Value and 26 or 2, 0.5, 0)
    toggleKnob.AnchorPoint = Vector2.new(0, 0.5)
    toggleKnob.BackgroundColor3 = Nova:GetTheme("Text")
    toggleKnob.BorderSizePixel = 0
    toggleKnob.Parent = toggleFrame
    
    Nova:RegisterThemeObject(toggleKnob, {
        BackgroundColor3 = "Text"
    })
    
    local knobCorner = Instance.new("UICorner")
    knobCorner.CornerRadius = UDim.new(1, 0)
    knobCorner.Parent = toggleKnob
    
    self.Objects.Toggle = toggleFrame
    self.Objects.Knob = toggleKnob
    
    -- Click handler
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            self:SetValue(not self.Value)
        end
    end)
    
    return self
end

function Toggle:SetValue(value)
    value = not not value
    if self.Value == value then return end
    self.Value = value
    
    -- Animate toggle
    TweenService:Create(self.Objects.Knob, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0, self.Value and 26 or 2, 0.5, 0)
    }):Play()
    
    TweenService:Create(self.Objects.Toggle, TweenInfo.new(0.2), {
        BackgroundColor3 = self.Value and Nova:GetTheme("Primary") or Nova:GetTheme("Secondary")
    }):Play()
    
    Nova:SafeCallback(self.Callback, self.Value)
    Nova:SafeCallback(self.Changed, self.Value)
end

-- =============================================
-- SLIDER ELEMENT
-- =============================================

local Slider = setmetatable({}, Element)
Slider.__index = Slider

function Nova:Slider(config)
    config = config or {}
    config.Type = "Slider"
    config.Min = config.Min or 0
    config.Max = config.Max or 100
    config.Default = config.Default or config.Min
    config.Suffix = config.Suffix or ""
    config.Decimals = config.Decimals or 0
    local self = setmetatable(Element.new(config), Slider)
    
    return self
end

function Slider:Create(parent)
    local frame = self:CreateBase(parent, true)
    frame.Size = UDim2.new(1, -20, 0, 70)
    
    -- Value display
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 100, 0, 20)
    valueLabel.Position = UDim2.new(1, -15, 0, 12)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.GothamSemibold
    valueLabel.Text = tostring(self.Value) .. " " .. self.Suffix
    valueLabel.TextColor3 = Nova:GetTheme("Primary")
    valueLabel.TextSize = 16
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    Nova:RegisterThemeObject(valueLabel, {
        TextColor3 = "Primary"
    })
    
    -- Slider rail
    local rail = Instance.new("Frame")
    rail.Name = "Rail"
    rail.Size = UDim2.new(1, -40, 0, 4)
    rail.Position = UDim2.new(0, 15, 0, 45)
    rail.BackgroundColor3 = Nova:GetTheme("Secondary")
    rail.BackgroundTransparency = 0.5
    rail.BorderSizePixel = 0
    rail.Parent = frame
    
    Nova:RegisterThemeObject(rail, {
        BackgroundColor3 = "Secondary"
    })
    
    local railCorner = Instance.new("UICorner")
    railCorner.CornerRadius = UDim.new(1, 0)
    railCorner.Parent = rail
    
    -- Slider fill
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Nova:GetTheme("Primary")
    fill.BorderSizePixel = 0
    fill.Parent = rail
    
    Nova:RegisterThemeObject(fill, {
        BackgroundColor3 = "Primary"
    })
    
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill
    
    -- Slider knob
    local knob = Instance.new("ImageLabel")
    knob.Name = "Knob"
    knob.Size = UDim2.new(0, 20, 0, 20)
    knob.Position = UDim2.new(0, 0, 0.5, 0)
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.BackgroundTransparency = 1
    knob.Image = Nova:GetIcon("circle")
    knob.ImageColor3 = Nova:GetTheme("Primary")
    knob.Parent = fill
    
    Nova:RegisterThemeObject(knob, {
        ImageColor3 = "Primary"
    })
    
    self.Objects.Value = valueLabel
    self.Objects.Rail = rail
    self.Objects.Fill = fill
    self.Objects.Knob = knob
    
    -- Update function
    local function updateFromPosition(x)
        local railPos = rail.AbsolutePosition.X
        local railSize = rail.AbsoluteSize.X
        local percent = math.clamp((x - railPos) / railSize, 0, 1)
        local value = self.Min + (self.Max - self.Min) * percent
        self:SetValue(value)
    end
    
    -- Dragging
    local dragging = false
    
    rail.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            dragging = true
            updateFromPosition(input.Position.X)
        end
    end)
    
    knob.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            dragging = true
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromPosition(input.Position.X)
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    
    self:SetValue(self.Value)
    
    return self
end

function Slider:SetValue(value)
    value = math.clamp(value, self.Min, self.Max)
    value = Round(value, self.Decimals)
    if self.Value == value then return end
    self.Value = value
    
    local percent = (value - self.Min) / (self.Max - self.Min)
    
    self.Objects.Fill.Size = UDim2.new(percent, 0, 1, 0)
    self.Objects.Value.Text = tostring(value) .. " " .. self.Suffix
    
    Nova:SafeCallback(self.Callback, value)
    Nova:SafeCallback(self.Changed, value)
end

-- =============================================
-- DROPDOWN ELEMENT
-- =============================================

local Dropdown = setmetatable({}, Element)
Dropdown.__index = Dropdown

function Nova:Dropdown(config)
    config = config or {}
    config.Type = "Dropdown"
    config.Values = config.Values or {}
    config.Multi = config.Multi or false
    config.Default = config.Default or (config.Multi and {} or nil)
    config.AllowNone = config.AllowNone or false
    local self = setmetatable(Element.new(config), Dropdown)
    
    return self
end

function Dropdown:Create(parent)
    local frame = self:CreateBase(parent, true)
    
    -- Selected value display
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 150, 0, 20)
    valueLabel.Position = UDim2.new(1, -15, 0.5, 0)
    valueLabel.AnchorPoint = Vector2.new(1, 0.5)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Font = Enum.Font.Gotham
    valueLabel.Text = self:_GetDisplayText()
    valueLabel.TextColor3 = Nova:GetTheme("TextDark")
    valueLabel.TextSize = 13
    valueLabel.TextTruncate = Enum.TextTruncate.AtEnd
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = frame
    
    Nova:RegisterThemeObject(valueLabel, {
        TextColor3 = "TextDark"
    })
    
    -- Dropdown icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Size = UDim2.new(0, 16, 0, 16)
    icon.Position = UDim2.new(1, -35, 0.5, 0)
    icon.AnchorPoint = Vector2.new(1, 0.5)
    icon.BackgroundTransparency = 1
    icon.Image = Nova:GetIcon("chevron-down")
    icon.ImageColor3 = Nova:GetTheme("TextDark")
    icon.Parent = frame
    
    Nova:RegisterThemeObject(icon, {
        ImageColor3 = "TextDark"
    })
    
    self.Objects.Value = valueLabel
    self.Objects.Icon = icon
    self.Objects.Frame = frame
    self.Opened = false
    
    -- Dropdown container
    local dropdownFrame = Instance.new("Frame")
    dropdownFrame.Name = "Dropdown"
    dropdownFrame.Size = UDim2.new(0, 200, 0, 0)
    dropdownFrame.Position = UDim2.new(1, -10, 1, 5)
    dropdownFrame.AnchorPoint = Vector2.new(1, 0)
    dropdownFrame.BackgroundColor3 = Nova:GetTheme("Surface")
    dropdownFrame.BackgroundTransparency = 0.05
    dropdownFrame.BorderSizePixel = 0
    dropdownFrame.Visible = false
    dropdownFrame.Parent = frame
    
    Nova:RegisterThemeObject(dropdownFrame, {
        BackgroundColor3 = "Surface"
    })
    
    local dropdownCorner = Instance.new("UICorner")
    dropdownCorner.CornerRadius = Nova:GetTheme("CornerRadius")
    dropdownCorner.Parent = dropdownFrame
    
    local dropdownStroke = Instance.new("UIStroke")
    dropdownStroke.Color = Nova:GetTheme("Border")
    dropdownStroke.Thickness = 1
    dropdownStroke.Transparency = 0.5
    dropdownStroke.Parent = dropdownFrame
    
    Nova:RegisterThemeObject(dropdownStroke, {
        Color = "Border"
    })
    
    local dropdownList = Instance.new("ScrollingFrame")
    dropdownList.Name = "List"
    dropdownList.Size = UDim2.new(1, 0, 1, 0)
    dropdownList.BackgroundTransparency = 1
    dropdownList.BorderSizePixel = 0
    dropdownList.ScrollBarThickness = 4
    dropdownList.ScrollBarImageColor3 = Nova:GetTheme("Border")
    dropdownList.CanvasSize = UDim2.new(0, 0, 0, 0)
    dropdownList.Parent = dropdownFrame
    
    local listLayout = Instance.new("UIListLayout")
    listLayout.Padding = UDim.new(0, 2)
    listLayout.Parent = dropdownList
    
    listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        dropdownList.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 4)
    end)
    
    self.Objects.Dropdown = dropdownFrame
    self.Objects.List = dropdownList
    self.Objects.ListLayout = listLayout
    
    -- Click handler
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            self:Toggle()
        end
    end)
    
    -- Populate dropdown
    self:Refresh(self.Values)
    
    return self
end

function Dropdown:_GetDisplayText()
    if self.Multi then
        local count = 0
        for _ in pairs(self.Value or {}) do
            count = count + 1
        end
        if count == 0 then
            return "None"
        elseif count == 1 then
            for k in pairs(self.Value) do
                return k
            end
        else
            return count .. " selected"
        end
    else
        return self.Value or "None"
    end
end

function Dropdown:Toggle()
    self.Opened = not self.Opened
    
    if self.Opened then
        -- Close other dropdowns
        for _, window in pairs(Nova.Windows or {}) do
            window:CloseAllDropdowns()
        end
        
        self.Objects.Dropdown.Visible = true
        
        -- Calculate height
        local count = 0
        for _ in pairs(self.Values) do
            count = count + 1
        end
        local height = math.min(count * 32, 200)
        
        -- Animate open
        self.Objects.Dropdown.Size = UDim2.new(0, 200, 0, 0)
        TweenService:Create(self.Objects.Dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 200, 0, height)
        }):Play()
        
        TweenService:Create(self.Objects.Icon, TweenInfo.new(0.2), {
            Rotation = 180
        }):Play()
    else
        self:Close()
    end
end

function Dropdown:Close()
    if not self.Opened then return end
    self.Opened = false
    
    TweenService:Create(self.Objects.Dropdown, TweenInfo.new(0.2, Enum.EasingStyle.Quad), {
        Size = UDim2.new(0, 200, 0, 0)
    }):Play()
    
    TweenService:Create(self.Objects.Icon, TweenInfo.new(0.2), {
        Rotation = 0
    }):Play()
    
    task.wait(0.2)
    self.Objects.Dropdown.Visible = false
end

function Dropdown:Refresh(newValues)
    self.Values = newValues or self.Values
    
    -- Clear list
    for _, child in ipairs(self.Objects.List:GetChildren()) do
        if not child:IsA("UIListLayout") then
            child:Destroy()
        end
    end
    
    -- Create option buttons
    for _, value in ipairs(self.Values) do
        local option = Instance.new("TextButton")
        option.Name = "Option"
        option.Size = UDim2.new(1, -8, 0, 28)
        option.Position = UDim2.new(0, 4, 0, 0)
        option.BackgroundTransparency = 0.95
        option.BackgroundColor3 = Nova:GetTheme("Element")
        option.Text = tostring(value)
        option.Font = Enum.Font.Gotham
        option.TextColor3 = Nova:GetTheme("Text")
        option.TextSize = 13
        option.AutoButtonColor = false
        option.Parent = self.Objects.List
        
        Nova:RegisterThemeObject(option, {
            BackgroundColor3 = "Element",
            TextColor3 = "Text"
        })
        
        local optionCorner = Instance.new("UICorner")
        optionCorner.CornerRadius = Nova:GetTheme("SmallCorner")
        optionCorner.Parent = option
        
        -- Check if selected
        local isSelected = self.Multi and self.Value and self.Value[value] or self.Value == value
        if isSelected then
            option.BackgroundTransparency = 0.7
        end
        
        -- Hover effect
        option.MouseEnter:Connect(function()
            if not isSelected then
                TweenService:Create(option, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.85
                }):Play()
            end
        end)
        
        option.MouseLeave:Connect(function()
            if not isSelected then
                TweenService:Create(option, TweenInfo.new(0.2), {
                    BackgroundTransparency = 0.95
                }):Play()
            end
        end)
        
        -- Click handler
        option.MouseButton1Click:Connect(function()
            if self.Multi then
                self.Value = self.Value or {}
                if self.Value[value] then
                    self.Value[value] = nil
                else
                    self.Value[value] = true
                end
            else
                self.Value = value
                self:Close()
            end
            
            self.Objects.Value.Text = self:_GetDisplayText()
            Nova:SafeCallback(self.Callback, self.Value)
            Nova:SafeCallback(self.Changed, self.Value)
        end)
    end
end

-- =============================================
-- INPUT ELEMENT
-- =============================================

local Input = setmetatable({}, Element)
Input.__index = Input

function Nova:Input(config)
    config = config or {}
    config.Type = "Input"
    config.Default = config.Default or ""
    config.Placeholder = config.Placeholder or "Enter text..."
    config.Numeric = config.Numeric or false
    config.MaxLength = config.MaxLength or 0
    config.Multiline = config.Multiline or false
    local self = setmetatable(Element.new(config), Input)
    
    return self
end

function Input:Create(parent)
    local frame = self:CreateBase(parent, true)
    frame.Size = UDim2.new(1, -20, 0, 68)
    
    -- Input box
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Input"
    inputBox.Size = UDim2.new(1, -30, 0, 30)
    inputBox.Position = UDim2.new(0, 15, 0, 30)
    inputBox.BackgroundColor3 = Nova:GetTheme("Surface")
    inputBox.BackgroundTransparency = 0.3
    inputBox.BorderSizePixel = 0
    inputBox.Font = Enum.Font.Gotham
    inputBox.PlaceholderText = self.Placeholder
    inputBox.PlaceholderColor3 = Nova:GetTheme("TextDark")
    inputBox.Text = self.Value
    inputBox.TextColor3 = Nova:GetTheme("Text")
    inputBox.TextSize = 14
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = false
    inputBox.Parent = frame
    
    Nova:RegisterThemeObject(inputBox, {
        BackgroundColor3 = "Surface",
        PlaceholderColor3 = "TextDark",
        TextColor3 = "Text"
    })
    
    if self.Multiline then
        inputBox.MultiLine = true
        inputBox.TextWrapped = true
        inputBox.Size = UDim2.new(1, -30, 0, 60)
        frame.Size = UDim2.new(1, -20, 0, 100)
    end
    
    local inputCorner = Instance.new("UICorner")
    inputCorner.CornerRadius = Nova:GetTheme("SmallCorner")
    inputCorner.Parent = inputBox
    
    local inputStroke = Instance.new("UIStroke")
    inputStroke.Color = Nova:GetTheme("Border")
    inputStroke.Thickness = 1
    inputStroke.Transparency = 0.5
    inputStroke.Parent = inputBox
    
    Nova:RegisterThemeObject(inputStroke, {
        Color = "Border"
    })
    
    self.Objects.Input = inputBox
    
    -- Focus effect
    local focusMotor = Motor.new(0)
    focusMotor:OnStep(function(value)
        inputStroke.Transparency = 0.5 - value * 0.3
        inputStroke.Color = Nova:GetTheme("Primary"):Lerp(Nova:GetTheme("Border"), 1 - value)
    end)
    
    inputBox.Focused:Connect(function()
        focusMotor:SetTarget(1)
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        focusMotor:SetTarget(0)
        
        if self.Numeric then
            local num = tonumber(inputBox.Text)
            if num then
                self:SetValue(num)
            else
                inputBox.Text = self.Value
            end
        else
            self:SetValue(inputBox.Text)
        end
    end)
    
    -- Character limit
    if self.MaxLength > 0 then
        inputBox.Changed:Connect(function(prop)
            if prop == "Text" and #inputBox.Text > self.MaxLength then
                inputBox.Text = inputBox.Text:sub(1, self.MaxLength)
            end
        end)
    end
    
    return self
end

function Input:SetValue(value)
    value = tostring(value)
    if self.Value == value then return end
    self.Value = value
    self.Objects.Input.Text = value
    
    Nova:SafeCallback(self.Callback, value)
    Nova:SafeCallback(self.Changed, value)
end

-- =============================================
-- KEYBIND ELEMENT
-- =============================================

local Keybind = setmetatable({}, Element)
Keybind.__index = Keybind

function Nova:Keybind(config)
    config = config or {}
    config.Type = "Keybind"
    config.Default = config.Default or "None"
    config.Changeable = config.Changeable ~= false
    config.Hold = config.Hold or false
    local self = setmetatable(Element.new(config), Keybind)
    self.Binding = false
    self.Holding = false
    
    return self
end

function Keybind:Create(parent)
    local frame = self:CreateBase(parent, true)
    
    -- Key display
    local keyLabel = Instance.new("TextLabel")
    keyLabel.Name = "Key"
    keyLabel.Size = UDim2.new(0, 80, 0, 30)
    keyLabel.Position = UDim2.new(1, -15, 0.5, 0)
    keyLabel.AnchorPoint = Vector2.new(1, 0.5)
    keyLabel.BackgroundColor3 = Nova:GetTheme("Surface")
    keyLabel.BackgroundTransparency = 0.3
    keyLabel.BorderSizePixel = 0
    keyLabel.Font = Enum.Font.GothamSemibold
    keyLabel.Text = self.Value
    keyLabel.TextColor3 = Nova:GetTheme("Primary")
    keyLabel.TextSize = 14
    keyLabel.Parent = frame
    
    Nova:RegisterThemeObject(keyLabel, {
        BackgroundColor3 = "Surface",
        TextColor3 = "Primary"
    })
    
    local keyCorner = Instance.new("UICorner")
    keyCorner.CornerRadius = Nova:GetTheme("SmallCorner")
    keyCorner.Parent = keyLabel
    
    self.Objects.Key = keyLabel
    
    -- Click to change
    if self.Changeable then
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked and not self.Binding then
                self:StartBinding()
            end
        end)
    end
    
    -- Key detection
    UserInputService.InputBegan:Connect(function(input, gameProcessed)
        if gameProcessed then return end
        if self.Locked then return end
        
        local key = self:_GetKeyName(input)
        if key == self.Value and not self.Binding then
            if self.Hold then
                self.Holding = true
                Nova:SafeCallback(self.Callback, true)
            else
                Nova:SafeCallback(self.Callback)
            end
        end
    end)
    
    UserInputService.InputEnded:Connect(function(input)
        local key = self:_GetKeyName(input)
        if key == self.Value and self.Hold and self.Holding then
            self.Holding = false
            Nova:SafeCallback(self.Callback, false)
        end
    end)
    
    return self
end

function Keybind:_GetKeyName(input)
    if input.UserInputType == Enum.UserInputType.Keyboard then
        return input.KeyCode.Name
    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
        return "MouseLeft"
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        return "MouseRight"
    elseif input.UserInputType == Enum.UserInputType.MouseButton3 then
        return "MouseMiddle"
    end
    return nil
end

function Keybind:StartBinding()
    self.Binding = true
    self.Objects.Key.Text = "..."
    
    local connection
    connection = UserInputService.InputBegan:Connect(function(input)
        local key = self:_GetKeyName(input)
        if key then
            self:SetValue(key)
            self.Binding = false
            connection:Disconnect()
        end
    end)
    
    task.wait(5)
    if self.Binding then
        self.Binding = false
        self.Objects.Key.Text = self.Value
        if connection then
            connection:Disconnect()
        end
    end
end

function Keybind:SetValue(key)
    self.Value = key
    self.Objects.Key.Text = key
    Nova:SafeCallback(self.Changed, key)
end

-- =============================================
-- COLOR PICKER ELEMENT
-- =============================================

local ColorPicker = setmetatable({}, Element)
ColorPicker.__index = ColorPicker

function Nova:ColorPicker(config)
    config = config or {}
    config.Type = "ColorPicker"
    config.Default = config.Default or Color3.fromRGB(255, 255, 255)
    config.Transparency = config.Transparency or 0
    local self = setmetatable(Element.new(config), ColorPicker)
    
    return self
end

function ColorPicker:Create(parent)
    local frame = self:CreateBase(parent, true)
    
    -- Color preview
    local preview = Instance.new("Frame")
    preview.Name = "Preview"
    preview.Size = UDim2.new(0, 30, 0, 30)
    preview.Position = UDim2.new(1, -15, 0.5, 0)
    preview.AnchorPoint = Vector2.new(1, 0.5)
    preview.BackgroundColor3 = self.Value
    preview.BackgroundTransparency = self.Transparency
    preview.BorderSizePixel = 0
    preview.Parent = frame
    
    Nova:RegisterThemeObject(preview, {
        BackgroundColor3 = "Primary"
    })
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = Nova:GetTheme("SmallCorner")
    previewCorner.Parent = preview
    
    local previewStroke = Instance.new("UIStroke")
    previewStroke.Color = Nova:GetTheme("Border")
    previewStroke.Thickness = 1
    previewStroke.Transparency = 0.5
    previewStroke.Parent = preview
    
    Nova:RegisterThemeObject(previewStroke, {
        Color = "Border"
    })
    
    self.Objects.Preview = preview
    
    -- Click handler
    frame.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 and not self.Locked then
            self:OpenPicker()
        end
    end)
    
    return self
end

function ColorPicker:OpenPicker()
    -- Create picker dialog
    local dialog = Instance.new("Frame")
    dialog.Name = "ColorPicker"
    dialog.Size = UDim2.new(0, 300, 0, 350)
    dialog.Position = UDim2.new(0.5, -150, 0.5, -175)
    dialog.BackgroundColor3 = Nova:GetTheme("Surface")
    dialog.BackgroundTransparency = 0.05
    dialog.BorderSizePixel = 0
    dialog.Parent = GUI
    
    Nova:RegisterThemeObject(dialog, {
        BackgroundColor3 = "Surface"
    })
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = Nova:GetTheme("LargeCorner")
    dialogCorner.Parent = dialog
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamSemibold
    title.Text = "Select Color"
    title.TextColor3 = Nova:GetTheme("Text")
    title.TextSize = 18
    title.Parent = dialog
    
    Nova:RegisterThemeObject(title, {
        TextColor3 = "Text"
    })
    
    -- Close button
    local close = Instance.new("ImageButton")
    close.Size = UDim2.new(0, 30, 0, 30)
    close.Position = UDim2.new(1, -35, 0, 5)
    close.BackgroundTransparency = 1
    close.Image = Nova:GetIcon("x")
    close.ImageColor3 = Nova:GetTheme("TextDark")
    close.Parent = dialog
    
    Nova:RegisterThemeObject(close, {
        ImageColor3 = "TextDark"
    })
    
    close.MouseButton1Click:Connect(function()
        dialog:TweenPosition(UDim2.new(0.5, -150, 1, 50), Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.3, true)
        task.wait(0.3)
        dialog:Destroy()
    end)
    
    -- Color picker implementation would go here
    -- This is a simplified version
    
    -- Preview area
    local preview = Instance.new("Frame")
    preview.Size = UDim2.new(0, 100, 0, 100)
    preview.Position = UDim2.new(0.5, -50, 0, 60)
    preview.BackgroundColor3 = self.Value
    preview.BackgroundTransparency = self.Transparency
    preview.BorderSizePixel = 0
    preview.Parent = dialog
    
    local previewCorner = Instance.new("UICorner")
    previewCorner.CornerRadius = UDim.new(0, 8)
    previewCorner.Parent = preview
    
    -- Done button
    local done = Instance.new("TextButton")
    done.Size = UDim2.new(0, 100, 0, 35)
    done.Position = UDim2.new(0.5, -50, 1, -45)
    done.BackgroundColor3 = Nova:GetTheme("Primary")
    done.BackgroundTransparency = 0
    done.Font = Enum.Font.GothamSemibold
    done.Text = "Done"
    done.TextColor3 = Nova:GetTheme("TextInverse")
    done.TextSize = 14
    done.Parent = dialog
    
    Nova:RegisterThemeObject(done, {
        BackgroundColor3 = "Primary",
        TextColor3 = "TextInverse"
    })
    
    local doneCorner = Instance.new("UICorner")
    doneCorner.CornerRadius = UDim.new(0, 6)
    doneCorner.Parent = done
    
    done.MouseButton1Click:Connect(function()
        close:Destroy()
    end)
    
    -- Animate in
    dialog.Position = UDim2.new(0.5, -150, 1, 50)
    TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -150, 0.5, -175)
    }):Play()
end

-- =============================================
-- SECTION ELEMENT
-- =============================================

local Section = setmetatable({}, Element)
Section.__index = Section

function Nova:Section(config)
    config = config or {}
    config.Type = "Section"
    config.Description = config.Description or ""
    local self = setmetatable(Element.new(config), Section)
    self.Elements = {}
    
    return self
end

function Section:Create(parent)
    local frame = Instance.new("Frame")
    frame.Name = "Section_" .. self.Title
    frame.Size = UDim2.new(1, 0, 0, 30)
    frame.BackgroundTransparency = 1
    frame.Parent = parent or self.Container
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 0, 20)
    title.Position = UDim2.new(0, 10, 0, 5)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = self.Title
    title.TextColor3 = Nova:GetTheme("Text")
    title.TextSize = 18
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = frame
    
    Nova:RegisterThemeObject(title, {
        TextColor3 = "Text"
    })
    
    -- Description
    if self.Description and self.Description ~= "" then
        local desc = Instance.new("TextLabel")
        desc.Size = UDim2.new(1, -20, 0, 16)
        desc.Position = UDim2.new(0, 10, 0, 27)
        desc.BackgroundTransparency = 1
        desc.Font = Enum.Font.Gotham
        desc.Text = self.Description
        desc.TextColor3 = Nova:GetTheme("TextDark")
        desc.TextSize = 13
        desc.TextXAlignment = Enum.TextXAlignment.Left
        desc.Parent = frame
        
        Nova:RegisterThemeObject(desc, {
            TextColor3 = "TextDark"
        })
        
        frame.Size = UDim2.new(1, 0, 0, 50)
    end
    
    -- Container for section elements
    local container = Instance.new("Frame")
    container.Name = "Container"
    container.Size = UDim2.new(1, 0, 0, 0)
    container.Position = UDim2.new(0, 0, 0, frame.Size.Y.Offset)
    container.BackgroundTransparency = 1
    container.Parent = frame
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 5)
    list.Parent = container
    
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        container.Size = UDim2.new(1, 0, 0, list.AbsoluteContentSize.Y)
        frame.Size = UDim2.new(1, 0, 0, frame.Size.Y.Offset + list.AbsoluteContentSize.Y)
    end)
    
    self.Objects.Frame = frame
    self.Objects.Container = container
    self.Objects.List = list
    
    return self
end

function Section:AddElement(element)
    if not element then return end
    table.insert(self.Elements, element)
    element.Container = self.Objects.Container
    element:Create()
    return element
end

-- =============================================
-- TAB SYSTEM
-- =============================================

local Tab = {}
Tab.__index = Tab

function Nova:Tab(config)
    config = config or {}
    return setmetatable({
        Title = config.Title or "Tab",
        Icon = config.Icon,
        Elements = {},
        Nova = Nova,
        Window = nil
    }, Tab)
end

function Tab:Create(window, container)
    self.Window = window
    
    -- Tab button
    local button = Instance.new("TextButton")
    button.Name = "Tab_" .. self.Title
    button.Size = UDim2.new(1, 0, 0, 40)
    button.BackgroundTransparency = 1
    button.Font = Enum.Font.Gotham
    button.Text = ""
    button.AutoButtonColor = false
    button.Parent = container
    
    -- Icon
    if self.Icon then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.Size = UDim2.new(0, 20, 0, 20)
        icon.Position = UDim2.new(0, 15, 0.5, 0)
        icon.AnchorPoint = Vector2.new(0, 0.5)
        icon.BackgroundTransparency = 1
        icon.Image = Nova:GetIcon(self.Icon)
        icon.ImageColor3 = Nova:GetTheme("TextDark")
        icon.Parent = button
        
        Nova:RegisterThemeObject(icon, {
            ImageColor3 = "TextDark"
        })
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.new(0, self.Icon and 45 or 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.Gotham
    title.Text = self.Title
    title.TextColor3 = Nova:GetTheme("TextDark")
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = button
    
    Nova:RegisterThemeObject(title, {
        TextColor3 = "TextDark"
    })
    
    -- Active indicator
    local indicator = Instance.new("Frame")
    indicator.Name = "Indicator"
    indicator.Size = UDim2.new(0, 3, 0, 0)
    indicator.Position = UDim2.new(0, 0, 0.5, 0)
    indicator.AnchorPoint = Vector2.new(0, 0.5)
    indicator.BackgroundColor3 = Nova:GetTheme("Primary")
    indicator.BorderSizePixel = 0
    indicator.Visible = false
    indicator.Parent = button
    
    Nova:RegisterThemeObject(indicator, {
        BackgroundColor3 = "Primary"
    })
    
    local indicatorCorner = Instance.new("UICorner")
    indicatorCorner.CornerRadius = UDim.new(1, 0)
    indicatorCorner.Parent = indicator
    
    self.Objects = {
        Button = button,
        Title = title,
        Icon = self.Icon and button:FindFirstChild("Icon"),
        Indicator = indicator
    }
    
    -- Content container (hidden by default)
    local content = Instance.new("ScrollingFrame")
    content.Name = "Content_" .. self.Title
    content.Size = UDim2.new(1, 0, 1, 0)
    content.BackgroundTransparency = 1
    content.BorderSizePixel = 0
    content.ScrollBarThickness = 4
    content.ScrollBarImageColor3 = Nova:GetTheme("Border")
    content.CanvasSize = UDim2.new(0, 0, 0, 0)
    content.Visible = false
    content.Parent = window.Objects.Content
    
    Nova:RegisterThemeObject(content, {
        ScrollBarImageColor3 = "Border"
    })
    
    local padding = Instance.new("UIPadding")
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.Parent = content
    
    local list = Instance.new("UIListLayout")
    list.Padding = UDim.new(0, 10)
    list.Parent = content
    
    list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        content.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 20)
    end)
    
    self.Objects.Content = content
    self.Objects.List = list
    
    -- Click handler
    button.MouseButton1Click:Connect(function()
        self.Window:SelectTab(self)
    end)
    
    return self
end

function Tab:AddElement(element)
    if not element then return end
    table.insert(self.Elements, element)
    element.Container = self.Objects.Content
    element:Create()
    return element
end

function Tab:Section(config)
    local section = Nova:Section(config)
    section.Container = self.Objects.Content
    section:Create()
    table.insert(self.Elements, section)
    return section
end

function Tab:Button(config)
    return self:AddElement(Nova:Button(config))
end

function Tab:Toggle(config)
    return self:AddElement(Nova:Toggle(config))
end

function Tab:Slider(config)
    return self:AddElement(Nova:Slider(config))
end

function Tab:Dropdown(config)
    return self:AddElement(Nova:Dropdown(config))
end

function Tab:Input(config)
    return self:AddElement(Nova:Input(config))
end

function Tab:Keybind(config)
    return self:AddElement(Nova:Keybind(config))
end

function Tab:ColorPicker(config)
    return self:AddElement(Nova:ColorPicker(config))
end

-- =============================================
-- WINDOW SYSTEM
-- =============================================

local Window = {}
Window.__index = Window

function Nova:CreateWindow(config)
    config = config or {}
    config.Title = config.Title or "Nova UI"
    config.SubTitle = config.SubTitle or ""
    config.Size = config.Size or UDim2.fromOffset(800, 500)
    config.Position = config.Position or UDim2.new(0.5, -400, 0.5, -250)
    config.Resizable = config.Resizable ~= false
    config.MinSize = config.MinSize or Vector2.new(400, 300)
    config.MaxSize = config.MaxSize or Vector2.new(1920, 1080)
    config.ShowClose = config.ShowClose ~= false
    config.ShowMinimize = config.ShowMinimize ~= false
    config.ShowMaximize = config.ShowMaximize ~= false
    
    local self = setmetatable({
        Config = config,
        Tabs = {},
        ActiveTab = nil,
        Minimized = false,
        Maximized = false,
        OriginalSize = config.Size,
        OriginalPosition = config.Position,
        Elements = {},
        Nova = Nova
    }, Window)
    
    -- Main window frame
    local frame = Instance.new("Frame")
    frame.Name = "Window"
    frame.Size = config.Size
    frame.Position = config.Position
    frame.BackgroundColor3 = Nova:GetTheme("Background")
    frame.BackgroundTransparency = Nova:GetTheme("BackgroundTransparency")
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.Parent = GUI
    
    Nova:RegisterThemeObject(frame, {
        BackgroundColor3 = "Background"
    })
    
    local frameCorner = Instance.new("UICorner")
    frameCorner.CornerRadius = Nova:GetTheme("LargeCorner")
    frameCorner.Parent = frame
    
    local frameStroke = Instance.new("UIStroke")
    frameStroke.Color = Nova:GetTheme("Border")
    frameStroke.Thickness = 1
    frameStroke.Transparency = 0.5
    frameStroke.Parent = frame
    
    Nova:RegisterThemeObject(frameStroke, {
        Color = "Border"
    })
    
    -- Shadow
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 60, 1, 60)
    shadow.Position = UDim2.new(0.5, -30, 0.5, -30)
    shadow.AnchorPoint = Vector2.new(0.5, 0.5)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://13155655345"
    shadow.ImageColor3 = Nova:GetTheme("Shadow")
    shadow.ImageTransparency = Nova:GetTheme("ShadowTransparency")
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(30, 30, 30, 30)
    shadow.Parent = frame
    
    Nova:RegisterThemeObject(shadow, {
        ImageColor3 = "Shadow",
        ImageTransparency = "ShadowTransparency"
    })
    
    self.Objects = {
        Frame = frame,
        Shadow = shadow
    }
    
    -- Title bar
    local titleBar = Instance.new("Frame")
    titleBar.Name = "TitleBar"
    titleBar.Size = UDim2.new(1, 0, 0, 40)
    titleBar.BackgroundColor3 = Nova:GetTheme("Surface")
    titleBar.BackgroundTransparency = Nova:GetTheme("SurfaceTransparency")
    titleBar.BorderSizePixel = 0
    titleBar.Parent = frame
    
    Nova:RegisterThemeObject(titleBar, {
        BackgroundColor3 = "Surface"
    })
    
    local titleBarCorner = Instance.new("UICorner")
    titleBarCorner.CornerRadius = Nova:GetTheme("LargeCorner")
    titleBarCorner.Parent = titleBar
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Size = UDim2.new(0, 200, 1, 0)
    title.Position = UDim2.new(0, 15, 0, 0)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = config.Title
    title.TextColor3 = Nova:GetTheme("Text")
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = titleBar
    
    Nova:RegisterThemeObject(title, {
        TextColor3 = "Text"
    })
    
    -- Subtitle
    if config.SubTitle and config.SubTitle ~= "" then
        local subtitle = Instance.new("TextLabel")
        subtitle.Name = "SubTitle"
        subtitle.Size = UDim2.new(0, 200, 1, 0)
        subtitle.Position = UDim2.new(0, 15 + title.TextBounds.X + 10, 0, 0)
        subtitle.BackgroundTransparency = 1
        subtitle.Font = Enum.Font.Gotham
        subtitle.Text = config.SubTitle
        subtitle.TextColor3 = Nova:GetTheme("TextDark")
        subtitle.TextSize = 14
        subtitle.TextXAlignment = Enum.TextXAlignment.Left
        subtitle.Parent = titleBar
        
        Nova:RegisterThemeObject(subtitle, {
            TextColor3 = "TextDark"
        })
    end
    
    -- Window controls
    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.Size = UDim2.new(0, 100, 1, 0)
    controls.Position = UDim2.new(1, -15, 0, 0)
    controls.AnchorPoint = Vector2.new(1, 0)
    controls.BackgroundTransparency = 1
    controls.Parent = titleBar
    
    local controlList = Instance.new("UIListLayout")
    controlList.FillDirection = Enum.FillDirection.Horizontal
    controlList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    controlList.VerticalAlignment = Enum.VerticalAlignment.Center
    controlList.Padding = UDim.new(0, 5)
    controlList.Parent = controls
    
    -- Close button
    if config.ShowClose then
        local closeBtn = Instance.new("ImageButton")
        closeBtn.Name = "Close"
        closeBtn.Size = UDim2.new(0, 30, 0, 30)
        closeBtn.BackgroundTransparency = 1
        closeBtn.Image = Nova:GetIcon("x")
        closeBtn.ImageColor3 = Nova:GetTheme("TextDark")
        closeBtn.Parent = controls
        
        Nova:RegisterThemeObject(closeBtn, {
            ImageColor3 = "TextDark"
        })
        
        closeBtn.MouseButton1Click:Connect(function()
            frame.Visible = false
        end)
    end
    
    -- Maximize button
    if config.ShowMaximize then
        local maxBtn = Instance.new("ImageButton")
        maxBtn.Name = "Maximize"
        maxBtn.Size = UDim2.new(0, 30, 0, 30)
        maxBtn.BackgroundTransparency = 1
        maxBtn.Image = Nova:GetIcon("maximize")
        maxBtn.ImageColor3 = Nova:GetTheme("TextDark")
        maxBtn.Parent = controls
        
        Nova:RegisterThemeObject(maxBtn, {
            ImageColor3 = "TextDark"
        })
        
        maxBtn.MouseButton1Click:Connect(function()
            self:ToggleMaximize()
        end)
    end
    
    -- Minimize button
    if config.ShowMinimize then
        local minBtn = Instance.new("ImageButton")
        minBtn.Name = "Minimize"
        minBtn.Size = UDim2.new(0, 30, 0, 30)
        minBtn.BackgroundTransparency = 1
        minBtn.Image = Nova:GetIcon("minimize")
        minBtn.ImageColor3 = Nova:GetTheme("TextDark")
        minBtn.Parent = controls
        
        Nova:RegisterThemeObject(minBtn, {
            ImageColor3 = "TextDark"
        })
        
        minBtn.MouseButton1Click:Connect(function()
            self:ToggleMinimize()
        end)
    end
    
    self.Objects.TitleBar = titleBar
    self.Objects.Controls = controls
    
    -- Tabs container
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(0, 150, 1, -40)
    tabContainer.Position = UDim2.new(0, 0, 0, 40)
    tabContainer.BackgroundColor3 = Nova:GetTheme("Surface")
    tabContainer.BackgroundTransparency = Nova:GetTheme("SurfaceTransparency") + 0.2
    tabContainer.BorderSizePixel = 0
    tabContainer.Parent = frame
    
    Nova:RegisterThemeObject(tabContainer, {
        BackgroundColor3 = "Surface"
    })
    
    local tabCorner = Instance.new("UICorner")
    tabCorner.CornerRadius = UDim.new(0, 8)
    tabCorner.Parent = tabContainer
    
    local tabList = Instance.new("ScrollingFrame")
    tabList.Name = "TabList"
    tabList.Size = UDim2.new(1, 0, 1, 0)
    tabList.BackgroundTransparency = 1
    tabList.BorderSizePixel = 0
    tabList.ScrollBarThickness = 0
    tabList.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabList.Parent = tabContainer
    
    local tabLayout = Instance.new("UIListLayout")
    tabLayout.Padding = UDim.new(0, 2)
    tabLayout.Parent = tabList
    
    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        tabList.CanvasSize = UDim2.new(0, 0, 0, tabLayout.AbsoluteContentSize.Y)
    end)
    
    self.Objects.TabContainer = tabContainer
    self.Objects.TabList = tabList
    self.Objects.TabLayout = tabLayout
    
    -- Content container
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -160, 1, -50)
    contentContainer.Position = UDim2.new(0, 155, 0, 45)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = frame
    
    self.Objects.Content = contentContainer
    
    -- Resize handles
    if config.Resizable then
        local handles = {}
        local handleSize = 10
        
        for _, pos in ipairs({"TopLeft", "Top", "TopRight", "Right", "BottomRight", "Bottom", "BottomLeft", "Left"}) do
            local handle = Instance.new("Frame")
            handle.Name = "Resize_" .. pos
            handle.BackgroundTransparency = 1
            handle.Size = UDim2.new(0, handleSize, 0, handleSize)
            handle.Parent = frame
            
            if pos == "TopLeft" then
                handle.Position = UDim2.new(0, 0, 0, 0)
                handle.Cursor = "SizeNWSE"
            elseif pos == "Top" then
                handle.Size = UDim2.new(1, -handleSize*2, 0, handleSize)
                handle.Position = UDim2.new(0, handleSize, 0, 0)
                handle.Cursor = "SizeNS"
            elseif pos == "TopRight" then
                handle.Position = UDim2.new(1, -handleSize, 0, 0)
                handle.Cursor = "SizeNESW"
            elseif pos == "Right" then
                handle.Size = UDim2.new(0, handleSize, 1, -handleSize*2)
                handle.Position = UDim2.new(1, -handleSize, 0, handleSize)
                handle.Cursor = "SizeWE"
            elseif pos == "BottomRight" then
                handle.Position = UDim2.new(1, -handleSize, 1, -handleSize)
                handle.Cursor = "SizeNWSE"
            elseif pos == "Bottom" then
                handle.Size = UDim2.new(1, -handleSize*2, 0, handleSize)
                handle.Position = UDim2.new(0, handleSize, 1, -handleSize)
                handle.Cursor = "SizeNS"
            elseif pos == "BottomLeft" then
                handle.Position = UDim2.new(0, 0, 1, -handleSize)
                handle.Cursor = "SizeNESW"
            elseif pos == "Left" then
                handle.Size = UDim2.new(0, handleSize, 1, -handleSize*2)
                handle.Position = UDim2.new(0, 0, 0, handleSize)
                handle.Cursor = "SizeWE"
            end
            
            -- Resize logic would go here
            handles[pos] = handle
        end
    end
    
    -- Make draggable
    MakeDraggable(titleBar, frame, function(newPos)
        if self.Maximized then
            self:ToggleMaximize()
        end
    end)
    
    self.Objects.Frame = frame
    Nova.Windows = Nova.Windows or {}
    table.insert(Nova.Windows, self)
    
    return self
end

function Window:AddTab(config)
    local tab = Nova:Tab(config)
    tab:Create(self, self.Objects.TabList)
    table.insert(self.Tabs, tab)
    
    if not self.ActiveTab then
        self:SelectTab(tab)
    end
    
    return tab
end

function Window:SelectTab(tab)
    if self.ActiveTab then
        -- Deactivate previous tab
        self.ActiveTab.Objects.Title.TextColor3 = Nova:GetTheme("TextDark")
        Nova:RegisterThemeObject(self.ActiveTab.Objects.Title, {
            TextColor3 = "TextDark"
        })
        
        if self.ActiveTab.Objects.Icon then
            self.ActiveTab.Objects.Icon.ImageColor3 = Nova:GetTheme("TextDark")
            Nova:RegisterThemeObject(self.ActiveTab.Objects.Icon, {
                ImageColor3 = "TextDark"
            })
        end
        
        self.ActiveTab.Objects.Indicator.Visible = false
        self.ActiveTab.Objects.Content.Visible = false
    end
    
    self.ActiveTab = tab
    
    -- Activate new tab
    tab.Objects.Title.TextColor3 = Nova:GetTheme("Text")
    Nova:RegisterThemeObject(tab.Objects.Title, {
        TextColor3 = "Text"
    })
    
    if tab.Objects.Icon then
        tab.Objects.Icon.ImageColor3 = Nova:GetTheme("Text")
        Nova:RegisterThemeObject(tab.Objects.Icon, {
            ImageColor3 = "Text"
        })
    end
    
    tab.Objects.Indicator.Visible = true
    tab.Objects.Content.Visible = true
end

function Window:ToggleMinimize()
    if self.Minimized then
        -- Restore
        TweenService:Create(self.Objects.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = self.OriginalSize,
            Position = self.OriginalPosition
        }):Play()
        
        self.Objects.TabContainer.Visible = true
        self.Objects.Content.Visible = true
    else
        -- Minimize
        self.OriginalSize = self.Objects.Frame.Size
        self.OriginalPosition = self.Objects.Frame.Position
        
        TweenService:Create(self.Objects.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, 200, 0, 40),
            Position = UDim2.new(1, -210, 1, -50)
        }):Play()
        
        self.Objects.TabContainer.Visible = false
        self.Objects.Content.Visible = false
    end
    
    self.Minimized = not self.Minimized
end

function Window:ToggleMaximize()
    if self.Maximized then
        -- Restore
        TweenService:Create(self.Objects.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = self.OriginalSize,
            Position = self.OriginalPosition
        }):Play()
    else
        -- Maximize
        self.OriginalSize = self.Objects.Frame.Size
        self.OriginalPosition = self.Objects.Frame.Position
        
        local viewport = workspace.CurrentCamera.ViewportSize
        TweenService:Create(self.Objects.Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
            Size = UDim2.new(0, viewport.X, 0, viewport.Y),
            Position = UDim2.new(0, 0, 0, 0)
        }):Play()
    end
    
    self.Maximized = not self.Maximized
end

function Window:CloseAllDropdowns()
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if element.Type == "Dropdown" and element.Opened then
                element:Close()
            end
            
            if element.Type == "Section" then
                for _, subElement in ipairs(element.Elements) do
                    if subElement.Type == "Dropdown" and subElement.Opened then
                        subElement:Close()
                    end
                end
            end
        end
    end
end

function Window:UpdateTheme()
    -- Update all registered objects for this window
    for _, tab in ipairs(self.Tabs) do
        for _, element in ipairs(tab.Elements) do
            if element.Objects and element.Objects.Frame then
                Nova:ApplyThemeToObject(element.Objects.Frame, {BackgroundColor3 = "Element"})
            end
        end
    end
end

function Window:Destroy()
    self.Objects.Frame:Destroy()
end

-- =============================================
-- DIALOG SYSTEM
-- =============================================

function Nova:Dialog(config)
    config = config or {}
    config.Title = config.Title or "Dialog"
    config.Content = config.Content or ""
    config.Buttons = config.Buttons or {{Title = "OK"}}
    
    local dialog = Instance.new("Frame")
    dialog.Name = "Dialog"
    dialog.Size = UDim2.new(0, 400, 0, 200)
    dialog.Position = UDim2.new(0.5, -200, 0.5, -100)
    dialog.BackgroundColor3 = self:GetTheme("Surface")
    dialog.BackgroundTransparency = 0.05
    dialog.BorderSizePixel = 0
    dialog.Parent = GUI
    
    self:RegisterThemeObject(dialog, {
        BackgroundColor3 = "Surface"
    })
    
    local dialogCorner = Instance.new("UICorner")
    dialogCorner.CornerRadius = self:GetTheme("LargeCorner")
    dialogCorner.Parent = dialog
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Font = Enum.Font.GothamBold
    title.Text = config.Title
    title.TextColor3 = self:GetTheme("Text")
    title.TextSize = 20
    title.Parent = dialog
    
    self:RegisterThemeObject(title, {
        TextColor3 = "Text"
    })
    
    -- Content
    local content = Instance.new("TextLabel")
    content.Size = UDim2.new(1, -40, 0, 60)
    content.Position = UDim2.new(0, 20, 0, 50)
    content.BackgroundTransparency = 1
    content.Font = Enum.Font.Gotham
    content.Text = config.Content
    content.TextColor3 = self:GetTheme("TextDark")
    content.TextSize = 14
    content.TextWrapped = true
    content.Parent = dialog
    
    self:RegisterThemeObject(content, {
        TextColor3 = "TextDark"
    })
    
    -- Buttons container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Size = UDim2.new(1, -40, 0, 40)
    buttonContainer.Position = UDim2.new(0, 20, 1, -50)
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Parent = dialog
    
    local buttonList = Instance.new("UIListLayout")
    buttonList.FillDirection = Enum.FillDirection.Horizontal
    buttonList.HorizontalAlignment = Enum.HorizontalAlignment.Right
    buttonList.VerticalAlignment = Enum.VerticalAlignment.Center
    buttonList.Padding = UDim.new(0, 10)
    buttonList.Parent = buttonContainer
    
    -- Buttons
    for _, btnConfig in ipairs(config.Buttons) do
        local button = Instance.new("TextButton")
        button.Size = UDim2.new(0, 100, 0, 35)
        button.BackgroundColor3 = self:GetTheme("Primary")
        button.BackgroundTransparency = 0
        button.Font = Enum.Font.GothamSemibold
        button.Text = btnConfig.Title
        button.TextColor3 = self:GetTheme("TextInverse")
        button.TextSize = 14
        button.Parent = buttonContainer
        
        self:RegisterThemeObject(button, {
            BackgroundColor3 = "Primary",
            TextColor3 = "TextInverse"
        })
        
        local buttonCorner = Instance.new("UICorner")
        buttonCorner.CornerRadius = UDim.new(0, 6)
        buttonCorner.Parent = button
        
        button.MouseButton1Click:Connect(function()
            if btnConfig.Callback then
                self:SafeCallback(btnConfig.Callback)
            end
            dialog:Destroy()
        end)
    end
    
    -- Close on outside click
    local blocker = Instance.new("TextButton")
    blocker.Name = "Blocker"
    blocker.Size = UDim2.new(1, 0, 1, 0)
    blocker.BackgroundTransparency = 0.5
    blocker.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    blocker.Text = ""
    blocker.Parent = GUI
    
    blocker.MouseButton1Click:Connect(function()
        blocker:Destroy()
        dialog:Destroy()
    end)
    
    -- Animate in
    dialog.Position = UDim2.new(0.5, -200, 1, 50)
    TweenService:Create(dialog, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Position = UDim2.new(0.5, -200, 0.5, -100)
    }):Play()
    
    return dialog
end

-- =============================================
-- TOOLTIP SYSTEM
-- =============================================

local Tooltip = Instance.new("Frame")
Tooltip.Name = "Tooltip"
Tooltip.Size = UDim2.new(0, 0, 0, 30)
Tooltip.BackgroundColor3 = Nova:GetTheme("Surface")
Tooltip.BackgroundTransparency = 0.1
Tooltip.BorderSizePixel = 0
Tooltip.Visible = false
Tooltip.Parent = GUI

Nova:RegisterThemeObject(Tooltip, {
    BackgroundColor3 = "Surface"
})

local TooltipCorner = Instance.new("UICorner")
TooltipCorner.CornerRadius = UDim.new(0, 6)
TooltipCorner.Parent = Tooltip

local TooltipText = Instance.new("TextLabel")
TooltipText.Name = "Text"
TooltipText.Size = UDim2.new(1, -20, 1, 0)
TooltipText.Position = UDim2.new(0, 10, 0, 0)
TooltipText.BackgroundTransparency = 1
TooltipText.Font = Enum.Font.Gotham
TooltipText.Text = ""
TooltipText.TextColor3 = Nova:GetTheme("Text")
TooltipText.TextSize = 13
TooltipText.TextXAlignment = Enum.TextXAlignment.Left
TooltipText.Parent = Tooltip

Nova:RegisterThemeObject(TooltipText, {
    TextColor3 = "Text"
})

function Nova:ShowTooltip(text, position)
    TooltipText.Text = text
    Tooltip.Size = UDim2.new(0, TooltipText.TextBounds.X + 20, 0, 30)
    Tooltip.Position = UDim2.fromOffset(position.X, position.Y - 35)
    Tooltip.Visible = true
    
    -- Auto hide after 2 seconds
    task.delay(2, function()
        Tooltip.Visible = false
    end)
end

-- =============================================
-- EXPORT
-- =============================================

-- Create global instance
getgenv().Nova = Nova

-- Auto-load configuration if exists
task.spawn(function()
    if not isfolder or not isfile then return end
    
    local configFolder = "NovaUI"
    local configFile = configFolder .. "/config.json"
    
    if not isfolder(configFolder) then
        makefolder(configFolder)
    end
    
    if isfile(configFile) then
        local success, data = pcall(function()
            return HttpService:JSONDecode(readfile(configFile))
        end)
        
        if success and data.Theme then
            Nova:SetTheme(data.Theme)
        end
    end
end)

return Nova
