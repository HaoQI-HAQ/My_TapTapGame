-- 主菜单独立排版：纸张、墨色标题与入职纸签，不复用饭局中的笔刷按钮。
local UI = require("urhox-libs/UI")
local Art = require("UI.ArtTheme")
local MainMenu = {}
local C = Art.C

local function Text(text, size, color, extra)
    return Art.Text(text, size, color, Art.Merge({whiteSpace = "nowrap", lineHeight = 1.15}, extra))
end

local function MenuButton(text, index, onClick, primary, id)
    local normal = primary and C.yellow or {255, 250, 237, 242}
    local hover = primary and {255, 207, 91, 255} or {236, 225, 241, 255}
    local label = Text(text, primary and 20 or 13, C.ink, {
        fontFamily = "menu", fontWeight = "bold", flexGrow = 1, flexBasis = 0,
        flexShrink = 1, minWidth = 0, pointerEvents = "none",
    })
    local number = Text(index, 10, primary and C.ink or C.purple, {
        width = 26, textAlign = "center", pointerEvents = "none",
    })
    local arrow = Text("→", primary and 24 or 18, C.ink, {
        width = 28, textAlign = "right", pointerEvents = "none",
    })
    local button = UI.Panel {
        id = id, height = primary and 64 or 52, minWidth = 0,
        paddingHorizontal = primary and 20 or 12,
        flexDirection = "row", alignItems = "center", gap = primary and 16 or 6,
        backgroundColor = normal, borderColor = C.ink,
        borderWidth = 1, borderBottomWidth = primary and 4 or 2,
        borderRadius = 2, pointerEvents = "box-only",
        transition = "backgroundColor 0.14s easeOut, translateY 0.10s easeOut",
        children = {number, label, arrow},
        onClick = onClick,
        onPointerEnter = function(_, widget) widget:SetStyle({backgroundColor = hover}) end,
        onPointerLeave = function(_, widget) widget:SetStyle({backgroundColor = normal, translateY = 0}) end,
        onPointerDown = function(event, widget)
            if event:IsPrimaryButton() then widget:SetStyle({translateY = 2}) end
        end,
        onPointerUp = function(_, widget) widget:SetStyle({translateY = 0}) end,
        onPointerCancel = function(_, widget) widget:SetStyle({translateY = 0, backgroundColor = normal}) end,
    }
    return button
end

