-- 图纸感视觉小说主题：资源清单、纸片组件与安全区响应式布局。
-- 路径为资源根相对路径；保留完整字面量，供构建器扫描引用。
local UI = require("urhox-libs/UI")
local GameData = require("Data.GameData")
local Art = {}
Art.C = {
    paper = {244, 239, 229, 255}, white = {255, 252, 245, 255},
    ink = {42, 34, 47, 255}, muted = {126, 113, 115, 255},
    yellow = {231, 180, 79, 255}, purple = {105, 76, 122, 255},
    lilac = {235, 224, 236, 255}, dark = {38, 29, 44, 255},
    line = {213, 199, 181, 255}, red = {165, 77, 76, 255},
    green = {69, 112, 86, 255}, blue = {71, 111, 143, 255},
    clear = {0, 0, 0, 0},
}
local C = Art.C
Art.Assets = {
    characters = {
        intern = {normal = "image/Art/Characters/intern_normal.png", portrait = "image/Art/Characters/intern_portrait.png", legacy = "image/v2_char_intern_normal_20261014125618.png"},
        worker = {normal = "image/Art/Characters/worker_normal.png", portrait = "image/Art/Characters/worker_portrait.png"},
        designer = {normal = "image/Art/Characters/designer_normal.png", portrait = "image/Art/Characters/designer_portrait.png"},
        dev = {normal = "image/Art/Characters/dev_normal.png", portrait = "image/Art/Characters/dev_portrait.png"},
        sales = {normal = "image/Art/Characters/sales_normal.png", portrait = "image/Art/Characters/sales_portrait.png"},
        hr = {normal = "image/Art/Characters/hr_normal.png", portrait = "image/Art/Characters/hr_portrait.png"},
        pm = {normal = "image/Art/Characters/pm_normal.png", portrait = "image/Art/Characters/pm_portrait.png"},
        veteran = {normal = "image/Art/Characters/veteran_normal.png", portrait = "image/Art/Characters/veteran_portrait.png"},
        boss = {normal = "image/Art/Characters/boss_normal.png", portrait = "image/Art/Characters/boss_portrait.png"},
    },
    npc = {
        leader = {normal = "image/Art/NPC/leader_normal.png", legacy = "image/v2_npc_leader_normal_20261014125559.png"},
        colleague = {normal = "image/Art/NPC/colleague_normal.png"},
        client = {normal = "image/Art/NPC/client_normal.png"},
        pu_rui_si = {normal = "image/Art/Hidden/pu_rui_si_normal.png", final = "image/Art/Hidden/pu_rui_si_final.png", legacy = "image/Art/Hidden/pu_rui_si_body.png"},
    },
    bossExpressions = {
        smile = "image/Art/Hidden/pu_rui_si_smile.png",
        skeptical = "image/Art/Hidden/pu_rui_si_skeptical.png",
        drunk = "image/Art/Hidden/pu_rui_si_drunk.png",
    },
    backgrounds = {
        bbq = "image/Art/Backgrounds/bg_bbq.png",
        flyshop = "image/Art/Backgrounds/bg_flyshop.png",
        hotpot = "image/Art/Backgrounds/bg_hotpot.png",
        dapaidang = "image/Art/Backgrounds/bg_dapaidang.png",
        biz_chinese = "image/Art/Backgrounds/bg_biz_chinese.png",
        izakaya = "image/Art/Backgrounds/bg_izakaya.png",
        steak = "image/Art/Backgrounds/bg_steak.png",
        craftbeer = "image/Art/Backgrounds/bg_craftbeer.png",
        private = "image/Art/Backgrounds/bg_private.png",
        michelin = "image/Art/Backgrounds/bg_michelin.png",
        omakase = "image/Art/Backgrounds/bg_omakase.png",
        fivestar = "image/Art/Backgrounds/bg_fivestar.png",
        yacht = "image/Art/Backgrounds/bg_yacht.png",
    },
    drinks = {
        beer = "image/Art/Drinks/icon_drink_beer.png",
        wine = "image/Art/Drinks/icon_drink_wine.png",
        baijiu = "image/Art/Drinks/icon_drink_baijiu.png",
        cocktail = "image/Art/Drinks/icon_drink_cocktail.png",
        foreign = "image/Art/Drinks/icon_drink_foreign.png",
        sake = "image/Art/Drinks/icon_drink_sake.png",
        tea = "image/Art/Drinks/icon_drink_tea.png",
    },
    icons = {
        favor = "image/Art/UI/ui_icon_favor.png", dignity = "image/Art/UI/ui_icon_dignity.png",
        sober = "image/Art/UI/ui_icon_sober.png", vibe = "image/Art/UI/ui_icon_vibe.png",
        face = "image/Art/UI/ui_icon_face.png",
    },
    badges = {
        "image/Art/UI/ui_badge_lv1.png", "image/Art/UI/ui_badge_lv2.png",
        "image/Art/UI/ui_badge_lv3.png", "image/Art/UI/ui_badge_lv4.png",
        "image/Art/UI/ui_badge_lv5.png", "image/Art/UI/ui_badge_lv6.png",
        "image/Art/UI/ui_badge_lv7.png", "image/Art/UI/ui_badge_lv8.png",
    },
    primary = "image/Art/UI/AfterHours/gold_button.png",
    primaryPressed = "image/Art/UI/AfterHours/gold_button.png",
    secondary = "image/Art/UI/AfterHours/paper_panel.png",
    secondaryPressed = "image/Art/UI/AfterHours/paper_panel.png",
    card = "image/Art/UI/AfterHours/paper_panel.png",
    dark = "image/Art/UI/AfterHours/felt_panel.png",
    bubble = "image/Art/UI/AfterHours/paper_panel.png",
    diceCup = "image/Art/UI/AfterHours/dice_cup.png",
}
local A = Art.Assets
local legacyBG = {
    bbq = "image/v2_bg_t1_bbq_20261014125730.png",
    biz_chinese = "image/Art/Backgrounds/bg_biz_chinese.png",
    yacht = "image/Art/Backgrounds/bg_yacht.png",
}

