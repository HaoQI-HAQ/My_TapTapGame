-- 主菜单沿用既有导航：背景、人物、桌前景、标题与按钮独立组合。
local UI = require("urhox-libs/UI")
local Art = require("UI.ArtTheme")
local Preferences = require("UI.Preferences")
local MainMenu = {}
local C, A = Art.C, Art.Assets

function MainMenu.Create(onStart, onGallery, onDice)
    local hero = Art.Picture(A.characters.intern.normal, {position = "absolute", id = "menu_character"})
    local leader = Art.Picture(A.npc.leader.normal, {position = "absolute", id = "menu_leader"})
    local tableArt = Art.Picture(A.foreground, {position = "absolute", backgroundFit = "cover"})
    local speech = Art.Picture(A.speech, {position = "absolute", children = {
        Art.Text("年轻人，\n机会就在杯里。", 16, C.ink, {position = "absolute", left = "16%", top = "18%",
            width = "68%", height = "54%", textAlign = "center", verticalAlign = "middle", fontWeight = "bold"}),
    }})
    local scene = UI.Panel {position = "absolute", id = "menu_scene", overflow = "hidden",
        pointerEvents = "none", children = {hero, leader, tableArt, speech}}
    local paper = UI.Panel {position = "absolute", backgroundColor = C.yellow, pointerEvents = "none"}
    local bottomPaper = UI.Panel {position = "absolute", backgroundColor = C.yellow, pointerEvents = "none"}
    local logo = Art.Picture(A.logo, {position = "absolute", id = "menu_logo"})
    local slogan = Art.Text("五天之内，你能坐到哪张桌子？", 20, C.ink,
        {position = "absolute", fontWeight = "bold", textAlign = "center", lineHeight = 1.3})
    local start = Art.Button("开始入职", onStart, false,
        {id = "start_game", width = "100%", minHeight = 64, fontSize = 24})
    local gallery = Art.Button("角色图鉴", onGallery, true,
        {id = "open_gallery", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, fontSize = 15})
    local settings = Art.Button("设置", function() Preferences.ShowSettings() end, true,
        {id = "open_settings", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, fontSize = 15})
    local dice = Art.Button("摇骰练习", onDice, true,
        {id = "open_dice_demo", width = "100%", minHeight = 48, fontSize = 13})
    local actions = UI.Panel {position = "absolute", id = "menu_actions", gap = 10, children = {
        start, UI.Panel {width = "100%", flexDirection = "row", gap = 12, children = {gallery, settings}}, dice,
    }}
    local savedVolume = tonumber(Preferences.Get("sfxVolume")) or 80
    local soundIcon = Art.Picture(A.icons.sound, {width = 30, height = 30})
    local sound = UI.Panel {position = "absolute", id = "sound_toggle", width = 48, height = 48,
        justifyContent = "center", alignItems = "center", backgroundColor = C.orange,
        borderWidth = 2, borderColor = C.ink, pointerEvents = "box-only", children = {soundIcon},
        onClick = function()
            local volume = tonumber(Preferences.Get("sfxVolume")) or 80
            if volume > 0 then savedVolume = volume; Preferences.Set("sfxVolume", 0)
            else Preferences.Set("sfxVolume", math.max(1, savedVolume)) end
            soundIcon:SetStyle({opacity = (tonumber(Preferences.Get("sfxVolume")) or 0) > 0 and 1 or 0.35})
        end,
    }
    soundIcon:SetStyle({opacity = savedVolume > 0 and 1 or 0.35})
    local footer = Art.Text("适度饮酒，拒绝酒驾。", 11, C.ink,
        {position = "absolute", textAlign = "center", pointerEvents = "none"})
    local safe = Art.Safe({scene, paper, bottomPaper, logo, slogan, actions, sound, footer})
    local root = Art.Root({safe}, A.backgrounds.bbq)

    -- 同一棵控件树响应转屏；按钮回调和既有开局模式选择不变。
    return Art.Responsive(root, function(w, h)
        local portrait = h > w * 1.05
        local unit = Art.Unit()
        local margin = portrait and math.max(20 * unit, w * 0.055) or math.max(28, w * 0.047)
        local compact = h < 560
        sound:SetStyle({right = margin, top = portrait and 12 * unit or 20,
            width = math.max(48 * unit, Art.TouchSize(48)),
            height = math.max(48 * unit, Art.TouchSize(48))})
        soundIcon:SetStyle({width = 30 * unit, height = 30 * unit})
        root:SetBackgroundImage(portrait and A.portraitBackground or A.backgrounds.bbq)
        if portrait then
            local upper = h * 0.27
            local actionHeight = 196 * unit
            local lower = math.max(actionHeight + 54 * unit, h * 0.25)
            local sceneHeight = math.max(160, h - upper - lower)
            paper:SetStyle({left = 0, top = 0, width = w, height = upper + 4})
            bottomPaper:SetStyle({left = 0, top = h - lower, width = w, height = lower})
            scene:SetStyle({left = 0, top = upper, width = w, height = sceneHeight + 12})
            hero:SetStyle({left = w * 0.08, bottom = -sceneHeight * 0.15,
                width = w * 0.46, height = sceneHeight * 1.05})
            leader:SetStyle({left = w * 0.51, bottom = sceneHeight * 0.03,
                width = w * 0.46, height = sceneHeight * 0.70})
            tableArt:SetStyle({left = 0, bottom = 0, width = w, height = sceneHeight * 0.16})
            speech:SetStyle({left = w * 0.52, top = 4, width = w * 0.45, height = sceneHeight * 0.28})
            local logoHeight = upper * 0.44
            local logoWidth = math.min(w - margin * 2, logoHeight * 376 / 128)
            logo:SetStyle({left = (w - logoWidth) / 2, top = math.max(upper * 0.24, 68 * unit),
                width = logoWidth, height = logoWidth * 128 / 376})
            slogan:SetStyle({left = margin, top = upper * 0.85, width = w - margin * 2})
            slogan:SetFontSize(Art.FontSize(14))
            actions:SetStyle({left = margin, top = h - lower + 12 * unit, width = w - margin * 2, gap = 8 * unit})
            start:SetStyle({minHeight = math.max(60 * unit, Art.TouchSize(48)), paddingVertical = 10 * unit})
            footer:SetStyle({left = margin, bottom = 14 * unit, width = w - margin * 2})
        else
            local leftWidth = math.min(760, w * 0.44)
            paper:SetStyle({left = 0, top = 0, width = leftWidth + margin, height = h})
            bottomPaper:SetVisible(false)
            scene:SetStyle({left = leftWidth, top = 0, width = w - leftWidth, height = h})
            local sceneWidth = w - leftWidth
            hero:SetStyle({left = sceneWidth * 0.05, bottom = -h * 0.06,
                width = sceneWidth * 0.42, height = h * 0.86})
            leader:SetStyle({left = sceneWidth * 0.48, bottom = h * 0.09,
                width = sceneWidth * 0.47, height = h * 0.58})
            tableArt:SetStyle({left = 0, bottom = 0, width = sceneWidth, height = h * 0.19})
            speech:SetStyle({left = sceneWidth * 0.43, top = h * 0.10,
                width = sceneWidth * 0.42, height = h * 0.23})
            local introWidth = leftWidth - margin * 1.3
            logo:SetStyle({left = margin, top = h * (compact and 0.08 or 0.13), width = introWidth, height = introWidth * 128 / 376})
            slogan:SetStyle({left = margin, top = h * (compact and 0.38 or 0.39), width = introWidth})
            slogan:SetFontSize(Art.FontSize(compact and 14 or 21))
            actions:SetStyle({left = margin, top = h * (compact and 0.46 or 0.53), width = introWidth, gap = (compact and 4 or 12) * unit})
            start:SetStyle({minHeight = math.max((compact and 48 or 70) * unit, Art.TouchSize(48)),
                paddingVertical = (compact and 8 or 16) * unit})
            footer:SetStyle({left = margin, bottom = compact and 6 or 20, width = introWidth})
        end
        bottomPaper:SetVisible(portrait)
        speech:SetVisible(h >= 620)
        speech.children[1]:SetStyle({fontSize = Art.FontSize(portrait and 10 or 14),
            top = "12%", height = "64%", lineHeight = 1.2})
        start.children[1]:SetStyle({fontSize = Art.FontSize(compact and 19 or 24)})
        print(string.format("[MainMenuV2] %s %.0fx%.0f，背景/人物/前景独立", portrait and "竖屏" or "横屏", w, h))
    end)
end

return MainMenu
