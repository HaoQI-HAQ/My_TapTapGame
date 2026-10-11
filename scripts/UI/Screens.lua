-- ============================================================================
-- 《酒桌文化》v1.2.1 UI 界面模块
-- 天数进度 / 职级显示 / 每日结算 / 终局结算 / 休息日
-- ============================================================================

local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local GameData = require("Data.GameData")

local Screens = {}

-- 颜色常量
local C = {
    bgWarm = { 245, 166, 35, 255 },
    bgDark = { 25, 28, 35, 255 },
    panelDark = { 38, 42, 55, 245 },
    panelCard = { 48, 54, 70, 235 },
    panelHover = { 60, 66, 85, 240 },
    textWhite = { 255, 255, 255, 255 },
    textGray = { 170, 175, 185, 255 },
    textYellow = { 255, 210, 60, 255 },
    textGold = { 255, 180, 40, 255 },
    accent = { 255, 140, 50, 255 },
    green = { 76, 195, 100, 255 },
    red = { 244, 67, 54, 255 },
    blue = { 80, 170, 255, 255 },
    purple = { 180, 100, 255, 255 },
    dimBg = { 0, 0, 0, 160 },
}

-- 回调
local onScreenChange_ = nil

function Screens.SetOnScreenChange(callback)
    onScreenChange_ = callback
end

-- ============================================================================
-- 辅助函数
-- ============================================================================

--- 统计行
local function StatRow(label, value, color)
    return UI.Panel {
        width = "100%",
        flexDirection = "row",
        justifyContent = "space-between",
        children = {
            UI.Label { text = label, fontSize = 13, fontColor = C.textGray },
            UI.Label { text = tostring(value), fontSize = 13, fontColor = color or C.textWhite },
        },
    }
end

--- 属性进度条
local function AttrBar(name, value, color)
    return UI.Panel {
        width = "100%", gap = 3,
        children = {
            UI.Panel {
                width = "100%", flexDirection = "row", justifyContent = "space-between",
                children = {
                    UI.Label { text = name, fontSize = 11, fontColor = C.textGray },
                    UI.Label { text = tostring(value), fontSize = 11, fontColor = C.textWhite },
                },
            },
            UI.ProgressBar {
                value = math.max(0, math.min(1, value / 100)),
                width = "100%",
                height = 5,
                fillColor = color,
                backgroundColor = { 60, 60, 60, 255 },
                borderRadius = 3,
            },
        },
    }
end

--- 顶部 HUD 状态栏（天数+职级+资金）
local function CreateHUD()
    local s = GameLogic.State
    local levelData = GameLogic.GetLevelData(s.currentLevel)
    return UI.Panel {
        width = "100%", padding = 10, paddingLeft = 14, paddingRight = 14,
        backgroundColor = C.panelDark,
        flexDirection = "row",
        justifyContent = "space-between",
        alignItems = "center",
        children = {
            UI.Label {
                text = "Day " .. s.currentDay .. "/" .. s.maxDays,
                fontSize = 12, fontColor = C.textYellow,
            },
            UI.Label {
                text = levelData.icon .. " Lv." .. s.currentLevel .. " " .. levelData.name,
                fontSize = 12, fontColor = C.textWhite,
            },
            UI.Label {
                text = "¥" .. s.money,
                fontSize = 12, fontColor = C.textGold,
            },
        },
    }
end

