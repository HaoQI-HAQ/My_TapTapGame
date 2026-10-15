-- 《酒桌文化》新版美术页面。主题/饭局舞台独立模块；保持旧 Screens API。
local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local GameData = require("Data.GameData")
local Art = require("UI.ArtTheme")
local Playing = require("UI.Playing")
local MainMenu = require("UI.MainMenu")
local Screens = {}
local C, A = Art.C, Art.Assets
---@type fun(screenName: string)?
local onScreenChange_ = nil
local resultCache = {}

function Screens.SetOnScreenChange(callback)
    onScreenChange_ = callback
end

-- 既有及点菜页面由入口回调路由；图鉴只作为纯 UI 支路独立挂载。
local function Navigate(phase)
    print("[ArtUI] → " .. tostring(phase))
    if onScreenChange_ then onScreenChange_(phase) end
end

local function Select(action, item, fallback)
    local ok, err = action(item)
    if ok == false then
        UI.Toast.Show(tostring(err or "余额不足，请换一个选择。"), {variant = "warning", duration = 3})
        return
    end
    Navigate(GameLogic.State.phase or fallback)
end

local function HUD()
    local s = GameLogic.State
    return Art.HUD(s, GameLogic.GetLevelData(s.currentLevel).name)
end

-- 页面标题与内容分层，短横屏缩减装饰而不挤压滚动区域。
local function Heading(kicker, title, subtitle)
    local headline = Art.Title(title, 27, C.paper, {width = "100%"})
    local caption = Art.Text(subtitle, 12, C.paper, {width = "100%", opacity = 0.78})
    local eyebrow = Art.Text(kicker, 10, C.yellow, {letterSpacing = 1})
    local panel = UI.Panel {width = "100%", paddingHorizontal = 24, paddingVertical = 16, gap = 5,
        backgroundColor = C.dark, children = {eyebrow, headline, caption}}
    return panel, headline, caption, eyebrow
end

local function Sheet(title, subtitle, children, background)
    local body = UI.Panel {width = "100%", maxWidth = 1080, alignSelf = "center", padding = 24, gap = 16,
        children = children}
    local heading, headline, caption, eyebrow = Heading("酒桌文化 / 我的手记", title, subtitle)
    local root = Art.Root({Art.Safe({heading,
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, flexShrink = 1, minHeight = 0,
            scrollY = true, children = {body}}})}, background)
    return Art.Responsive(root, function(w, h)
        local compact = h < 550
        body:SetStyle({padding = w < 620 and 14 or 24, gap = compact and 12 or 16})
        heading:SetStyle({paddingHorizontal = w < 620 and 18 or 24, paddingVertical = compact and 9 or 16})
        headline:SetFontSize(compact and 21 or 27)
        caption:SetFontSize(compact and 11 or 12)
        eyebrow:SetVisible(not compact)
    end)
end

local function TwoColumns(left, right)
    return UI.SimpleGrid {width = "100%", minColumnWidth = 330, gap = 16,
        children = {left, right}}
end

local function Metric(label, value, color)
    return UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, minWidth = 100, padding = 12,
        backgroundColor = C.lilac, borderRadius = 10, gap = 5, children = {
            Art.Text(label, 11, C.muted, {width = "100%"}),
            Art.Title(tostring(value), 20, color or C.ink, {width = "100%"}),
        }}
end

local function Profile(state)
    return UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 14, children = {
        Art.Picture(Art.Character(state.character, true), {width = 74, height = 90}),
        UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, gap = 5, children = {
            Art.Title((state.character or {}).name, 22, C.ink, {width = "100%"}),
            Art.Text((state.workplace or {}).name, 12, C.muted, {width = "100%"}),
            Art.Text("Lv." .. state.currentLevel .. " · " .. GameLogic.GetLevelData(state.currentLevel).name,
                13, C.purple, {width = "100%"}),
        }},
    }}
end

local prepSteps = {"职场", "身份", "场地", "酒类", "品牌", "菜品"}
local prepIndex = {workplace = 1, character = 2, restaurant = 3, drink = 4, brand = 5, dish = 6}

