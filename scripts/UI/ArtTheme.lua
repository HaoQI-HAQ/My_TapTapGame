-- 黄橙手绘与深蓝酒桌主题；运行素材与制作参考分目录保存。
-- 路径为资源根相对路径；保留完整字面量，供构建器扫描引用。
local UI = require("urhox-libs/UI")
local ImageCache = require("urhox-libs/UI/Core/ImageCache")
local GameData = require("Data.GameData")
local Art = {}
Art.C = {
    paper = {246, 235, 207, 255}, white = {255, 248, 225, 255},
    ink = {24, 33, 47, 255}, muted = {108, 105, 91, 255},
    yellow = {255, 197, 35, 255}, orange = {255, 143, 26, 255},
    purple = {155, 99, 22, 255}, lilac = {238, 218, 175, 255},
    dark = {22, 31, 44, 255}, line = {193, 167, 121, 255},
    red = {183, 57, 40, 255}, green = {51, 122, 83, 255},
    blue = {66, 124, 165, 255}, clear = {0, 0, 0, 0},
}
local C = Art.C
Art.Assets = {
    characters = {
        intern = {normal = "image/Art/UI/JiuzhuoV2/Characters/intern_normal_full.png", half = "image/Art/UI/JiuzhuoV2/Characters/intern_normal_half.png", portrait = "image/Art/UI/JiuzhuoV2/Characters/intern_normal_portrait.png", legacy = "image/v2_char_intern_normal_20261014125618.png"},
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
        leader = {normal = "image/Art/UI/JiuzhuoV2/Characters/leader_normal.png", portrait = "image/Art/UI/JiuzhuoV2/Characters/leader_normal_portrait.png", legacy = "image/v2_npc_leader_normal_20261014125559.png"},
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
        bbq = "image/Art/UI/JiuzhuoV2/Scene/bg_bbq_landscape.png",
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
        favor = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_favor.png", dignity = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_dignity.png",
        sober = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_sober.png", vibe = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_vibe.png",
        face = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_face.png",
        day = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_day.png", rank = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_rank.png",
        money = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_money.png", round = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_round.png",
        pause = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_pause.png", sound = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_sound.png",
        check = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_check.png", info = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_info.png",
        badge = "image/Art/UI/JiuzhuoV2/Icons/ui_icon_badge.png",
    },
    badges = {
        "image/Art/UI/ui_badge_lv1.png", "image/Art/UI/ui_badge_lv2.png",
        "image/Art/UI/ui_badge_lv3.png", "image/Art/UI/ui_badge_lv4.png",
        "image/Art/UI/ui_badge_lv5.png", "image/Art/UI/ui_badge_lv6.png",
        "image/Art/UI/ui_badge_lv7.png", "image/Art/UI/ui_badge_lv8.png",
    },
    primary = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_primary_normal.png",
    primaryPressed = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_primary_pressed.png",
    primaryFocus = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_primary_focus.png",
    secondary = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_secondary_normal.png",
    secondaryPressed = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_secondary_pressed.png",
    option = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_option_normal.png",
    optionSelected = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_option_selected.png",
    disabled = "image/Art/UI/JiuzhuoV2/Buttons/ui_btn_disabled.png",
    card = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_settlement.png",
    dark = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_dialogue.png",
    bubble = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_dialogue.png",
    brushGold = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_brush_gold.png",
    brushInk = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_brush_ink.png",
    speech = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_speech.png",
    logo = "image/Art/UI/JiuzhuoV2/Panels/ui_logo_jiuzhuo.png",
    statusPill = "image/Art/UI/JiuzhuoV2/Panels/ui_panel_status_pill.png",
    foreground = "image/Art/UI/JiuzhuoV2/Scene/fg_table_empty.png",
    portraitBackground = "image/Art/UI/JiuzhuoV2/Scene/bg_bbq_portrait.png",
    layoffBox = "image/Art/UI/JiuzhuoV2/Scene/prop_layoff_box.png",
    internEmbarrassedPortrait = "image/Art/UI/JiuzhuoV2/Characters/intern_embarrassed_portrait.png",
    leaderSatisfiedPortrait = "image/Art/UI/JiuzhuoV2/Characters/leader_satisfied_portrait.png",
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

-- 基准像素与手机 dp 分开换算，补偿 DEFAULT 的小屏密度缩放。
function Art.Unit()
    local w, h = UI.GetWidth(), UI.GetHeight()
    local density = UI.GetScale() / math.max(1, graphics:GetDPR())
    local design = h > w and w / 360 or math.min(w / 800, h / 450)
    return math.max(1 / math.max(0.1, density), math.min(h > w and 3 or 1.8, design))
end

function Art.TouchSize(size)
    local density = UI.GetScale() / math.max(1, graphics:GetDPR())
    return (size or 48) / math.max(0.1, density)
end

function Art.FontSize(size)
    return size * Art.Unit()
end

function Art.Text(text, size, color, extra)
    return UI.Label(Art.Merge({text = tostring(text or ""), fontSize = Art.FontSize(size or 14), artFontSize = size or 14,
        fontFamily = "sans", fontWeight = "normal",
        fontColor = color or C.ink, whiteSpace = "normal", wordBreak = "break-word",
        lineHeight = 1.5, flexShrink = 0, minWidth = 0}, extra))
end

function Art.Title(text, size, color, extra)
    return Art.Text(text, size or 26, color, Art.Merge({fontFamily = "menu", fontWeight = "bold",
        lineHeight = 1.35}, extra))
end

function Art.Picture(path, extra)
    local picture = UI.Panel(Art.Merge({backgroundImage = path, backgroundFit = "contain",
        pointerEvents = "none", flexShrink = 0}, extra))
    -- 限定 contain 的图像绘制区域，透明留白外不重复采样边缘像素。
    -- 仍调用 UI 组件渲染接口，不创建独立 NanoVG 帧或绕过组件层级。
    local renderTarget = picture --[[@as table]]
    ---@param self Panel
    ---@param vg NVGContextWrapper
    renderTarget.Render = function(self, vg)
        local props = self.props
        local imagePath = props.backgroundImage
        if not imagePath or props.backgroundFit ~= "contain" then
            UI.Panel.Render(self, vg)
            return
        end
        -- 使用 UI 已加载的 GPU 纹理尺寸，兼容 PNG 的平台压缩变体与 DWP 热替换。
        -- 不用 Image 解码：BC/ASTC 等 KTX 是纹理格式，部分平台不能作为 CPU Image 读取。
        if ImageCache.Get(imagePath) <= 0 then return end
        local imageWidth, imageHeight = ImageCache.GetSize(imagePath)
        if imageWidth <= 0 or imageHeight <= 0 then return end
        local rect = self:GetAbsoluteLayout()
        if rect.w <= 0 or rect.h <= 0 then return end
        local ratio = math.min(rect.w / imageWidth, rect.h / imageHeight)
        local width, height = imageWidth * ratio, imageHeight * ratio
        local tint = props.imageTint --[[@as RGBAColor?]]
        self:RenderBackgroundImage(vg, imagePath,
            {x = rect.x + (rect.w - width) / 2, y = rect.y + (rect.h - height) / 2,
                w = width, h = height}, "fill", nil, 0, tint, props.backgroundImageOpacity)
    end
    return picture
end

function Art.Character(item, portrait)
    item = item or {}
    local entry = A.characters[item.id] or {}
    -- 只升级此次确认的实习生；其余身份及隐藏人物仍沿用原数据资源。
    if item.id == "intern" then
        return Art.Pick(portrait and entry.portrait or entry.normal, item.illustration, entry.legacy)
    end
    if portrait then return Art.Pick(item.portrait, item.thumbnail, entry.portrait, entry.normal, entry.legacy) end
    return Art.Pick(item.illustration, entry.normal, entry.legacy, item.portrait, entry.portrait)
end

function Art.Background(item, portrait)
    item = item or {}
    if item.id == "bbq" then
        return Art.Pick(portrait and A.portraitBackground or A.backgrounds.bbq, item.background, legacyBG.bbq)
    end
    return Art.Pick(item.background, A.backgrounds[item.id], legacyBG[item.id], A.backgrounds.bbq, legacyBG.bbq)
end

function Art.Opponent(state)
    local opponent = state.opponent or {}
    local hidden = opponent.id == "pu_rui_si"
    local id = hidden and "pu_rui_si" or opponent.id or "leader"
    local entry = A.npc[id] or A.npc.leader
    local path = id == "leader" and Art.Pick(entry.normal, opponent.illustration, entry.legacy, opponent.portrait)
        or Art.Pick(opponent.illustration, entry.normal, entry.legacy, opponent.portrait)
    return opponent.name or (hidden and "普老板·普瑞斯" or "直属领导"), path
end

-- 运行纹理已裁 Alpha 边并等比缩小；切线使用运行纹理像素，顺序 TRBL。
-- 原 1024px 图的源切线不能直接塞入 UI 的 48px 控件，否则中心区为负。
function Art.Paper(children, extra, dark)
    return UI.Panel(Art.Merge({backgroundImage = Art.Pick(dark and A.dark or A.card),
        backgroundFit = "sliced", backgroundSlice = dark and {15, 19, 15, 19} or {14, 25, 14, 25},
        backgroundColor = C.clear, borderWidth = 0, borderRadius = 0,
        padding = 26, gap = 12, children = children}, extra))
end

local function ButtonImage(button, pressed, focus)
    local props = button.props
    if props.flat then return end
    local path = props.disabled and A.disabled or
        (props.selected and props.option and A.optionSelected) or
        (props.option and A.option) or
        (props.secondaryArt and (pressed and A.secondaryPressed or A.secondary)) or
        (pressed and A.primaryPressed or (focus and A.primaryFocus or A.primary))
    button:SetStyle({backgroundImage = Art.Pick(path), translateY = pressed and 1 or 0,
        imageTint = {255, 255, 255, 255}})
end

-- 可换行底板＋独立正文；字母、勾和动态文本不烘焙进九宫格。
function Art.Button(text, onClick, secondary, extra)
    local props = extra or {}
    local normal = props.option and A.option or (secondary and A.secondary or A.primary)
    local lightText = (secondary or props.option) and not props.flat
    local label = Art.Text(text, props.fontSize or 13, props.fontColor or (lightText and C.white or C.ink),
        {textAlign = props.textAlign or "center", fontWeight = "bold",
            pointerEvents = "none", width = "100%", lineHeight = 1.3})
    local function restore(_, widget) ButtonImage(widget, false, false) end
    local button = UI.Panel(Art.Merge({minHeight = 48, flexShrink = 0, paddingHorizontal = 20, paddingVertical = 12,
        backgroundImage = not props.flat and Art.Pick(normal) or nil, backgroundFit = "sliced",
        backgroundSlice = {12, 17, 16, 17},
        backgroundColor = props.flat and C.white or C.clear, borderWidth = props.flat and 1 or 0,
        borderColor = C.line, borderRadius = props.flat and 6 or 0,
        justifyContent = "center", alignItems = "center", pointerEvents = "box-only",
        transition = "translateY 0.10s easeOut", children = {label}, secondaryArt = secondary == true,
        onPointerEnter = function(_, widget)
            if not widget.props.disabled then ButtonImage(widget, false, true) end
        end,
        onPointerDown = function(event, widget)
            if event:IsPrimaryButton() and not widget.props.disabled then ButtonImage(widget, true, false) end
        end,
        onPointerUp = restore, onPointerCancel = restore, onPointerLeave = restore,
        onClick = function(widget)
            if not widget.props.disabled and onClick then onClick(widget) end
        end}, extra))
    button:SetStyle({minHeight = math.max(props.minHeight or 48, 48 * Art.Unit(), Art.TouchSize(48)),
        paddingHorizontal = (props.paddingHorizontal or 20) * Art.Unit(),
        paddingVertical = (props.paddingVertical or 12) * Art.Unit()})
    return button
end

function Art.SetDisabled(button, disabled)
    button.props.disabled = disabled
    ButtonImage(button, false, false)
    button:SetStyle({opacity = disabled and 0.62 or 1})
end

function Art.SetSelected(button, selected)
    button.props.selected = selected
    ButtonImage(button, false, false)
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
    ---@type table<string, Label>
    local labels = {}
    local names = {}
    local unit = Art.Unit()
    for _, key in ipairs({"favor", "dignity", "sober", "vibe", "face"}) do
        local name = key == "dignity" and state.mode == "offwork" and "骨气" or statNames[key]
        names[key] = name
        local label = Art.Text(name .. " " .. tostring(state[key] or 0), compact and 10 or 12, C.white,
            {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, lineHeight = 1.25})
        labels[key] = label
        children[#children + 1] = UI.Panel {id = "banquet_stat_" .. key,
            flexGrow = 1, flexShrink = 1, flexBasis = 0, minWidth = 0,
            flexDirection = "row", alignItems = "center", gap = 4 * unit, children = {
                Art.Picture(A.icons[key], {width = (compact and 18 or 24) * unit, height = (compact and 18 or 24) * unit}),
                label,
            }}
    end
    -- 显式两组行容器，避免 wrap 在父级计算单行高度后把末两项裁掉。
    local first = UI.Panel {flexDirection = "row", gap = 6 * unit,
        children = {children[1], children[2], children[3]}}
    local second = UI.Panel {flexDirection = "row", gap = 6 * unit,
        children = {children[4], children[5]}}
    local root = UI.Panel {id = "banquet_stats", width = "100%", flexShrink = 0,
        gap = 6 * unit, padding = (compact and 10 or 14) * unit, backgroundColor = C.dark,
        borderBottomWidth = 2, borderBottomColor = C.orange, children = {first, second}}
    local update = root.Update
    root.Update = function(self, dt)
        if update then update(self, dt) end
        -- 猜骰结算会原地修改 State；每帧只在文本变化时同步，不触发玩法调用。
        for key, label in pairs(labels) do
            local text = names[key] .. " " .. tostring(state[key] or 0)
            if label:GetText() ~= text then label:SetText(text) end
        end
    end
    return Art.Responsive(root, function(w)
        local stacked = w / Art.Unit() < 600
        root:SetStyle({flexDirection = stacked and "column" or "row"})
        first:SetStyle({width = stacked and "100%" or "auto", flexGrow = stacked and 0 or 3,
            flexBasis = stacked and "auto" or 0, flexShrink = 0})
        second:SetStyle({width = stacked and "100%" or "auto", flexGrow = stacked and 0 or 2,
            flexBasis = stacked and "auto" or 0, flexShrink = 0})
    end)
end

function Art.HUD(state, levelName)
    local mode = GameData.GetMode(state.mode)
    local unit = Art.Unit()
    local function item(icon, text, color)
        return UI.Panel {flexDirection = "row", alignItems = "center", gap = 6 * unit, minWidth = 90 * unit,
            flexShrink = 1, children = {
                Art.Picture(A.icons[icon], {width = 20 * unit, height = 20 * unit}),
                Art.Text(text, 12, color or C.white, {whiteSpace = "nowrap", fontWeight = "bold"}),
            }}
    end
    return UI.Panel {id = "banquet_hud", width = "100%", minHeight = 48, paddingHorizontal = 16, paddingVertical = 8,
        flexDirection = "row", flexWrap = "wrap", alignItems = "center", justifyContent = "space-between",
        columnGap = 12, rowGap = 8, backgroundColor = C.dark, children = {
            item("day", "第 " .. state.currentDay .. " 天 / " .. state.maxDays .. " 天"),
            item("rank", "Lv." .. state.currentLevel .. " " .. levelName),
            item("money", "¥ " .. state.money, C.yellow),
            item("round", "第 " .. state.round .. " / " .. state.maxRounds .. " 回合"),
            Art.Text(mode.name, 11, C.yellow, {whiteSpace = "nowrap", fontWeight = "bold"}),
        }}
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
        local layout = self:GetLayout()
        -- 挂在导航条下面时按本页实际高度排版，不把整屏高度误当内容高度。
        local w = (layout.w > 0 and layout.w or UI.GetWidth()) - insets.left - insets.right
        local h = (layout.h > 0 and layout.h or UI.GetHeight()) - insets.top - insets.bottom
        if w ~= lastW or h ~= lastH then
            lastW, lastH = w, h
            local function scaleText(widget)
                if widget.props.artFontSize then widget:SetStyle({fontSize = Art.FontSize(widget.props.artFontSize)}) end
                for _, child in ipairs(widget:GetChildren()) do scaleText(child) end
            end
            scaleText(self)
            apply(w, h, w < 760, h < 560)
        end
    end
    root:Update(0)
    return root
end

return Art
