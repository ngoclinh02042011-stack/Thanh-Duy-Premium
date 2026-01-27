local WindUI = loadstring(game:HttpGet("https://github.com/Footagesus/WindUI/releases/latest/download/main.lua"))()

WindUI:AddTheme({
    Name = "My Theme", -- theme name
    
    Accent = Color3.fromHex("#18181b"),
    Background = Color3.fromHex("#101010"), -- Accent
    Outline = Color3.fromHex("#FFFFFF"),
    Text = Color3.fromHex("#FFFFFF"),
    Placeholder = Color3.fromHex("#7a7a7a"),
    Button = Color3.fromHex("#52525b"),
    Icon = Color3.fromHex("#a1a1aa"),
})

local Window = WindUI:CreateWindow({
    Title = "🔥 ThanhDuy HUB | TSB 🔥",
    Icon = "app-window", -- lucide icon
    Author = "by ThanhDuy",
    Folder = "MySuperHub",
    
    -- ↓ This all is Optional. You can remove it.
    Background = "rbxassetid://124984802322746", -- rbxassetid
    Size = UDim2.fromOffset(580, 460),
    MinSize = Vector2.new(560, 350),
    MaxSize = Vector2.new(850, 560),
    Transparent = true,
    Theme = "My Theme",
    Resizable = true,
    SideBarWidth = 200,
    BackgroundImageTransparency = 0.65,
    HideSearchBar = true,
    ScrollBarEnabled = false,
    
    -- ↓ Optional. You can remove it.
    --[[ You can set 'rbxassetid://' or video to Background.
        'rbxassetid://':
            Background = "rbxassetid://", -- rbxassetid
        Video:
            Background = "video:YOUR-RAW-LINK-TO-VIDEO.webm", -- video 
    --]]
    
    -- ↓ Optional. You can remove it.
    User = {
        Enabled = true,
        Anonymous = false,
        Callback = function()
            print("clicked")
        end,
    },
    
    --       remove this all, 
    -- !  ↓  if you DON'T need the key system
    KeySystem = { 
        -- ↓ Optional. You can remove it.
        Key = { "Thanhduy_keylesspremium1609" },
        
        Note = "Key System",
        
        -- ↓ Optional. You can remove it.
        Thumbnail = {
            Image = "rbxassetid://127475420595076",
            Title = "Thumbnail",
        },
        
        -- ↓ Optional. You can remove it.
        URL = "https://link-hub.net/3056710/MxcMgPM0baZw",
        
        -- ↓ Optional. You can remove it.
        SaveKey = true, -- automatically save and load the key.
        
        -- ↓ Optional. You can remove it.
        -- API = {} ← Services. Read about it below ↓
    },
})

Window:EditOpenButton({
    Title = "Open ThanhDuy Hub",
    Icon = "monitor",
    CornerRadius = UDim.new(0,16),
    StrokeThickness = 2,
    Color = ColorSequence.new( -- gradient
        Color3.fromHex("FF0F7B"), 
        Color3.fromHex("F89B29")
    ),
    OnlyMobile = false,
    Enabled = true,
    Draggable = true,
})

local TechTab = Window:Tab({
    Title = "Tech",
    Icon = "zap", -- optional
    Locked = false,
})

--==================================================
-- TECH BUTTONS
--==================================================

TechTab:Button({
    Title = "Kyoto",
    Desc = "",
    Locked = false,
    Callback = function()
        getgenv().Requires4M1 = false
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/Combos/refs/heads/main/Protected_6711617962776331.lua"))()
    end
})

TechTab:Button({
    Title = "Kiba v4 (New)",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/kietsonphongthanhnghia-a11y/Uhyeah/refs/heads/main/Protected_1425045629292384.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Kyoto Rework",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/KyotoTechRework/refs/heads/main/Protected_9378660372508532.lua"))()
    end
})

TechTab:Button({
    Title = "Merebennie Hub V1.5",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/Merebennie%20Hub%20V2"))()
    end
})

TechTab:Button({
    Title = "Kiba v3",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/KibaV3"))()
    end
})

TechTab:Button({
    Title = "Kiba v4",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/Kibav4"))()
    end
})

TechTab:Button({
    Title = "Side Dash Assist",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/5e4945144797011e2c6229d2f8a2a41bd771c018109e2eff0d6e119708c38400/download"))()
    end
})

TechTab:Button({
    Title = "Lix Tech",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MerebennieOfficial/ExoticJn/refs/heads/main/Protected_83737738.txt"))()
    end
})

TechTab:Button({
    Title = "LoopDash V2",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/84e2bd29cccc0f5302267e4dc952cff6816db4af36416cbd477daaa26d60863d.lua"))()
    end
})

TechTab:Button({
    Title = "M1 Reset",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://rawscripts.net/raw/Universal-Script-M1-RESET-57657"))()
    end
})

TechTab:Button({
    Title = "Backdash Cancel",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/YQANTG/YQANTG/refs/heads/main/SOBABYIMSOGOOD.txt"))()
    end
})

TechTab:Button({
    Title = "Lethal Kiba",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/MinhNhatHUB/MinhNhat/refs/heads/main/Lethal%20Kiba.lua"))()
    end
})

TechTab:Button({
    Title = "Side Dash V3",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/23bcf4264b586dc93b16a9b054eddae259938b7421ac5096353079b2e9d74e24.lua"))()
    end
})

TechTab:Button({
    Title = "Supa v2",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/2753546c83053761e44664d36ffe5035d6e20fc8aee1d19f0eb7b933974ae537.lua"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethal/refs/heads/main/Protected_5983112998592296.lua"))()
    end
})

TechTab:Button({
    Title = "Supa Tech V3",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/ea0b7cbd8c395e01ec38271794b2559808d26501bd6e6e30c48660759a7db7b3.lua"))()
    end
})

TechTab:Button({
    Title = "Akira Tech",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/officialakira/Akira-Hub/refs/heads/main/akira%20tech.lua"))()
    end
})

TechTab:Button({
    Title = "Instant Twisted",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantTwistedRevamp/refs/heads/main/Protected_7455521176683315.lua"))()
    end
})

TechTab:Button({
    Title = "Auto Tech",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/NewAutoTech/refs/heads/main/Protected_6389347658054908.lua"))()
    end
})

TechTab:Button({
    Title = "Oreo Rework",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.getpolsec.com/scripts/hosted/909ad4ca04917630a59f7c5714516c003ddb2544f9e739bd1e38b4c0abc255c5.lua"))()
    end
})

TechTab:Button({
    Title = "Lethal Dash FixLag",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/letuankiet09812345-cmyk/Testkiba/refs/heads/main/LethalFixLag-obfuscated.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Boomy Lethal Dash",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://api.junkie-development.de/api/v1/luascripts/public/2345da4cc975b07b3f250f6a83c45687a70c1999b9c46219cd6893771f9dd542/download"))()
    end
})

TechTab:Button({
    Title = "Dripz",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/letuankiet09812345-cmyk/Testkiba/refs/heads/main/4cbcd9b905ee3e41.lua.txt"))()
    end
})

TechTab:Button({
    Title = "Instant Lethal Revamp",
    Desc = "",
    Locked = false,
    Callback = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Cyborg883/InstantLethalRevamp/refs/heads/main/Protected_6977817281150270.lua"))()
    end
})