-- ============================================================================
-- 主菜单
-- ============================================================================
function Screens.CreateMainMenu()
    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgWarm,
        justifyContent = "center",
        alignItems = "center",
        children = {
            UI.Panel {
                alignItems = "center", gap = 8, marginBottom = 40,
                children = {
                    UI.Label { text = "🍻", fontSize = 64 },
                    UI.Label {
                        text = "酒桌文化",
                        fontSize = 36, fontWeight = "bold",
                        fontColor = { 60, 30, 0, 255 },
                    },
                    UI.Label {
                        text = "职场应酬生存模拟器 · v1.2",
                        fontSize = 13,
                        fontColor = { 100, 60, 20, 180 },
                    },
                },
            },
            UI.Panel {
                width = 260, gap = 12, alignItems = "center",
                children = {
                    UI.Button {
                        text = "🎲  开始入职",
                        width = 220, height = 48,
                        variant = "primary",
                        fontSize = 17,
                        onClick = function()
                            GameLogic.StartNewGame()
                            if onScreenChange_ then onScreenChange_("select_workplace") end
                        end,
                    },
                    UI.Button {
                        text = "🎲  摇骰子演示",
                        width = 220, height = 48,
                        fontSize = 17,
                        onClick = function()
                            if onScreenChange_ then onScreenChange_("dice_demo") end
                        end,
                    },
                    UI.Label {
                        text = "5天内从实习生卷到老板",
                        fontSize = 11, fontColor = { 80, 40, 0, 160 },
                        marginTop = 8,
                    },
                },
            },
            UI.Label {
                text = "适度饮酒，拒绝酒驾",
                fontSize = 10, fontColor = { 100, 60, 20, 100 },
                marginTop = 50,
            },
        },
    }
end

-- ============================================================================
-- 通用选择列表
-- ============================================================================
local function CreateSelectionScreen(title, subtitle, items, onSelect, extraHeader)
    local cards = {}
    for i, item in ipairs(items) do
        -- 右侧信息文本
        local rightText = ""
        if item.costPerPerson then
            rightText = "¥" .. item.costPerPerson .. "/人"
        elseif item.price then
            rightText = "¥" .. item.price
        elseif item.startLevel then
            local ld = GameData.Levels[item.startLevel]
            rightText = "Lv." .. item.startLevel .. " " .. (ld and ld.name or "")
        elseif item.difficulty then
            rightText = string.rep("⭐", math.min(5, item.difficulty))
        end

        -- 副文本
        local subText = item.desc or item.skillDesc or item.special or ""
        if item.skill then
            subText = "【" .. item.skill .. "】" .. (item.skillDesc or "")
        end

        table.insert(cards, UI.Panel {
            width = "100%",
            padding = 12,
            backgroundColor = C.panelCard,
            borderRadius = 10,
            flexDirection = "row",
            alignItems = "center",
            gap = 10,
            pointerEvents = "auto",
            onClick = function()
                onSelect(item, i)
            end,
            children = {
                UI.Label {
                    text = item.icon or "📌",
                    fontSize = 26, width = 36, textAlign = "center",
                },
                UI.Panel {
                    flex = 1, gap = 2,
                    children = {
                        UI.Label {
                            text = item.name,
                            fontSize = 15, fontWeight = "bold",
                            fontColor = C.textWhite,
                        },
                        UI.Label {
                            text = subText,
                            fontSize = 11, fontColor = C.textGray,
                        },
                    },
                },
                UI.Label {
                    text = rightText,
                    fontSize = 12, fontColor = C.textYellow,
                },
            },
        })
    end

    local headerChildren = {
        UI.Label {
            text = title,
            fontSize = 18, fontWeight = "bold",
            fontColor = C.textYellow,
        },
    }
    if subtitle and subtitle ~= "" then
        table.insert(headerChildren, UI.Label {
            text = subtitle,
            fontSize = 11, fontColor = C.textGray,
        })
    end

    local bodyChildren = {}
    -- 额外头部（如 HUD）
    if extraHeader then
        table.insert(bodyChildren, extraHeader)
    end
    -- 标题区
    table.insert(bodyChildren, UI.Panel {
        width = "100%", padding = 14,
        backgroundColor = C.panelDark,
        alignItems = "center", gap = 3,
        children = headerChildren,
    })
    -- 列表
    table.insert(bodyChildren, UI.ScrollView {
        flex = 1, flexBasis = 0,
        width = "100%",
        padding = 14,
        contentContainerStyle = { gap = 8, paddingBottom = 20 },
        children = cards,
    })

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgDark,
        flexDirection = "column",
        children = bodyChildren,
    }