local function Preparation(kind)
    local current = prepIndex[kind] or 1
    local steps = {}
    for i, name in ipairs(prepSteps) do
        local active, done = i == current, i < current
        steps[#steps + 1] = UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, gap = 6, children = {
            UI.Panel {width = "100%", height = 3, borderRadius = 2,
                backgroundColor = (active or done) and C.yellow or C.lilac},
            Art.Text(name, 11, active and C.purple or C.muted,
                {width = "100%", textAlign = "center", fontWeight = active and "bold" or "normal", whiteSpace = "nowrap"}),
        }}
    end
    return UI.Panel {width = "100%", paddingHorizontal = 20, paddingVertical = 11,
        backgroundColor = C.paper, flexDirection = "row", gap = 8, children = steps}
end

function Screens.CreateMainMenu()
    return MainMenu.Create(function()
        resultCache = {}
        GameLogic.StartNewGame()
        Navigate("select_workplace")
    end, function()
        Navigate("art_gallery")
    end, function()
        Navigate("dice_demo")
    end)
end

local workplaceScenes = {internet = "craftbeer", state = "biz_chinese", realestate = "dapaidang",
    finance = "michelin", media = "izakaya", game = "hotpot", startup = "bbq", factory = "flyshop"}

local function Visual(item, kind)
    if kind == "character" then return Art.Character(item, true), "cover" end
    if kind == "restaurant" then return Art.Pick(item.thumbnail, item.background, Art.Background(item)), "cover" end
    if kind == "workplace" then return Art.Pick(item.thumbnail, item.background,
        Art.Background({id = workplaceScenes[item.id]})), "cover" end
    if kind == "drink" then return Art.Pick(item.thumbnail, A.drinks[item.id]), "contain" end
    if kind == "brand" then return Art.Pick(item.thumbnail, A.drinks[(GameLogic.State.drinkType or {}).id]), "contain" end
    return Art.Pick(item.thumbnail), "contain"
end

local function Details(item, kind)
    local info = item.desc or item.special or ""
    local tag = ""
    if kind == "character" then
        tag = "Lv." .. item.startLevel .. " 起步"
        info = "技能 · " .. (item.skill or "专属技能") .. "\n" .. (item.skillDesc or "")
    elseif kind == "workplace" then
        tag = "难度 " .. (item.difficulty or 1) .. " / 5"
    elseif kind == "restaurant" then
        tag = "T" .. item.tier .. " · ¥" .. item.costPerPerson .. "/人"
        info = info .. "\n双人席 ¥" .. item.costPerPerson * 2 .. " · 面子 +" .. (item.faceBonus or 0)
    elseif kind == "drink" then
        tag = "面子基数 +" .. (item.faceBase or 0)
        info = "清醒影响 " .. (item.soberHit or 0) .. " / 杯"
    elseif kind == "dish" then
        tag = "T" .. (item.tier or 1) .. " · ¥" .. (item.cost or item.price or 0)
        info = "面子 +" .. (item.face or 0) .. "  氛围 +" .. (item.vibe or 0) .. "\n清醒 +" .. (item.sober or 0)
    elseif item.price then
        tag = "¥" .. item.price
        info = (item.special or info) .. "\n面子 +" .. (item.face or 0)
    end
    return tag, info
end

local function BudgetNotice()
    local logic = GameLogic --[[@as table]]
    if type(logic.GetBudgetStatus) ~= "function" then return nil end
    local status = logic.GetBudgetStatus()
    if not status or status.canContinue ~= false then return nil end
    return Art.Paper({
        Art.Text("预算告急 · 今日饭局无法继续", 16, C.red, {fontWeight = "bold", width = "100%"}),
        Art.Text(status.message or "当前余额无法支付任何完整饭局组合。", 12, C.ink, {width = "100%"}),
        Art.Text("最低还需 ¥" .. tostring(status.minimumRequired or 0) .. " · 缺口 ¥" .. tostring(status.shortfall or 0),
            12, C.red, {width = "100%"}),
        Art.Button("预算不足，结束今日饭局", function()
            if type(logic.EndDayForInsufficientBudget) ~= "function" then
                UI.Toast.Show("预算结算接口尚未就绪。", {variant = "warning"})
                return
            end
            local ok, err = logic.EndDayForInsufficientBudget()
            if not ok then
                UI.Toast.Show(tostring(err or "仍有可负担选择，请继续挑选。"), {variant = "warning", duration = 3})
                return
            end
            Navigate(GameLogic.State.phase)
        end, false, {width = "100%", id = "end_day_insufficient_budget"}),
    }, {width = "100%", padding = 12, gap = 6, borderColor = C.red, id = "budget_notice"})
