-- ============================================================================
-- 《酒桌文化》标准 / 克苏鲁立体摇骰演示
-- 保持 2D UI 脚手架；六面贴图在 Dice3D 控件内透视投影，无 3D 场景。
-- ============================================================================
local UI = require("urhox-libs/UI")
local Widget = require("urhox-libs/UI/Core/Widget")
local Dice3D = require("UI.Dice3D")

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
    { key = "classic", title = "标准骰子", subtitle = "白色陶瓷 / 黑色凹点", accent = { 236, 190, 105, 255 },
      preview = "image/标准骰子立体图_20261008124016.png", panel = { 40, 43, 50, 255 } },
    { key = "cthulhu", title = "克苏鲁骰子", subtitle = "深海石碑 / 触手纹饰", accent = { 118, 206, 168, 255 },
      preview = "image/克苏鲁骰子立体图_20261008124020.png", panel = { 24, 43, 40, 255 } },
}

---@param onBack fun()
---@return Widget
function DiceDemo.CreateScreen(onBack)
    local root = DemoRoot:new({ width = "100%", height = "100%", backgroundColor = { 17, 22, 28, 255 } })
    local views, labels, buttons = {}, {}, {}
    local cards = {}
    local allButton = UI.Button { text = "同时摇两颗", width = 180, height = 46, variant = "primary" }
    local function Refresh()
        local busy = false
        for i, view in ipairs(views) do
            local rolling = view:IsRolling()
            buttons[i]:SetDisabled(rolling)
            busy = busy or rolling
        end
        allButton:SetDisabled(busy)
    end

    for index, style in ipairs(STYLES) do
        local label = UI.Label { text = "待摇骰", fontSize = 18, fontColor = style.accent, textAlign = "center" }
        labels[index] = label
        local view = Dice3D.View {
            id = "dice_" .. style.key, styleKey = style.key,
            width = "100%", height = 250, flexShrink = 0,
            onRollStart = function()
                label:SetText("翻滚中…")
                root:PlaySound(ROLL_SFX, false)
                Refresh()
            end,
            onLand = function() root:PlaySound(LAND_SFX, true) end,
            onComplete = function(result)
                label:SetText("结果：" .. result .. " 点")
                Refresh()
            end,
        }
        views[index] = view
        local button = UI.Button {
            id = "roll_" .. style.key, text = "摇一摇", width = "100%", height = 44,
            onClick = function() view:Roll() end,
        }
        buttons[index] = button
        cards[#cards + 1] = UI.Panel {
            width = 290, maxWidth = "100%", padding = 16, gap = 10,
            backgroundColor = style.panel, borderRadius = 18, borderWidth = 1,
            borderColor = { style.accent[1], style.accent[2], style.accent[3], 65 },
            children = {
                UI.Panel {
                    flexDirection = "row", alignItems = "center", gap = 12,
                    children = {
                        UI.Panel { width = 48, height = 48, borderRadius = 9,
                            backgroundImage = style.preview, backgroundFit = "cover" },
                        UI.Panel { gap = 3, flexShrink = 1, children = {
                            UI.Label { text = style.title, fontSize = 19, fontColor = style.accent },
                            UI.Label { text = style.subtitle, fontSize = 11, fontColor = { 165, 180, 182, 255 } },
                        } },
                    },
                },
                view, label, button,
            },
        }
    end
    allButton.props.onClick = function()
        for _, view in ipairs(views) do if view:IsRolling() then return end end
        for _, view in ipairs(views) do view:Roll() end
    end

    root:AddChild(UI.ScrollView {
        width = "100%", height = "100%", flexShrink = 1,
        children = {
            UI.Panel {
                width = "100%", padding = 24, gap = 16, alignItems = "center",
                children = {
                    UI.Label { text = "立体摇骰子", fontSize = 28, fontColor = { 244, 237, 218, 255 } },
                    UI.Label { text = "多轴翻滚 · 透视贴面 · 弹跳落定", fontSize = 13, fontColor = { 159, 177, 183, 255 } },
                    UI.Panel {
                        width = "100%", maxWidth = 620, flexDirection = "row", flexWrap = "wrap",
                        justifyContent = "center", gap = 16, children = cards,
                    },
                    UI.Panel { flexDirection = "row", flexWrap = "wrap", justifyContent = "center", gap = 12, children = {
                        allButton,
                        UI.Button { text = "返回主菜单", width = 140, height = 46, onClick = onBack },
                    } },
                    UI.Label { text = "沿用本地六面素材，落定仍保留立体侧面。", fontSize = 12, fontColor = { 142, 162, 167, 255 } },
                },
            },
        },
    })
    print("[DiceDemo] 标准 / 克苏鲁立体演示已打开")
    return root
end

return DiceDemo