-- 不缓存缺失结果：开发者稍后入库 PNG 时，重进页面即可使用。
function Art.Pick(...)
    for i = 1, select("#", ...) do
        local path = select(i, ...)
        if type(path) == "string" and path ~= "" and cache:Exists(path) then return path end
    end
    return nil
end

function Art.Merge(base, extra)
    local result = {}
    for k, v in pairs(base) do result[k] = v end
    for k, v in pairs(extra or {}) do result[k] = v end
    return result
end

function Art.Text(text, size, color, extra)
    return UI.Label(Art.Merge({text = tostring(text or ""), fontSize = size or 14,
        fontFamily = "sans", fontWeight = "normal",
        fontColor = color or C.ink, whiteSpace = "normal", wordBreak = "break-word",
        lineHeight = 1.5, flexShrink = 0, minWidth = 0}, extra))
end

function Art.Title(text, size, color, extra)
    return Art.Text(text, size or 26, color, Art.Merge({fontFamily = "menu", fontWeight = "bold",
        lineHeight = 1.35}, extra))
end

function Art.Picture(path, extra)
    return UI.Panel(Art.Merge({backgroundImage = path, backgroundFit = "contain",
        pointerEvents = "none", flexShrink = 0}, extra))
end

function Art.Character(item, portrait)
    item = item or {}
    local entry = A.characters[item.id] or {}
    if portrait then return Art.Pick(item.portrait, item.thumbnail, entry.portrait, entry.normal, entry.legacy) end
    return Art.Pick(item.illustration, entry.normal, entry.legacy, item.portrait, entry.portrait)
end

function Art.Background(item)
    item = item or {}
    return Art.Pick(item.background, A.backgrounds[item.id], legacyBG[item.id], A.backgrounds.bbq, legacyBG.bbq)
end

