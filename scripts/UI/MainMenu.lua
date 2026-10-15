-- 主菜单以纸页与水彩人物构成双栏；按钮、标题统一由主题提供。
local UI = require("urhox-libs/UI")
local Art = require("UI.ArtTheme")
local Preferences = require("UI.Preferences")
local MainMenu = {}
local C = Art.C

function MainMenu.Create(onStart, onGallery, onDice)
    local hero = Art.Picture("image/Art/Characters/intern_normal.png", {
        position = "absolute", id = "menu_character", backgroundFit = "contain",
    })
    local tableRing = UI.Panel {position = "absolute", width = 340, height = 340, borderRadius = 170,
        backgroundColor = C.dark, borderWidth = 1, borderColor = {192, 158, 94, 100}, pointerEvents = "none"}
    local sceneLabel = Art.Text("席位未定，故事待写。", 13, C.paper, {
        position = "absolute", textAlign = "center", letterSpacing = 2, pointerEvents = "none"})
    local titleTop = Art.Title("酒桌", 64, C.ink, {width = "100%", lineHeight = 1.1, letterSpacing = 2})
    local titleBottom = Art.Title("文化", 64, C.ink, {width = "100%", lineHeight = 1.1, letterSpacing = 2})
    local title = UI.Panel {width = "100%", children = {titleTop, titleBottom}}
    local slogan = Art.Text("把每一场应酬，\n写成自己的生存手记。", 18, C.ink, {width = "100%", lineHeight = 1.55})
    local note = Art.Text("选一份工作，带着你的本事入席。\n在面子与清醒之间，找到自己的位置。", 12, C.muted,
        {width = "100%", lineHeight = 1.65})
    local rule = UI.Panel {width = 44, height = 3, backgroundColor = C.yellow, marginVertical = 8}
    local intro = Art.Paper({
        Art.Text("职 场 生 存 手 记", 11, C.purple, {width = "100%", letterSpacing = 2}),
        title, rule,
        slogan, note,
    }, {position = "absolute", id = "menu_intro", padding = 30, gap = 12})

    local start = Art.Button("开始入职  →", onStart, false,
        {id = "start_game", width = "100%", minHeight = 58, fontSize = 19})
    local gallery = Art.Button("人物图鉴", onGallery, true,
        {id = "open_gallery", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0})
    local dice = Art.Button("摇骰练习", onDice, true,
        {id = "open_dice_demo", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0})
    local actions = UI.Panel {position = "absolute", id = "menu_actions", gap = 10, children = {
        start, UI.Panel {width = "100%", flexDirection = "row", gap = 10, children = {gallery, dice}},
    }}
    local settings = Art.Button("设置", function() Preferences.ShowSettings() end, true,
        {id = "open_settings", width = 88, minHeight = 40, paddingVertical = 6, fontSize = 12})
    local header = UI.Panel {position = "absolute", height = 42, flexDirection = "row", alignItems = "center",
        justifyContent = "space-between", children = {
            Art.Text("酒桌文化 / 生存手记", 12, C.paper, {flexGrow = 1, flexBasis = 0, flexShrink = 1}), settings,
        }}
    local footer = Art.Text("适度饮酒，拒绝酒驾。饭局之外，也要好好生活。", 10, C.paper,
        {position = "absolute", lineHeight = 1.5})
    local veil = UI.Panel {position = "absolute", width = "100%", height = "100%",
        backgroundColor = {36, 27, 43, 158}, pointerEvents = "none"}
    local safe = Art.Safe({tableRing, hero, sceneLabel, intro, actions, header, footer})
    local root = Art.Root({veil, safe}, "image/Art/Backgrounds/bg_menu.png")

    -- 只调节现有控件，不重建页面，不触发开局或导航。
    return Art.Responsive(root, function(w, h)
        local portrait = h > w * 1.05
        local compact = h < 550
        local margin = portrait and 20 or math.max(24, math.floor(w * 0.055))
        local leftWidth = portrait and (w - margin * 2) or math.min(490, math.floor(w * 0.44))
        header:SetStyle({left = margin, top = 12, width = w - margin * 2})
        footer:SetStyle({left = margin, bottom = 12, width = w - margin * 2, textAlign = portrait and "center" or "left"})
        note:SetVisible(h > 850 and not portrait)
        sceneLabel:SetVisible(not compact)
        rule:SetVisible(not compact)
        if portrait then
            local heroTop = 62
            local heroHeight = math.max(210, math.floor(h * 0.35))
            ---@type number
            local paperTop = heroTop + heroHeight - 14
            ---@type number
            local paperHeight = math.max(210, h - paperTop - 174)
            tableRing:SetStyle({left = w * 0.18, top = heroTop + 18, width = w * 0.64,
                height = w * 0.64, borderRadius = w * 0.32})
            hero:SetStyle({left = w * 0.22, top = heroTop - 12, width = w * 0.64, height = heroHeight + 12})
            sceneLabel:SetStyle({left = margin, top = heroTop + heroHeight - 45, width = w - margin * 2})
            intro:SetStyle({left = margin, top = paperTop, width = leftWidth, height = paperHeight,
                padding = 24, gap = 9, justifyContent = "center"})
            title:SetStyle({flexDirection = "row"})
            titleTop:SetStyle({width = "50%", letterSpacing = 4})
            titleBottom:SetStyle({width = "50%", letterSpacing = 4})
            local fontSize = math.min(60, math.floor((leftWidth - 48) / 6))
            titleTop:SetFontSize(fontSize)
            titleBottom:SetFontSize(fontSize)
            slogan:SetText("把每一场应酬，写成自己的生存手记。")
            slogan:SetFontSize(16)
            actions:SetStyle({left = margin, bottom = 54, width = leftWidth})
        else
            local top = compact and 55 or math.max(70, math.floor(h * 0.12))
            local actionsBottom = compact and 46 or 64
            local paperHeight = h - top - actionsBottom - (compact and 118 or 150)
            local titleRows = not compact and paperHeight > 540
            intro:SetStyle({left = margin, top = top, width = leftWidth, height = math.max(180, paperHeight),
                padding = compact and 20 or 30, gap = compact and 5 or 12, justifyContent = "center"})
            title:SetStyle({flexDirection = titleRows and "column" or "row"})
            titleTop:SetStyle({width = titleRows and "100%" or "50%", letterSpacing = titleRows and 5 or 3})
            titleBottom:SetStyle({width = titleRows and "100%" or "50%", letterSpacing = titleRows and 5 or 3})
            local fontSize = titleRows and math.min(68, math.floor(h * 0.09)) or math.min(52, math.floor((leftWidth - 60) / 6))
            titleTop:SetFontSize(fontSize)
            titleBottom:SetFontSize(fontSize)
            slogan:SetText(compact and "酒桌之上，你会如何落座？" or "把每一场应酬，\n写成自己的生存手记。")
            slogan:SetFontSize(compact and 14 or 18)
            local rightX = margin + leftWidth + 20
            local rightWidth = w - rightX - margin
            ---@type number
            local ring = math.min(rightWidth * 0.94, h * 0.65)
            tableRing:SetStyle({left = rightX + (rightWidth - ring) / 2, top = (h - ring) / 2 + 20,
                width = ring, height = ring, borderRadius = ring / 2})
            hero:SetStyle({left = rightX, top = compact and 40 or 50, width = rightWidth, height = h - 95})
            sceneLabel:SetStyle({left = rightX, top = h - 80, width = rightWidth})
            actions:SetStyle({left = margin, bottom = actionsBottom, width = leftWidth})
        end
        start:SetStyle({minHeight = compact and 48 or 58, paddingVertical = compact and 8 or 12})
        gallery:SetStyle({minHeight = compact and 42 or 46})
        dice:SetStyle({minHeight = compact and 42 or 46})
        print(string.format("[MainMenu] 排版 %.0fx%.0f", w, h))
    end)
end

return MainMenu