end

-- ============================================================================
-- 开局选择阶段
-- ============================================================================
function Screens.CreateWorkplaceSelect()
    return CreateSelectionScreen(
        "选择职场环境",
        "不同环境，不同酒桌规矩",
        GameData.Workplaces,
        function(item)
            GameLogic.SelectWorkplace(item)
            if onScreenChange_ then onScreenChange_("select_character") end
        end
    )
end

function Screens.CreateCharacterSelect()
    return CreateSelectionScreen(
        "选择你的角色",
        "角色决定起始职级和专属技能",
        GameData.Characters,
        function(item)
            GameLogic.SelectCharacter(item)
            if onScreenChange_ then onScreenChange_("day_start") end
        end
    )
end

-- ============================================================================
-- 每日开始界面 (day_start)
-- ============================================================================
function Screens.CreateDayStart()
    local s = GameLogic.State
    local levelData = GameLogic.GetLevelData(s.currentLevel)

    -- 天数进度指示
    local dayDots = {}
    for d = 1, s.maxDays do
        local dotColor = { 80, 80, 80, 255 }
        local dotText = tostring(d)
        if d < s.currentDay then
            dotColor = C.green
            dotText = "✓"
        elseif d == s.currentDay then
            dotColor = C.accent
        end
        table.insert(dayDots, UI.Panel {
            width = 36, height = 36,
            backgroundColor = dotColor,
            borderRadius = 18,
            justifyContent = "center", alignItems = "center",
            children = {
                UI.Label { text = dotText, fontSize = 14, fontColor = C.textWhite },
            },
        })
        if d < s.maxDays then
            table.insert(dayDots, UI.Panel {
                width = 20, height = 2,
                backgroundColor = d < s.currentDay and C.green or { 80, 80, 80, 255 },
            })
        end
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgDark,
        justifyContent = "center",
        alignItems = "center",
        gap = 24,
        children = {
            -- 天数进度
            UI.Panel {
                flexDirection = "row", alignItems = "center", gap = 4,
                children = dayDots,
            },
            -- 当日信息
            UI.Panel {
                alignItems = "center", gap = 8,
                padding = 24,
                backgroundColor = C.panelDark,
                borderRadius = 16,
                width = 300,
                children = {
                    UI.Label {
                        text = "第 " .. s.currentDay .. " 天",
                        fontSize = 28, fontWeight = "bold",
                        fontColor = C.textYellow,
                    },
                    UI.Label {
                        text = levelData.icon .. " " .. levelData.name .. " (Lv." .. s.currentLevel .. ")",
                        fontSize = 16, fontColor = C.textWhite,
                    },
                    UI.Label {
                        text = "💰 余额 ¥" .. s.money,
                        fontSize = 14, fontColor = C.textGold,
                    },
                    UI.Label {
                        text = s.character.icon .. " " .. s.character.name .. " · " .. s.workplace.icon .. " " .. s.workplace.name,
                        fontSize = 12, fontColor = C.textGray,
                        marginTop = 4,
                    },
                    -- 被优化次数
                    UI.Label {
                        text = "❌ 被优化 " .. s.optimizeCount .. "/" .. s.maxOptimize,
                        fontSize = 12,
                        fontColor = s.optimizeCount > 0 and C.red or C.textGray,
                        marginTop = 2,
                    },
                },
            },
            -- 开始按钮
            UI.Button {
                text = "🍻  出发赴宴",
                width = 200, height = 46,
                variant = "primary",
                fontSize = 16,
                onClick = function()
                    GameLogic.StartDay()
                    if onScreenChange_ then onScreenChange_(GameLogic.State.phase) end
                end,
            },
        },
    }
end