function Art.Opponent(state)
    local opponent = state.opponent or {}
    local hidden = opponent.id == "pu_rui_si"
    local id = hidden and "pu_rui_si" or opponent.id or "leader"
    local entry = A.npc[id] or A.npc.leader
    local path = Art.Pick(opponent.illustration, entry.normal, entry.legacy, opponent.portrait)
    return opponent.name or (hidden and "普老板·普瑞斯" or "直属领导"), path
end

function Art.Paper(children, extra, dark)
    return UI.Panel(Art.Merge({backgroundImage = Art.Pick(dark and A.dark or A.card),
        backgroundFit = "sliced", backgroundSlice = {24, 24, 24, 24},
        backgroundColor = C.clear, borderWidth = 0, borderRadius = 12,
        padding = 18, gap = 12, children = children,
        boxShadow = {{x = 0, y = 5, blur = 18, color = {42, 34, 47, 24}}}}, extra))
end

-- 长选项可换行；禁用状态在封装与业务回调两端都应检查。
function Art.Button(text, onClick, secondary, extra)
    local props = extra or {}
    local normal = not props.flat and (secondary and A.secondary or A.primary) or nil
    local label = Art.Text(text, props.fontSize or 13, C.ink,
        {textAlign = props.textAlign or "center", fontFamily = "sans", fontWeight = "bold",
            pointerEvents = "none", width = "100%", lineHeight = 1.3})
    local function restore(_, widget)
        widget:SetStyle({imageTint = {255, 255, 255, 255}, translateY = 0})
    end
    return UI.Panel(Art.Merge({minHeight = 46, flexShrink = 0, paddingHorizontal = 16, paddingVertical = 11,
        backgroundImage = Art.Pick(normal), backgroundFit = "sliced",
        backgroundSlice = secondary and {24, 24, 24, 24} or {20, 30, 20, 30},
        backgroundColor = props.flat and C.white or C.clear, borderWidth = props.flat and 1 or 0,
        borderColor = C.line, borderRadius = 10,
        justifyContent = "center", alignItems = "center", pointerEvents = "box-only",
        transition = "translateY 0.10s easeOut", children = {label},
        onPointerEnter = function(_, widget)
            if not widget.props.disabled then widget:SetStyle({imageTint = {255, 248, 225, 255}}) end
        end,
        onPointerDown = function(event, widget)
            if event:IsPrimaryButton() and not widget.props.disabled then
                widget:SetStyle({imageTint = {224, 213, 195, 255}, translateY = 1})
            end
        end,
        onPointerUp = restore, onPointerCancel = restore, onPointerLeave = restore,
        onClick = function(widget)
            if not widget.props.disabled and onClick then onClick(widget) end
        end}, extra))
end

function Art.SetDisabled(button, disabled)
    button.props.disabled = disabled
    button:SetStyle({opacity = disabled and 0.38 or 1})
end

function Art.Badge(level, size)
    local lv = math.max(1, math.min(8, level or 1))
    return UI.Panel {width = size or 54, height = size or 54, flexShrink = 0,
        backgroundImage = Art.Pick(A.badges[lv]), backgroundFit = "contain", pointerEvents = "none",
        children = {Art.Text("L" .. lv, 11, C.ink, {position = "absolute", bottom = 0, right = 0,
            backgroundColor = C.yellow, width = 26, minWidth = 26, paddingHorizontal = 0,
            textAlign = "center", borderWidth = 1, borderColor = C.ink})}}
end

function Art.StatRow(label, value, color)
    return UI.Panel {width = "100%", flexDirection = "row", gap = 12,
        justifyContent = "space-between", children = {
            Art.Text(label, 13, C.muted, {flexGrow = 1, flexBasis = 0, flexShrink = 1}),
            Art.Text(value, 13, color, {flexGrow = 1, flexBasis = 0, flexShrink = 1, textAlign = "right"})}}
end

