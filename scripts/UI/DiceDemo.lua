-- 摇骰练习沿用立体骰子控件，仅统一纸卡、桌布与交互主题。
local UI = require("urhox-libs/UI")
local Widget = require("urhox-libs/UI/Core/Widget")
local Dice3D = require("UI.Dice3D")
local Art = require("UI.ArtTheme")
local C = Art.C
local DiceDemo = {}
local ROLL_SFX, LAND_SFX = "audio/sfx/dice_roll.mp3", "audio/sfx/dice_land.mp3"

---@class DiceDemoRoot : Widget
---@field soundScene_ Scene?
---@field rollSource_ SoundSource?
---@field landSource_ SoundSource?
local DemoRoot = Widget:Extend("DiceDemoRoot")

function DemoRoot:Init(props)
    Widget.Init(self, props)
end

function DemoRoot:PlaySound(path, landing)
    if not self.soundScene_ then
        self.soundScene_ = Scene()
        local node = self.soundScene_:CreateChild("DiceAudio")
        self.rollSource_ = node:CreateComponent("SoundSource")
        self.landSource_ = node:CreateComponent("SoundSource")
        self.rollSource_.soundType = SOUND_EFFECT
        self.landSource_.soundType = SOUND_EFFECT
    end
    local source = landing and self.landSource_ or self.rollSource_
    local sound = cache:GetResource("Sound", path)
    if source and sound then
        source:Play(sound, sound:GetFrequency(), landing and 0.75 or 0.65)
    else
        print("[DiceDemo] 音效未就绪: " .. path)
    end
end

function DemoRoot:Destroy()
    if self.soundScene_ then
        if self.rollSource_ then self.rollSource_:Stop() end
        if self.landSource_ then self.landSource_:Stop() end
        self.soundScene_:Dispose()
        self.soundScene_, self.rollSource_, self.landSource_ = nil, nil, nil
    end
    Widget.Destroy(self)
end

local STYLES = {
    {key = "classic", title = "标准骰子", subtitle = "白色陶瓷 · 黑色凹点",
        preview = "image/标准骰子立体图_20261008124016.png"},
    {key = "cthulhu", title = "克苏鲁骰子", subtitle = "深海石碑 · 触手纹饰",
        preview = "image/克苏鲁骰子立体图_20261008124020.png"},
}

-- 主题按钮为 Panel，以禁用标志与透明度统一控制，不依赖 Button 子类方法。
local function Disable(button, disabled)
    Art.SetDisabled(button, disabled)
end

---@param onBack fun()
---@return Widget
function DiceDemo.CreateScreen(onBack)
    local demo = DemoRoot:new({width = "100%", height = "100%", pointerEvents = "box-none"})
    ---@type Dice3DView[]
    local views = {}
    ---@type Widget[]
    local buttons = {}
    local cards = {}
    local allButton = Art.Button("同时摇两颗  →", function()
        for _, view in ipairs(views) do if view:IsRolling() then return end end
        for _, view in ipairs(views) do view:Roll() end
    end, false, {id = "roll_all", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 170})
    local function Refresh()
        local busy = false
        for i, view in ipairs(views) do
            local rolling = view:IsRolling()
            if buttons[i] then Disable(buttons[i], rolling) end
            busy = busy or rolling
        end
        Disable(allButton, busy)
    end

    for index, style in ipairs(STYLES) do
        local label = Art.Title("等待落定", 19, C.purple, {width = "100%", textAlign = "center"})
        local view = Dice3D.View {
            id = "dice_" .. style.key, styleKey = style.key,
            width = "100%", height = 250, flexShrink = 0,
            onRollStart = function()
                label:SetText("翻滚中…")
                demo:PlaySound(ROLL_SFX, false)
                Refresh()
            end,
            onLand = function() demo:PlaySound(LAND_SFX, true) end,
            onComplete = function(result)
                label:SetText(tostring(result) .. " 点")
                Refresh()
            end,
        }
        views[index] = view
        local button = Art.Button("摇一摇", function()
            if not view:IsRolling() then view:Roll() end
        end, false, {id = "roll_" .. style.key, width = "100%"})
        buttons[index] = button
        cards[#cards + 1] = Art.Paper({
            UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 12, children = {
                Art.Picture(style.preview, {width = 48, height = 48, borderRadius = 8, backgroundFit = "cover"}),
                UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, gap = 4, children = {
                    Art.Title(style.title, 20, C.ink, {width = "100%"}),
                    Art.Text(style.subtitle, 11, C.muted, {width = "100%"}),
                }},
            }},
            UI.Panel {width = "100%", borderRadius = 12, backgroundColor = C.dark, overflow = "hidden", children = {view}},
            label, button,
        }, {padding = 18, gap = 12, minWidth = 0})
    end
    local headline = Art.Title("桌边摇骰练习", 27, C.paper, {width = "100%"})
    local subtitle = Art.Text("先熟悉手感，再从容入席。这里不改变游戏进度。", 12, C.paper,
        {width = "100%", opacity = 0.8})
    local heading = UI.Panel {width = "100%", paddingHorizontal = 24, paddingVertical = 16, gap = 6,
        backgroundColor = C.dark, children = {headline, subtitle}}
    local grid = UI.SimpleGrid {width = "100%", minColumnWidth = 300, gap = 18, children = cards}
    local body = UI.Panel {width = "100%", maxWidth = 900, alignSelf = "center", padding = 22, gap = 16, children = {
        grid,
        UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 12, children = {
            allButton, Art.Button("返回主菜单", onBack, true,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 140}),
        }},
        Art.Text("多轴翻滚，弹跳落定。选择喜欢的骰子，轻松试一局。", 11, C.muted,
            {width = "100%", textAlign = "center"}),
    }}
    demo:AddChild(Art.Safe({heading,
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, flexShrink = 1, minHeight = 0,
            scrollY = true, children = {body}},
    }))
    local root = Art.Root({demo})
    print("[DiceDemo] 标准 / 克苏鲁立体演示已打开")
    return Art.Responsive(root, function(w, h)
        local compact = h < 550
        heading:SetStyle({paddingVertical = compact and 9 or 16})
        headline:SetFontSize(compact and 21 or 27)
        body:SetStyle({padding = w < 620 and 14 or 22, gap = compact and 12 or 16})
        for _, view in ipairs(views) do view:SetStyle({height = compact and 132 or 235}) end
        for _, card in ipairs(cards) do card:SetStyle({padding = compact and 12 or 18, gap = compact and 8 or 12}) end
    end)
end

return DiceDemo