-- ============================================================================
-- 休息日界面 (rest_day)
-- ============================================================================
function Screens.CreateRestDay()
    local s = GameLogic.State
    local msg = GameData.RestDayMessages[math.random(1, #GameData.RestDayMessages)]

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgDark,
        justifyContent = "center",
        alignItems = "center",
        gap = 20,
        children = {
            UI.Label { text = "😴", fontSize = 64 },
            UI.Label {
                text = "休息日",
                fontSize = 24, fontWeight = "bold",
                fontColor = C.textWhite,
            },
            UI.Panel {
                width = 300, padding = 20,
                backgroundColor = C.panelDark,
                borderRadius = 14,
                alignItems = "center",
                children = {
                    UI.Label {
                        text = msg,
                        fontSize = 14,
                        fontColor = C.textGray,
                        textAlign = "center",
                        whiteSpace = "normal",
                    },
                },
            },
            UI.Label {
                text = "Day " .. s.currentDay .. "/" .. s.maxDays .. " · 职级不变",
                fontSize = 12, fontColor = C.textGray,
            },
            UI.Button {
                text = "💤  结束休息 → 下一天",
                width = 220, height = 44,
                variant = "secondary",
                fontSize = 14,
                onClick = function()
                    GameLogic.EndRestDay()
                    if onScreenChange_ then onScreenChange_(GameLogic.State.phase) end
                end,
            },
        },
    }
end

-- ============================================================================
-- 每日选择阶段（带HUD）
-- ============================================================================
function Screens.CreateRestaurantSelect()
    local s = GameLogic.State
    local available = GameLogic.GetAvailableRestaurants()
    local minTier, maxTier = GameData.GetTierRange(s.currentLevel)
    return CreateSelectionScreen(
        "选择饭局场地",
        "Tier " .. minTier .. "-" .. maxTier .. " · 余额 ¥" .. s.money,
        available,
        function(item)
            GameLogic.SelectRestaurant(item)
            if onScreenChange_ then onScreenChange_("select_drink_type") end
        end,
        CreateHUD()
    )
end

function Screens.CreateDrinkTypeSelect()
    return CreateSelectionScreen(
        "选什么类型的酒",
        "酒的类型影响面子和清醒度",
        GameData.DrinkTypes,
        function(item)
            GameLogic.SelectDrinkType(item)
            if onScreenChange_ then onScreenChange_("select_drink_brand") end
        end,
        CreateHUD()
    )
end

function Screens.CreateDrinkBrandSelect()
    local s = GameLogic.State
    local brands = GameLogic.GetAvailableBrands()
    return CreateSelectionScreen(
        "选一个品牌",
        s.drinkType.name .. " · 余额 ¥" .. s.money,
        brands,
        function(item)
            GameLogic.SelectDrinkBrand(item)
            if onScreenChange_ then onScreenChange_("playing") end
        end,
        CreateHUD()
    )
end

-- ============================================================================
-- 游戏进行界面 (playing)
-- ============================================================================
function Screens.CreateGameScreen()
    local s = GameLogic.State

    -- 摇骰子
    local p, o = GameLogic.RollDice()
    local event = GameLogic.GetNextEvent()

    if not event then
        -- 没有事件了 → 进入日结算
        s.phase = "day_result"
        if onScreenChange_ then onScreenChange_("day_result") end
        return UI.Panel { width = "100%", height = "100%" }
    end

    -- 选项按钮
    local choiceButtons = {}
    for i, choice in ipairs(event.choices) do
        table.insert(choiceButtons, UI.Panel {
            width = "100%",
            padding = 12,
            backgroundColor = { 55, 60, 78, 235 },
            borderRadius = 10,
            borderWidth = 1,
            borderColor = { 90, 100, 130, 80 },
            pointerEvents = "auto",
            onClick = function()
                GameLogic.MakeChoice(i)
                local phase = GameLogic.State.phase
                if onScreenChange_ then onScreenChange_(phase) end
            end,
            children = {
                UI.Label {
                    text = choice.text,
                    fontSize = 14,
                    fontColor = C.textWhite,
                    whiteSpace = "normal",
                },
            },
        })
    end

    -- 骰子描述
    local diceResult = GameLogic.GetDiceResult()
    local diceDesc = diceResult == "tie" and "🍻 平局干杯！"
        or diceResult == "advantage" and "💪 你占优势！"
        or "😅 对方优势..."

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgDark,
        flexDirection = "column",
        children = {
            -- HUD
            CreateHUD(),
            -- 属性条
            UI.Panel {
                width = "100%", paddingLeft = 14, paddingRight = 14, paddingTop = 6, paddingBottom = 6,
                flexDirection = "row", gap = 8,
                children = {
                    UI.Panel { flex = 1, children = { AttrBar("好感", s.favor, C.green) } },
                    UI.Panel { flex = 1, children = { AttrBar("清醒", s.sober, C.blue) } },
                    UI.Panel { flex = 1, children = { AttrBar("氛围", s.vibe, C.purple) } },
                },
            },
            -- 骰子区
            UI.Panel {
                width = "100%", padding = 10,
                alignItems = "center", gap = 4,
                children = {
                    UI.Panel {
                        flexDirection = "row", gap = 20, alignItems = "center",
                        children = {
                            UI.Panel {
                                width = 44, height = 44,
                                backgroundColor = { 255, 255, 255, 255 },
                                borderRadius = 8,
                                justifyContent = "center", alignItems = "center",
                                children = {
                                    UI.Label { text = tostring(p), fontSize = 22, fontWeight = "bold", fontColor = { 30, 30, 30, 255 } },
                                },
                            },
                            UI.Label { text = "VS", fontSize = 13, fontColor = C.textGray },
                            UI.Panel {
                                width = 44, height = 44,
                                backgroundColor = { 70, 70, 70, 255 },
                                borderRadius = 8,
                                justifyContent = "center", alignItems = "center",
                                children = {
                                    UI.Label { text = tostring(o), fontSize = 22, fontWeight = "bold", fontColor = C.textWhite },
                                },
                            },
                        },
                    },
                    UI.Label { text = diceDesc .. " (回合 " .. s.round .. "/" .. s.maxRounds .. ")", fontSize = 11, fontColor = C.textGray },
                },
            },
            -- 事件文本
            UI.Panel {
                width = "100%", paddingLeft = 14, paddingRight = 14, paddingBottom = 8,
                children = {
                    UI.Panel {
                        width = "100%", padding = 14,
                        backgroundColor = { 40, 45, 60, 245 },
                        borderRadius = 10,
                        borderWidth = 1, borderColor = C.accent,
                        children = {
                            UI.Label {
                                text = event.text,
                                fontSize = 14, fontColor = C.textWhite,
                                whiteSpace = "normal",
                            },
                        },
                    },
                },
            },
            -- 选项
            UI.ScrollView {
                flex = 1, flexBasis = 0,
                width = "100%",
                padding = 14,
                contentContainerStyle = { gap = 8, paddingBottom = 16 },
                children = choiceButtons,
            },
        },
    }