local statNames = {favor = "好感", dignity = "尊严", sober = "清醒", vibe = "氛围", face = "面子"}
local statColors = {favor = C.yellow, dignity = C.purple, sober = C.blue, vibe = C.purple, face = C.yellow}
function Art.Stat(key, value, compact)
    local n = tonumber(value) or 0
    if compact then
        return UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, minWidth = 0, gap = 3, children = {
            Art.Text(statNames[key] or key, 9, C.muted, {width = "100%", textAlign = "center", whiteSpace = "nowrap"}),
            Art.Title(tostring(n), 12, C.ink, {width = "100%", textAlign = "center"}),
            UI.ProgressBar {value = math.max(0, math.min(1, n / 100)), height = 3, width = "100%",
                fillColor = statColors[key], backgroundColor = C.line, borderRadius = 3},
        }}
    end
    local icon = Art.Picture(A.icons[key], {width = 30, height = 30})
    return UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, minWidth = 0, gap = 4,
        children = {
            UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 4, children = {
                icon, Art.Text((statNames[key] or key) .. " " .. n, compact and 11 or 13, C.ink,
                    {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0})}},
            UI.ProgressBar {value = math.max(0, math.min(1, n / 100)), height = compact and 3 or 5,
                width = "100%", fillColor = statColors[key], backgroundColor = C.line, borderRadius = 3},
        }}
end

function Art.Stats(state, compact)
    local children = {}
    for _, key in ipairs({"favor", "dignity", "sober", "vibe", "face"}) do
        children[#children + 1] = Art.Stat(key, state[key], compact)
    end
    return UI.Panel {width = "100%", flexDirection = "row", gap = compact and 6 or 12,
        padding = compact and 8 or 12, backgroundColor = C.paper,
        borderBottomWidth = 1, borderBottomColor = C.line, children = children}
end

function Art.HUD(state, levelName)
    local mode = GameData and GameData.GetMode and GameData.GetMode(state.mode) or nil
    local modeLabel = mode and (mode.icon .. " " .. mode.name) or "💼 上班咯"
    local children = {
        Art.Text(modeLabel, 10, C.yellow, {width = 86, whiteSpace = "nowrap"}),
        Art.Text("DAY " .. state.currentDay .. " / " .. state.maxDays, 11, C.yellow, {width = 78}),
        UI.Panel {width = 165, flexDirection = "row", gap = 4, alignItems = "center", children = {
            Art.Badge(state.currentLevel, 24), Art.Text("Lv." .. state.currentLevel .. " " .. levelName, 10, C.white,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, whiteSpace = "nowrap"})}},
        Art.Text("¥" .. state.money, 11, C.yellow, {width = 83, textAlign = "right"}),
    }
    return UI.Panel {width = "100%", minHeight = 40, paddingHorizontal = 12, paddingVertical = 5,
        flexDirection = "row", flexWrap = "wrap", alignItems = "center", justifyContent = "space-between",
        columnGap = 8, rowGap = 4, backgroundColor = C.dark, children = children}
end

function Art.Safe(children, extra)
    return UI.SafeAreaView(Art.Merge({width = "100%", height = "100%", nativeMenuInset = true,
        children = children, pointerEvents = "box-none"}, extra))
end

function Art.Root(children, background)
    return UI.Panel {width = "100%", height = "100%", overflow = "hidden", backgroundColor = C.paper,
        backgroundImage = background, backgroundFit = "cover", children = children}
end

-- UI.Init 位于受保护的 main.lua，沿用它的 UI.Scale.DEFAULT，不重新初始化。
-- 只更新布局，不重建页面；调整窗口不会重复 RollDice/GetNextEvent/ApplyBanquetResult。
function Art.Responsive(root, apply)
    ---@type number
    local lastW = -1
    ---@type number
    local lastH = -1
    local oldUpdate = root.Update
    root.Update = function(self, dt)
        if oldUpdate then oldUpdate(self, dt) end
        local insets = UI.GetSafeAreaInsets()
        local w = UI.GetWidth() - insets.left - insets.right
        local h = UI.GetHeight() - insets.top - insets.bottom
        if w ~= lastW or h ~= lastH then
            lastW, lastH = w, h
            apply(w, h, w < 760, h < 560)
        end
    end
    root:Update(0)
    return root
end

return Art