end

local function Selection(title, subtitle, items, kind, onSelect, withHUD)
    local cards, layouts = {}, {}
    local selected = false
    for index, item in ipairs(items or {}) do
        local path, fit = Visual(item, kind)
        local tag, description = Details(item, kind)
        local unaffordable = item.affordable == false
        local imageMat = Art.Picture(path, {width = "100%", height = 164, backgroundFit = fit,
            borderRadius = 10, overflow = "hidden"})
        local descriptionLabel = Art.Text(description, 12, C.muted, {width = "100%", lineHeight = 1.55})
        local info = UI.Panel {width = "100%", gap = 7, minWidth = 0, children = {
            Art.Title(item.name, 20, unaffordable and C.muted or C.ink, {width = "100%"}),
            Art.Text(tag, 12, unaffordable and C.red or C.purple, {width = "100%", fontWeight = "bold"}),
            descriptionLabel,
        }}
        if kind == "brand" and item.thumbnailLabel then
            info:AddChild(Art.Text(item.thumbnailLabel, 10, C.muted, {width = "100%", lineHeight = 1.4}))
        end
        info:AddChild(UI.Panel {width = "100%", marginTop = 5, flexDirection = "row", alignItems = "center",
            justifyContent = "space-between", gap = 6, children = {
                Art.Text(unaffordable and "余额不足 · 查看原因" or "确认选择", 12,
                    unaffordable and C.red or C.purple, {flexGrow = 1, flexBasis = 0, flexShrink = 1}),
                Art.Title("→", 20, unaffordable and C.muted or C.purple, {width = 28, textAlign = "right"}),
            }})
        local card = Art.Paper({imageMat, info}, {padding = 14, gap = 13, minWidth = 0,
            pointerEvents = "box-only", id = kind .. "_" .. (item.id or index),
            onClick = function()
                if selected then return end
                selected = true
                onSelect(item)
                selected = false
            end,
            onPointerEnter = function(_, widget) widget:SetStyle({borderColor = C.purple, translateY = -2}) end,
            onPointerLeave = function(_, widget) widget:SetStyle({borderColor = C.line, translateY = 0}) end,
            transition = "translateY 0.12s easeOut, borderColor 0.12s easeOut"})
        cards[#cards + 1] = card
        layouts[#layouts + 1] = {card = card, image = imageMat, info = info, description = descriptionLabel}
    end
    if #cards == 0 then
        cards[1] = Art.Paper({Art.Title("暂时没有可选项", 18), Art.Text("请确认数据接口已就绪。", 12, C.muted)})
    end
    local grid = UI.SimpleGrid {width = "100%", minColumnWidth = 290, gap = 16, children = cards}
    local list = UI.Panel {width = "100%", maxWidth = 1200, alignSelf = "center", padding = 22, gap = 16}
    local budget = withHUD and BudgetNotice() or nil
    if budget then list:AddChild(budget) end
    list:AddChild(grid)
    local heading, headline, caption, eyebrow = Heading("赴宴准备 · " .. (prepIndex[kind] or 1) .. " / 6", title, subtitle)
    local progress = Preparation(kind)
    local children = {}
    if withHUD then children[#children + 1] = HUD() end
    children[#children + 1] = heading
    children[#children + 1] = progress
    children[#children + 1] = UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, flexShrink = 1,
        minHeight = 0, scrollY = true, showScrollbar = true, children = {list}}
    local root = Art.Root({Art.Safe(children)})
    return Art.Responsive(root, function(w, h)
        local narrow, compact = w < 650, h < 550
        heading:SetStyle({paddingHorizontal = narrow and 18 or 24, paddingVertical = compact and 8 or 16})
        headline:SetFontSize(compact and 21 or 27)
        caption:SetFontSize(compact and 11 or 12)
        eyebrow:SetVisible(not compact)
        progress:SetStyle({paddingVertical = compact and 7 or 11, paddingHorizontal = narrow and 14 or 24})
        list:SetStyle({padding = narrow and 14 or 22, paddingBottom = 24})
        for _, layout in ipairs(layouts) do
            local row = narrow
            layout.card:SetStyle({flexDirection = row and "row" or "column", alignItems = row and "center" or "stretch",
                padding = compact and 12 or 14, gap = row and 14 or 12})
            layout.image:SetStyle({width = row and (kind == "character" and 122 or 110) or "100%",
                height = row and (kind == "character" and 180 or 135) or (compact and 116 or (kind == "character" and 190 or 164))})
            layout.info:SetStyle({width = row and "auto" or "100%", flexGrow = 1, flexShrink = 1,
                flexBasis = row and 0 or "auto"})
            layout.description:SetStyle({minHeight = row and 0 or (kind == "character" and 83 or 56)})
        end
    end)
end

function Screens.CreateWorkplaceSelect()
    return Selection("选择职场环境", "不同的公司，不同的酒桌规矩。", GameData.Workplaces, "workplace", function(item)
        Select(GameLogic.SelectWorkplace, item, "select_character")
    end)
end

function Screens.CreateCharacterSelect()
    local characters = {}
    -- 普瑞斯属于隐藏对手；区域老板 boss 是可选玩家，不能混淆。
    for _, item in ipairs(GameData.Characters) do
        if item.id ~= "pu_rui_si" then characters[#characters + 1] = item end
    end
    return Selection("选择你的角色", "从哪一级出发，由你决定。技能与身份将伴随整个职场旅程。", characters, "character", function(item)
        Select(GameLogic.SelectCharacter, item, "day_start")
    end)
end

function Screens.CreateRestaurantSelect()
    local minTier, maxTier = GameData.GetTierRange(GameLogic.State.currentLevel)
    return Selection("今晚，在哪张桌子？", "已解锁 T" .. minTier .. "—T" .. maxTier .. " · 场地费用按双人席计算。",
        GameLogic.GetAvailableRestaurants(), "restaurant", function(item)
            Select(GameLogic.SelectRestaurant, item, "select_drink_type")
        end, true)
end

function Screens.CreateDrinkTypeSelect()
    return Selection("选一杯开场白", "排面还是清醒？也可以以茶代酒。", GameData.DrinkTypes, "drink", function(item)
        Select(GameLogic.SelectDrinkType, item, "select_drink_brand")
    end, true)
end

function Screens.CreateDrinkBrandSelect()
    local drink = GameLogic.State.drinkType or {}
    return Selection("为饭局挑个品牌", (drink.name or "酒水") .. " · 量力而行，预算也是实力的一部分。",
        GameLogic.GetAvailableBrands(), "brand", function(item)
            local ok, err = GameLogic.SelectDrinkBrand(item)
            if ok == false then UI.Toast.Show(tostring(err or "余额不足"), {variant = "warning"}); return end
            -- 老版 GameLogic 仍返回 playing，新版返回 select_dish；一律先展示点菜页。
            Navigate("select_dish")
        end, true)
end

function Screens.CreateDishSelect()
    -- 接口通过 table 收窄兼容并行数据/逻辑更新，不在 UI 层更改预算或菜品属性。
    local logic = GameLogic --[[@as table]]
    if type(logic.GetAvailableDishes) == "function" and type(logic.SelectDish) == "function" then
        return Selection("再点几道好菜", "菜品会影响面子、氛围与清醒度 · 选择一道后正式开席。",
            logic.GetAvailableDishes(), "dish", function(item)
                Select(logic.SelectDish, item, "playing")
            end, true)
    end
    return Sheet("菜品准备中", "当前玩法版本尚未提供点菜接口。", {
        Art.Text("新版菜品接口接入后，这里将显示可选菜品及价格。", 15),
        Art.Button("继续旧版饭局", function() Navigate("playing") end),
    })
end

function Screens.CreateDayStart()
    local s = GameLogic.State
    local character = s.character or {}
    local progress = {}
    for day = 1, s.maxDays do
        progress[#progress + 1] = UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0,
            minWidth = 30, gap = 6, alignItems = "center", children = {
                UI.Panel {width = "100%", height = 4, borderRadius = 2,
                    backgroundColor = day <= s.currentDay and C.yellow or C.lilac},
                Art.Text("第" .. day .. "天", 11, day == s.currentDay and C.purple or C.muted,
                    {width = "100%", textAlign = "center"}),
            }}
    end
    local identity = Art.Paper({Profile(s),
        UI.Panel {width = "100%", height = 1, backgroundColor = C.line},
        Art.Title(character.skill or "专属技能", 16, C.purple),
        Art.Text(character.skillDesc or "", 13, C.muted, {width = "100%", lineHeight = 1.6}),
    }, {minWidth = 0, padding = 20, gap = 14})
    local briefing = {Art.Title("今日赴宴备忘", 19, C.ink),
        UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 10, children = {
            Metric("可用预算", "¥" .. s.money),
            Metric("被优化次数", s.optimizeCount .. " / " .. s.maxOptimize, s.optimizeCount > 0 and C.red or C.purple),
        }},
        Art.Text("选好场地、酒水与菜品，再开始今天的饭局。", 13, C.muted, {width = "100%"}),
    }
    -- 昨日情报只读展示，为今日选酒、选菜与场地提供参考。
    local intel = GameLogic.GetIntel()
    if intel then
        local personality = GameLogic.GetPersonality(intel.personality)
        briefing[#briefing + 1] = UI.Panel {width = "100%", padding = 14, gap = 7,
            backgroundColor = C.lilac, borderRadius = 10, children = {
                Art.Title("昨日情报 · " .. personality.name, 15, C.purple, {width = "100%"}),
                Art.Text(intel.answer, 14, C.ink, {width = "100%", lineHeight = 1.6}),
                Art.Text("线索：" .. intel.tag, 12, C.muted, {width = "100%"}),
            }}
    end
    return Sheet("第 " .. s.currentDay .. " 天 · 出门之前", "新的饭局，新的生存机会。", {
        Art.Paper({UI.Panel {width = "100%", flexDirection = "row", gap = 10, children = progress}},
            {width = "100%", padding = 14}),
        TwoColumns(identity, Art.Paper(briefing, {minWidth = 0, padding = 20, gap = 14})),
        Art.Button("准备好了，出发赴宴  →", function() GameLogic.StartDay(); Navigate(s.phase) end,
            false, {width = "100%", minHeight = 52}),
    })
end

function Screens.CreateRestDay()
    local s = GameLogic.State
    local messages = GameData.RestDayMessages
    return Sheet("今天，不上酒桌", "第 " .. s.currentDay .. " / " .. s.maxDays .. " 天 · 休息日", {
        Art.Paper({
            Art.Picture(A.drinks.tea, {width = 140, height = 140, alignSelf = "center"}),
            Art.Title(messages[math.random(1, #messages)], 23, C.ink, {width = "100%", textAlign = "center", lineHeight = 1.5}),
            Art.Text("职级不变。偶尔离开饭局，也是生存策略。", 13, C.muted,
                {width = "100%", textAlign = "center"}),
            Art.Button("好好休息，明天继续", function() GameLogic.EndRestDay(); Navigate(s.phase) end,
                false, {width = "100%", marginTop = 10}),
        }, {width = "100%", maxWidth = 680, alignSelf = "center", padding = 24, gap = 16}),
    }, Art.Background({id = "flyshop"}))
end

function Screens.CreateGameScreen()
    return Playing.Create(Navigate)
end

function Screens.CreateDayResult()
    local s = GameLogic.State
    -- 构建/重进页面不得重复应用日结算。缓存只读展示结果，不替代玩法判定。
    if resultCache.state ~= s or resultCache.day ~= s.currentDay or resultCache.history ~= s.dayHistory then
        local result = GameLogic.GetBanquetResult()
        resultCache = {state = s, day = s.currentDay, history = s.dayHistory,
            result = result, message = GameLogic.GetResultMessage(result), before = s.currentLevel}
        GameLogic.ApplyBanquetResult(result)
        resultCache.after = s.currentLevel
    end
    local labels = {promote = "升职通知", maintain = "平稳落席", demote = "岗位调整", optimized = "优化预警"}
    local colors = {promote = C.green, maintain = C.purple, demote = C.red, optimized = C.red}
    local summary = Art.Paper({
        Profile(s),
        Art.Title(resultCache.message, 25, colors[resultCache.result], {width = "100%", lineHeight = 1.45}),
        UI.Panel {width = "100%", padding = 14, gap = 7, borderRadius = 10, backgroundColor = C.lilac, children = {
            Art.Text("本日职级变动", 11, C.muted),
            Art.Title("Lv." .. resultCache.before .. "  →  Lv." .. resultCache.after, 28, C.purple),
            Art.Text(GameLogic.GetLevelData(resultCache.before).name .. " → " ..
                GameLogic.GetLevelData(resultCache.after).name, 13, C.ink, {width = "100%"}),
        }},
        Art.Text((s --[[@as table]]).lastChoiceFeedback or "饭局结束，记得照顾好自己。", 13, C.muted,
            {width = "100%", lineHeight = 1.65}),
    }, {minWidth = 0, padding = 22, gap = 16})
    local details = Art.Paper({
        Art.Title("散席复盘", 19, C.ink),
        Art.Stats(s, true),
        UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 10, children = {
            Metric("剩余资金", "¥" .. s.money),
            Metric("被优化次数", s.optimizeCount .. " / " .. s.maxOptimize, s.optimizeCount > 0 and C.red or C.purple),
        }},
        Art.Text("把今天的得失记下，下一场继续从容入席。", 12, C.muted, {width = "100%"}),
    }, {minWidth = 0, padding = 22, gap = 18})
    return Sheet(labels[resultCache.result] or "饭局结算", "第 " .. s.currentDay .. " 天 · 饭局复盘", {
        TwoColumns(summary, details),
        Art.Button("收好工牌，继续  →", function() GameLogic.ProceedAfterResult(); Navigate(s.phase) end,
            false, {width = "100%", minHeight = 52}),
    }, Art.Background(s.restaurant))
end

function Screens.CreateGameOver()
    local s = GameLogic.State
    local title = GameLogic.GetTitle()
    local headline, description = "本次职场旅程结束", "饭局散场，故事还在继续。"
    if s.gameOverType == "win" then
        headline, description = "终于，坐上主位", "从底层到顶层，你拿到了属于自己的工牌。"
    elseif s.gameOverType == "fired" then
        headline, description = "离席，也是一种结局", "被优化 " .. s.optimizeCount .. " 次。下一份工作，重新开始。"
    else
        local rating = GameLogic.GetFinalRating() --[[@as table]]
        headline, description = rating.title or rating.label, rating.msg
    end
    ---@type Widget[]
    local history = {Art.Title("每日手记", 20, C.ink),
        Art.Text("每次落座，都留下了一点改变。", 12, C.muted, {width = "100%"})}
    local resultNames = {promote = "升职", maintain = "维持", demote = "降级", optimized = "被优化", rest = "休息"}
    local resultColors = {promote = C.green, maintain = C.purple, demote = C.red, optimized = C.red, rest = C.muted}
    for _, item in ipairs(s.dayHistory) do
        local color = resultColors[item.result] or C.purple
        history[#history + 1] = UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 12,
            paddingVertical = 11, borderBottomWidth = 1, borderBottomColor = C.line, children = {
                UI.Panel {width = 40, height = 40, borderRadius = 20, backgroundColor = C.lilac,
                    justifyContent = "center", alignItems = "center", children = {
                        Art.Title(tostring(item.day), 17, C.purple, {width = "100%", textAlign = "center"})}},
                UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, gap = 3, children = {
                    Art.Title(resultNames[item.result] or item.result, 15, color, {width = "100%"}),
                    Art.Text(GameLogic.GetLevelData(item.levelBefore).name .. " → " ..
                        GameLogic.GetLevelData(item.levelAfter).name, 11, C.muted, {width = "100%"}),
                }},
                Art.Text("Lv." .. item.levelBefore .. " → " .. item.levelAfter, 12, C.purple,
                    {width = 90, textAlign = "right", whiteSpace = "nowrap"}),
            }}
    end
    if #s.dayHistory == 0 then history[#history + 1] = Art.Text("这本手记，还在等待第一场饭局。", 13, C.muted) end
    local record = Art.Paper(history, {minWidth = 0, padding = 20, gap = 10})
    local summary = Art.Paper({Profile(s),
        Art.Paper({Art.Text("本次获得称号", 11, C.yellow),
            Art.Title(title.name, 27, C.paper, {width = "100%"}),
            Art.Text(title.desc, 13, C.paper, {width = "100%", lineHeight = 1.65})}, {width = "100%", padding = 18}, true),
        UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 10, children = {
            Metric("完成酒局", s.banquetCount .. " 场"), Metric("总花费", "¥" .. s.totalSpent),
        }},
        Art.StatRow("起始职级", "Lv." .. s.startLevel .. " " .. GameLogic.GetLevelData(s.startLevel).name),
        Art.StatRow("被优化次数", s.optimizeCount .. " 次", s.optimizeCount > 0 and C.red or C.muted),
        Art.StatRow("最高连续升职", s.maxConsecutive .. " 次"),
    }, {minWidth = 0, padding = 20, gap = 16})
    return Sheet(headline, description, {
        TwoColumns(summary, record),
        Art.Button("合上手记，重新入职  →", function() resultCache = {}; GameLogic.Reset(); Navigate("menu") end,
            false, {width = "100%", minHeight = 52}),
    })
end

-- 图鉴是纯 UI 支路；不重置 State、不掺入开局选择、不展示隐藏对手。
function Screens.CreateArtGallery()
    local characters, restaurants = {}, {}
    for _, item in ipairs(GameData.Characters) do
        if item.id ~= "pu_rui_si" then
            characters[#characters + 1] = Art.Paper({
                Art.Picture(Art.Character(item), {width = "100%", height = 210}),
                Art.Title(item.name, 20, C.ink, {width = "100%"}),
                Art.Text(item.skillDesc or item.desc, 12, C.muted, {width = "100%", lineHeight = 1.55}),
            }, {padding = 16, gap = 10, minWidth = 0})
        end
    end
    for _, item in ipairs(GameData.Restaurants) do
        restaurants[#restaurants + 1] = Art.Paper({
            Art.Picture(Art.Background(item), {width = "100%", height = 146, backgroundFit = "cover", borderRadius = 10}),
            Art.Title(item.name, 18, C.ink, {width = "100%"}),
            Art.Text("T" .. item.tier .. " · " .. (item.desc or ""), 12, C.muted, {width = "100%"}),
        }, {padding = 14, gap = 10, minWidth = 0})
    end
    return Sheet("桌边人物与风景", "这里只翻阅美术，不改变游戏进度。", {
        Art.Button("← 返回主菜单", function() Navigate("menu") end, true, {alignSelf = "flex-start"}),
        Art.Title("人物篇", 21, C.ink),
        UI.SimpleGrid {width = "100%", minColumnWidth = 240, gap = 16, children = characters},
        Art.Title("场地篇", 21, C.ink, {marginTop = 10}),
        UI.SimpleGrid {width = "100%", minColumnWidth = 270, gap = 16, children = restaurants},
    })
end

function Screens.Shutdown()
    Playing.Shutdown()
    onScreenChange_ = nil
    resultCache = {}
end

return Screens