end

-- ============================================================================
-- 每日结算界面 (day_result)
-- ============================================================================
function Screens.CreateDayResult()
    local s = GameLogic.State
    local result = GameLogic.GetBanquetResult()
    local resultMsg = GameLogic.GetResultMessage(result)

    -- 应用结果
    local levelBefore = s.currentLevel
    GameLogic.ApplyBanquetResult(result)
    local levelAfter = s.currentLevel

    -- 结果颜色和图标
    local resultInfo = {
        promote   = { icon = "🎉", label = "升职！", color = C.green },
        maintain  = { icon = "😐", label = "原地踏步", color = C.textGray },
        demote    = { icon = "📉", label = "降级...", color = C.accent },
        optimized = { icon = "💀", label = "被优化！", color = C.red },
    }
    local info = resultInfo[result] or resultInfo.maintain

    -- 职级变化显示
    local levelBeforeData = GameLogic.GetLevelData(levelBefore)
    local levelAfterData = GameLogic.GetLevelData(levelAfter)
    local levelChangeText = levelBeforeData.icon .. " Lv." .. levelBefore .. " " .. levelBeforeData.name
    if levelBefore ~= levelAfter then
        levelChangeText = levelChangeText .. "  →  " .. levelAfterData.icon .. " Lv." .. levelAfter .. " " .. levelAfterData.name
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgDark,
        justifyContent = "center",
        alignItems = "center",
        gap = 16,
        children = {
            -- Day 标记
            UI.Label {
                text = "第 " .. s.currentDay .. " 天 结算",
                fontSize = 13, fontColor = C.textGray,
            },
            -- 结果图标
            UI.Label { text = info.icon, fontSize = 56 },
            UI.Label {
                text = info.label,
                fontSize = 24, fontWeight = "bold",
                fontColor = info.color,
            },
            -- 描述
            UI.Panel {
                width = 300, padding = 16,
                backgroundColor = C.panelDark,
                borderRadius = 12,
                alignItems = "center", gap = 8,
                children = {
                    UI.Label {
                        text = resultMsg,
                        fontSize = 14, fontColor = C.textWhite,
                        textAlign = "center",
                        whiteSpace = "normal",
                    },
                    UI.Divider { marginTop = 6, marginBottom = 6 },
                    -- 职级变化
                    UI.Label {
                        text = levelChangeText,
                        fontSize = 13,
                        fontColor = levelBefore ~= levelAfter and C.textYellow or C.textGray,
                        textAlign = "center",
                    },
                    -- 被优化计数
                    UI.Label {
                        text = "❌ 被优化 " .. s.optimizeCount .. "/" .. s.maxOptimize,
                        fontSize = 12,
                        fontColor = s.optimizeCount > 0 and C.red or C.textGray,
                    },
                },
            },
            -- 属性回顾
            UI.Panel {
                width = 300, padding = 12, gap = 4,
                backgroundColor = C.panelCard,
                borderRadius = 10,
                children = {
                    AttrBar("好感度", s.favor, C.green),
                    AttrBar("清醒度", s.sober, C.blue),
                    AttrBar("氛围值", s.vibe, C.purple),
                    AttrBar("尊严值", s.dignity, C.accent),
                },
            },
            -- 继续按钮
            UI.Button {
                text = "→  继续",
                width = 200, height = 44,
                variant = "primary",
                fontSize = 15,
                onClick = function()
                    GameLogic.ProceedAfterResult()
                    if onScreenChange_ then onScreenChange_(GameLogic.State.phase) end
                end,
            },
        },
    }
