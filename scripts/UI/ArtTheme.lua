-- 图纸感视觉小说主题：资源清单、纸片组件与安全区响应式布局。
-- 路径为资源根相对路径；保留完整字面量，供构建器扫描引用。
local UI = require("urhox-libs/UI")
local Art = {}
Art.C = {
    paper = {246, 239, 220, 255}, white = {255, 250, 237, 255},
    ink = {30, 28, 34, 255}, muted = {106, 96, 99, 255},
    yellow = {248, 190, 65, 255}, purple = {108, 75, 146, 255},
    lilac = {226, 213, 236, 255}, dark = {35, 30, 43, 246},
    line = {64, 53, 60, 255}, red = {172, 57, 58, 255},
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
        pu_rui_si = {normal = "image/Art/NPC/pu_rui_si_normal.png", final = "image/Art/NPC/pu_rui_si_final.png", legacy = "image/Art/Characters/pu_rui_si_body.png"},
    },
    bossExpressions = {
        smile = "image/Art/Characters/pu_rui_si_smile.png",
        skeptical = "image/Art/Characters/pu_rui_si_skeptical.png",
        drunk = "image/Art/Characters/pu_rui_si_drunk.png",
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
    primary = "image/Art/UI/ui_btn_primary_normal.png",
    primaryPressed = "image/Art/UI/ui_btn_primary_pressed.png",
    secondary = "image/Art/UI/ui_btn_secondary_normal.png",
    secondaryPressed = "image/Art/UI/ui_btn_secondary_pressed.png",
    card = "image/Art/UI/ui_panel_card.png",
    dark = "image/Art/UI/ui_panel_dark.png",
    bubble = "image/Art/UI/ui_bubble_dialog.png",
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
        fontColor = color or C.ink, whiteSpace = "normal", wordBreak = "break-word",
        lineHeight = 1.35, flexShrink = 0, minWidth = 0}, extra))
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
        backgroundFit = "sliced", backgroundSlice = {20, 20, 20, 20},
        backgroundColor = dark and C.dark or C.paper, borderWidth = 2, borderColor = C.ink,
        borderRadius = 3, padding = 16, gap = 10, children = children,
        boxShadow = {{x = 4, y = 5, blur = 0, color = {30, 28, 34, 90}}}}, extra))
end

-- Panel 按钮允许长选项自然换行，避免 Button 内部单行文字裁切。
function Art.Button(text, onClick, secondary, extra)
    local normal = secondary and A.secondary or A.primary
    local pressed = secondary and A.secondaryPressed or A.primaryPressed
    local label = Art.Text(text, 15, secondary and C.paper or C.ink,
        {textAlign = "center", fontWeight = "bold", pointerEvents = "none", width = "100%"})
    local function restore(_, widget)
        widget:SetStyle({backgroundImage = Art.Pick(normal), translateY = 0})
    end
    local button = UI.Panel(Art.Merge({minHeight = 46, paddingHorizontal = 16, paddingVertical = 10,
        backgroundImage = Art.Pick(normal), backgroundFit = "sliced",
        backgroundSlice = {14, 20, 18, 20},
        backgroundColor = secondary and C.purple or C.yellow, borderWidth = 2, borderColor = C.ink,
        borderRadius = 3, justifyContent = "center", alignItems = "center", pointerEvents = "box-only",
        transition = "translateY 0.12s easeOut", children = {label},
        onPointerDown = function(event, widget)
            if event:IsPrimaryButton() then widget:SetStyle({backgroundImage = Art.Pick(pressed, normal), translateY = 2}) end
        end,
        onPointerUp = restore, onPointerCancel = restore, onPointerLeave = restore,
        onClick = function(widget)
            if not widget.props.disabled and onClick then onClick(widget) end
        end}, extra))
    return button
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
    local icon = Art.Picture(A.icons[key], {width = compact and 22 or 30, height = compact and 22 or 30})
    return UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, minWidth = 0, gap = 4,
        children = {
            UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 4, children = {
                icon, Art.Text((statNames[key] or key) .. " " .. n, compact and 11 or 13, C.ink,
                    {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0})}},
            UI.ProgressBar {value = math.max(0, math.min(1, n / 100)), height = compact and 4 or 6,
                width = "100%", fillColor = statColors[key], backgroundColor = {200, 189, 177, 255}, borderRadius = 0},
        }}
end

function Art.Stats(state, compact)
    local children = {}
    for _, key in ipairs({"favor", "dignity", "sober", "vibe", "face"}) do
        children[#children + 1] = Art.Stat(key, state[key], compact)
    end
    return UI.Panel {width = "100%", flexDirection = "row", gap = compact and 6 or 12,
        padding = compact and 8 or 12, backgroundColor = C.paper,
        borderBottomWidth = 2, borderBottomColor = C.ink, children = children}
end

function Art.HUD(state, levelName)
    local children = {
        Art.Text("DAY " .. state.currentDay .. " / " .. state.maxDays, 13, C.yellow, {minWidth = 104}),
        UI.Panel {minWidth = 174, flexDirection = "row", gap = 6, alignItems = "center", children = {
            Art.Badge(state.currentLevel, 28), Art.Text("Lv." .. state.currentLevel .. " " .. levelName, 13, C.paper,
                {minWidth = 140})}},
        Art.Text("余额 ¥" .. state.money, 13, C.yellow, {minWidth = 136}),
    }
    return UI.Panel {width = "100%", minHeight = 44, paddingHorizontal = 12, paddingVertical = 5,
        flexDirection = "row", flexWrap = "wrap", alignItems = "center", justifyContent = "space-between",
        gap = 8, backgroundColor = C.ink, borderBottomWidth = 3, borderBottomColor = C.yellow, children = children}
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