function MainMenu.Create(onStart, onGallery, onDice)
    local hero = Art.Picture("image/Art/Characters/intern_normal.png", {
        id = "menu_character", position = "absolute", backgroundFit = "contain",
    })
    local eyebrow = Text("职 场 生 存 手 记", 11, C.purple, {
        width = "100%", fontFamily = "menu", fontWeight = "bold",
    })
    local titleTop = Text("酒桌", 72, C.ink, {
        width = "100%", fontFamily = "menu", fontWeight = "bold", letterSpacing = 5,
    })
    local titleBottom = Text("文化", 72, C.ink, {
        width = "100%", fontFamily = "menu", fontWeight = "bold", letterSpacing = 5,
    })
    local title = UI.Panel {width = "100%", gap = 0, children = {titleTop, titleBottom}}
    local underline = UI.Panel {width = 64, height = 5, backgroundColor = C.yellow, marginTop = 5, marginBottom = 8}
    local slogan = Text("五天之内，\n你能坐到哪张桌子？", 19, C.ink, {
        width = "100%", lineHeight = 1.5, whiteSpace = "normal",
    })
    local intro = UI.Panel {position = "absolute", id = "menu_intro", gap = 8,
        children = {eyebrow, title, underline, slogan}}

    local start = MenuButton("开始入职", "01", onStart, true, "start_game")
    start:SetStyle({width = "100%"})
    local gallery = MenuButton("人物图鉴", "02", onGallery, false, "open_gallery")
    local dice = MenuButton("摇骰练习", "03", onDice, false, "open_dice_demo")
    gallery:SetStyle({flexGrow = 1, flexBasis = 0, flexShrink = 1})
    dice:SetStyle({flexGrow = 1, flexBasis = 0, flexShrink = 1})
    local actionHint = Text("你的第一场饭局，从这里开始。", 11, C.muted, {width = "100%", marginBottom = 2})
    local actions = UI.Panel {position = "absolute", id = "menu_actions", gap = 10, children = {
        actionHint,
        start,
        UI.Panel {width = "100%", flexDirection = "row", gap = 10, children = {gallery, dice}},
    }}
    local header = UI.Panel {position = "absolute", id = "menu_header", height = 26,
        flexDirection = "row", alignItems = "center", justifyContent = "space-between", children = {
            Text("AFTER HOURS", 10, C.muted, {width = 130, letterSpacing = 1}),
            Text("入职档案  /  001", 10, C.purple, {width = 132, textAlign = "right"}),
        }}
    local footer = UI.Panel {position = "absolute", id = "menu_footer", gap = 6, children = {
        UI.Panel {width = "100%", height = 1, backgroundColor = {86, 67, 68, 48}},
        Text("适度饮酒，拒绝酒驾。饭局之外，也要好好生活。", 10, C.muted,
            {width = "100%", whiteSpace = "normal", lineHeight = 1.4}),
        Text("职场应酬生存模拟器  /  v1.2.1", 9, C.muted, {width = "100%"}),
    }}
    local safe = Art.Safe({hero, intro, actions, header, footer})
    local textVeil = UI.Panel {position = "absolute", left = 0, top = 0, width = "100%", height = "100%",
        backgroundColor = {246, 239, 220, 82}, pointerEvents = "none"}
    local root = Art.Root({textVeil, safe}, "image/Art/Backgrounds/bg_menu.png")

    return Art.Responsive(root, function(w, h)
        local portrait = h > w * 1.05
        local margin = portrait and math.max(22, math.floor(w * 0.065)) or math.max(32, math.floor(w * 0.075))
        local compact = h < 650
        local contentWidth = portrait and (w - margin * 2) or math.min(410, math.floor(w * 0.43))
        header:SetStyle({left = margin, top = portrait and 24 or 26, width = w - margin * 2})
        footer:SetStyle({left = margin, bottom = 18, width = contentWidth})
        title:SetStyle({flexDirection = portrait and "column" or "row"})
        titleTop:SetStyle({width = portrait and "100%" or "50%"})
        titleBottom:SetStyle({width = portrait and "100%" or "50%"})
        textVeil:SetStyle({width = portrait and "100%" or "48%",
            backgroundColor = {246, 239, 220, portrait and 82 or 237}})
        actionHint:SetVisible(not compact)
        slogan:SetVisible(portrait or not compact)
        if portrait then
            local titleSize = math.min(66, math.max(42, w * 0.13))
            local introTop = compact and 65 or math.max(78, math.floor(h * 0.105))
            intro:SetStyle({left = margin, top = introTop, width = math.floor(w * 0.58), gap = compact and 4 or 8})
            titleTop:SetFontSize(titleSize)
            titleBottom:SetFontSize(titleSize)
            slogan:SetFontSize(compact and 14 or 17)
            underline:SetStyle({marginTop = compact and 0 or 5, marginBottom = compact and 2 or 8})
            hero:SetStyle({right = -math.floor(w * 0.19), top = introTop + 65,
                width = math.floor(w * 0.88), height = math.max(200, h - introTop - 320)})
            actions:SetStyle({left = margin, bottom = 110, width = contentWidth})
        else
            local titleSize = math.min(compact and 45 or 61, math.floor(contentWidth * 0.145))
            intro:SetStyle({left = margin, top = compact and 66 or math.floor(h * 0.13), width = contentWidth, gap = compact and 3 or 8})
            titleTop:SetFontSize(titleSize)
            titleBottom:SetFontSize(titleSize)
            slogan:SetFontSize(compact and 16 or 19)
            hero:SetStyle({right = math.floor(w * 0.01), top = 60, width = math.floor(w * 0.51), height = h - 115})
            actions:SetStyle({left = margin, bottom = compact and 90 or 105, width = contentWidth})
        end
        start:SetStyle({height = compact and 54 or 64})
        gallery:SetStyle({height = compact and 46 or 52})
        dice:SetStyle({height = compact and 46 or 52})
        print(string.format("[MainMenu] layout %.0fx%.0f %s", w, h, portrait and "portrait" or "landscape"))
    end)
end

return MainMenu