end

-- ============================================================================
-- 终局界面 (game_over)
-- ============================================================================
function Screens.CreateGameOver()
    local s = GameLogic.State
    local title = GameLogic.GetTitle()

    -- 根据终局类型展示不同内容
    local headerIcon, headerText, headerColor, headerDesc
    if s.gameOverType == "win" then
        headerIcon = "👔"
        headerText = "通关！成为老板！"
        headerColor = C.textGold
        headerDesc = "从底层到顶层，你证明了自己！"
    elseif s.gameOverType == "fired" then
        headerIcon = "📦"
        headerText = "被开除了..."
        headerColor = C.red
        headerDesc = "被优化 " .. s.optimizeCount .. " 次，收拾东西走人吧"
    else -- timeout
        local rating = GameLogic.GetFinalRating()
        headerIcon = "⏰"
        headerText = rating.label
        headerColor = C.textYellow
        headerDesc = rating.msg
    end

    -- 天数历史
    local historyItems = {}
    for _, h in ipairs(s.dayHistory) do
        local resultLabel = ({
            promote = "↑升职", maintain = "—维持", demote = "↓降级",
            optimized = "✗优化", rest = "💤休息",
        })[h.result] or h.result
        local resultColor = ({
            promote = C.green, maintain = C.textGray, demote = C.accent,
            optimized = C.red, rest = C.blue,
        })[h.result] or C.textGray

        table.insert(historyItems, UI.Panel {
            width = "100%", flexDirection = "row", justifyContent = "space-between",
            paddingTop = 3, paddingBottom = 3,
            children = {
                UI.Label { text = "Day " .. h.day, fontSize = 12, fontColor = C.textGray },
                UI.Label { text = resultLabel, fontSize = 12, fontColor = resultColor },
                UI.Label {
                    text = "Lv." .. h.levelBefore .. "→" .. h.levelAfter,
                    fontSize = 12, fontColor = C.textWhite,
                },
            },
        })
    end

    return UI.Panel {
        width = "100%", height = "100%",
        backgroundColor = C.bgWarm,
        flexDirection = "column",
        children = {
            UI.ScrollView {
                flex = 1, flexBasis = 0,
                width = "100%",
                contentContainerStyle = { padding = 24, gap = 14, alignItems = "center" },
                children = {
                    -- 头部
                    UI.Label { text = headerIcon, fontSize = 56 },
                    UI.Label {
                        text = headerText,
                        fontSize = 26, fontWeight = "bold",
                        fontColor = headerColor,
                    },
                    UI.Label {
                        text = headerDesc,
                        fontSize = 14, fontColor = { 80, 40, 0, 200 },
                        textAlign = "center",
                        whiteSpace = "normal",
                    },
                    -- 统计
                    UI.Panel {
                        width = "90%", maxWidth = 360,
                        padding = 14, gap = 6,
                        backgroundColor = C.panelDark,
                        borderRadius = 12,
                        children = {
                            StatRow("角色", s.character.icon .. " " .. s.character.name),
                            StatRow("公司", s.workplace.icon .. " " .. s.workplace.name),
                            StatRow("起始职级", "Lv." .. s.startLevel .. " " .. GameLogic.GetLevelData(s.startLevel).name),
                            StatRow("最终职级", "Lv." .. s.currentLevel .. " " .. GameLogic.GetLevelData(s.currentLevel).name,
                                s.currentLevel > s.startLevel and C.green or
                                s.currentLevel < s.startLevel and C.red or C.textWhite),
                            UI.Divider { marginTop = 4, marginBottom = 4 },
                            StatRow("完成酒局", s.banquetCount .. " 场"),
                            StatRow("被优化次数", s.optimizeCount .. " 次",
                                s.optimizeCount > 0 and C.red or C.textWhite),
                            StatRow("总花费", "¥" .. s.totalSpent),
                            StatRow("最高连续升职", s.maxConsecutive .. " 次",
                                s.maxConsecutive >= 3 and C.green or C.textWhite),
                        },
                    },
                    -- 每天记录
                    UI.Panel {
                        width = "90%", maxWidth = 360,
                        padding = 14, gap = 4,
                        backgroundColor = C.panelDark,
                        borderRadius = 12,
                        children = {
                            UI.Label { text = "📅 每日记录", fontSize = 13, fontColor = C.textYellow, marginBottom = 4 },
                            table.unpack(historyItems),
                        },
                    },
                    -- 称号
                    UI.Panel {
                        width = "90%", maxWidth = 360,
                        padding = 16,
                        backgroundColor = { 160, 50, 30, 230 },
                        borderRadius = 12,
                        alignItems = "center", gap = 4,
                        children = {
                            UI.Label { text = "鉴定结果", fontSize = 11, fontColor = { 255, 200, 150, 180 } },
                            UI.Label {
                                text = "【" .. title.name .. "】",
                                fontSize = 20, fontWeight = "bold",
                                fontColor = C.textYellow,
                            },
                            UI.Label {
                                text = title.desc,
                                fontSize = 12, fontColor = { 255, 220, 180, 200 },
                            },
                        },
                    },
                },
            },
            -- 底部按钮
            UI.Panel {
                width = "100%", padding = 16,
                alignItems = "center",
                children = {
                    UI.Button {
                        text = "🔄  重新入职",
                        width = 220, height = 48,
                        variant = "primary",
                        fontSize = 16,
                        onClick = function()
                            GameLogic.Reset()
                            if onScreenChange_ then onScreenChange_("menu") end
                        end,
                    },
                },
            },
        },
    }
end

return Screens
