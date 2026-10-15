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

local function Heading(kicker, title, subtitle)
    return UI.Panel {width = "100%", padding = 16, gap = 5, children = {
        Art.Text(kicker, 10, C.purple, {letterSpacing = 2}),
        Art.Text(title, 25, C.ink, {fontWeight = "bold"}),
        Art.Text(subtitle, 12, C.muted, {width = "100%"}),
    }}
end

local function Sheet(title, subtitle, children, background)
    local card = Art.Paper(children, {width = "100%", maxWidth = 660, alignSelf = "center", padding = 22, gap = 14})
    local body = UI.Panel {width = "100%", padding = 18, gap = 12, children = {card}}
    local heading = Heading("AFTER HOURS / 酒桌手记", title, subtitle)
    heading:SetStyle({backgroundColor = {246, 239, 220, 238}})
    return Art.Root({Art.Safe({heading,
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, scrollY = true, children = {body}}})}, background)
end

function Screens.CreateMainMenu()
    return MainMenu.Create(function()
        resultCache = {}
        GameLogic.StartNewGame()
        Navigate("select_workplace")
    end, function()
        UI.SetRoot(Screens.CreateArtGallery(), true)
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
        info = (item.desc or "") .. "\n【" .. (item.skill or "专属技能") .. "】" .. (item.skillDesc or "")
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
        info = info .. "\n面子 +" .. (item.face or 0)
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
    local cards = {}
    local selected = false
    for index, item in ipairs(items or {}) do
        local path, fit = Visual(item, kind)
        local tag, description = Details(item, kind)
        local picture = Art.Picture(path, {width = "100%", height = kind == "character" and 190 or 132, backgroundFit = fit})
        local imageMat = UI.Panel {width = "100%", height = kind == "character" and 190 or 132,
            backgroundColor = C.lilac, overflow = "hidden", pointerEvents = "none", children = {picture,
                Art.Text(string.format("%02d", index), 11, C.ink, {position = "absolute", top = 5, left = 6,
                    width = 28, minWidth = 28, textAlign = "center", paddingHorizontal = 0, backgroundColor = C.yellow})}}
        local unaffordable = item.affordable == false
        local card = Art.Paper({imageMat,
            Art.Text(item.name, 17, unaffordable and C.muted or C.ink, {fontWeight = "bold", width = "100%"}),
            Art.Text(tag, 12, unaffordable and C.muted or C.purple, {fontWeight = "bold", width = "100%"}),
            Art.Text(description, 12, C.muted, {width = "100%"}),
            Art.Text(unaffordable and "余额不足 · 点击查看" or "选择这张  →", 11, unaffordable and C.red or C.ink,
                {alignSelf = "flex-end", minWidth = unaffordable and 140 or 90,
                    backgroundColor = unaffordable and C.lilac or C.yellow, padding = 4}),
        }, {padding = 10, gap = 7, minWidth = 0, pointerEvents = "box-only", id = kind .. "_" .. (item.id or index),
            onClick = function()
                if selected then return end
                selected = true
                onSelect(item)
                selected = false
            end,
            onPointerEnter = function(_, widget) widget:SetStyle({borderColor = C.purple, translateY = -2}) end,
            onPointerLeave = function(_, widget) widget:SetStyle({borderColor = C.ink, translateY = 0}) end,
            transition = "translateY 0.12s easeOut"})
        cards[#cards + 1] = card
    end
    if #cards == 0 then cards[1] = Art.Paper({Art.Text("暂时没有可选项。", 15), Art.Text("请确认数据接口已就绪。", 12, C.muted)}) end
    local grid = UI.SimpleGrid {width = "100%", minColumnWidth = 210, gap = 14, children = cards}
    local list = UI.Panel {width = "100%", padding = 18, paddingBottom = 30, children = {grid}}
    local children = {}
    if withHUD then children[#children + 1] = HUD() end
    children[#children + 1] = Heading("PREPARATION / 赴宴准备", title, subtitle)
    children[#children + 1] = UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, scrollY = true,
        showScrollbar = true, children = {list}}
    local budget = withHUD and BudgetNotice() or nil
    if budget then children[#children + 1] = budget end
    children[#children + 1] = Art.Text("向下滚动查看更多 · 点击照片卡片确认选择", 10, C.muted,
        {width = "100%", textAlign = "center", padding = 8})
    return Art.Root({Art.Safe(children)})
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
    local character, workplace = s.character or {}, s.workplace or {}
    local progress = {}
    for day = 1, s.maxDays do
        progress[#progress + 1] = UI.Panel {width = 34, height = 34, alignItems = "center", justifyContent = "center",
            backgroundColor = day == s.currentDay and C.yellow or (day < s.currentDay and C.lilac or C.paper),
            borderWidth = 2, borderColor = C.ink, children = {Art.Text(tostring(day), 13)}}
    end
    return Sheet("第 " .. s.currentDay .. " 天", "新的饭局，新的生存机会。", {
        UI.Panel {flexDirection = "row", flexWrap = "wrap", gap = 8, children = progress},
        UI.Panel {flexDirection = "row", alignItems = "center", gap = 16, children = {
            Art.Picture(Art.Character(character, true), {width = 86, height = 104}),
            UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, gap = 5, children = {
                Art.Text(character.name, 23, C.ink, {fontWeight = "bold"}),
                Art.Text(workplace.name, 13, C.muted),
                Art.Text("Lv." .. s.currentLevel .. " " .. GameLogic.GetLevelData(s.currentLevel).name, 14, C.purple),
            }}, Art.Badge(s.currentLevel, 58)}},
        Art.StatRow("今日预算", "¥" .. s.money),
        Art.StatRow("被优化次数", s.optimizeCount .. " / " .. s.maxOptimize, s.optimizeCount > 0 and C.red or C.muted),
        Art.Text((character.skill or "专属技能") .. " / " .. (character.skillDesc or ""), 13, C.muted),
        Art.Button("出发赴宴  →", function() GameLogic.StartDay(); Navigate(s.phase) end),
    })
end

function Screens.CreateRestDay()
    local s = GameLogic.State
    local messages = GameData.RestDayMessages
    return Sheet("今天，不上酒桌", "DAY " .. s.currentDay .. " / " .. s.maxDays .. " · 休息日", {
        Art.Picture(A.drinks.tea, {width = 110, height = 110, alignSelf = "center"}),
        Art.Text(messages[math.random(1, #messages)], 20, C.ink, {width = "100%", textAlign = "center"}),
        Art.Text("职级不变。偶尔离开饭局，也是生存策略。", 13, C.muted),
        Art.Button("好好休息，明天继续", function() GameLogic.EndRestDay(); Navigate(s.phase) end, true),
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
    return Sheet(labels[resultCache.result] or "饭局结算", "第 " .. s.currentDay .. " 天 · 饭局复盘", {
        UI.Panel {flexDirection = "row", alignItems = "center", gap = 12, children = {
            Art.Picture(Art.Character(s.character, true), {width = 82, height = 96}),
            Art.Badge(resultCache.before, 64), Art.Text("→", 26, C.purple), Art.Badge(resultCache.after, 72),
        }},
        Art.Text(resultCache.message, 23, colors[resultCache.result], {fontWeight = "bold", width = "100%"}),
        Art.Text("Lv." .. resultCache.before .. " " .. GameLogic.GetLevelData(resultCache.before).name .. "  →  Lv." ..
            resultCache.after .. " " .. GameLogic.GetLevelData(resultCache.after).name, 14, C.purple, {width = "100%"}),
        Art.Text((s --[[@as table]]).lastChoiceFeedback or "饭局结束，记得照顾好自己。", 13, C.muted),
        Art.Stats(s, true),
        Art.StatRow("被优化次数", s.optimizeCount .. " / " .. s.maxOptimize, s.optimizeCount > 0 and C.red or C.muted),
        Art.StatRow("剩余资金", "¥" .. s.money),
        Art.Button("收好工牌，继续  →", function() GameLogic.ProceedAfterResult(); Navigate(s.phase) end),
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
    local history = {Art.Text("每日手记 / CAREER LOG", 13, C.purple, {fontWeight = "bold"})}
    local resultNames = {promote = "升职", maintain = "维持", demote = "降级", optimized = "被优化", rest = "休息"}
    for _, item in ipairs(s.dayHistory) do
        history[#history + 1] = Art.StatRow("DAY " .. item.day .. " · " .. (resultNames[item.result] or item.result),
            "Lv." .. item.levelBefore .. " → " .. item.levelAfter)
    end
    local record = Art.Paper(history, {width = "100%", padding = 12, gap = 9})
    return Sheet(headline, description, {
        UI.Panel {flexDirection = "row", gap = 16, alignItems = "center", children = {
            Art.Picture(Art.Character(s.character, true), {width = 96, height = 114}),
            UI.Panel {flexGrow = 1, flexShrink = 1, flexBasis = 0, gap = 5, children = {
                Art.Text((s.character or {}).name, 21, C.ink, {fontWeight = "bold"}),
                Art.Text((s.workplace or {}).name, 13, C.muted),
                Art.Text("最终 Lv." .. s.currentLevel .. " " .. GameLogic.GetLevelData(s.currentLevel).name, 14, C.purple),
            }}, Art.Badge(s.currentLevel, 72)}},
        Art.Paper({Art.Text("本次获得称号", 11, C.yellow),
            Art.Text(title.name, 26, C.paper, {fontWeight = "bold", width = "100%"}),
            Art.Text(title.desc, 13, C.paper, {width = "100%"})}, {width = "100%"}, true),
        Art.StatRow("起始职级", "Lv." .. s.startLevel .. " " .. GameLogic.GetLevelData(s.startLevel).name),
        Art.StatRow("完成酒局", s.banquetCount .. " 场"),
        Art.StatRow("被优化次数", s.optimizeCount .. " 次"),
        Art.StatRow("总花费", "¥" .. s.totalSpent),
        Art.StatRow("最高连续升职", s.maxConsecutive .. " 次"), record,
        Art.Button("重新入职  →", function() resultCache = {}; GameLogic.Reset(); Navigate("menu") end),
    })
end

-- 图鉴是纯 UI 支路；不重置 State、不掺入开局选择、不展示隐藏对手。
function Screens.CreateArtGallery()
    local entries = {}
    for _, item in ipairs(GameData.Characters) do
        if item.id ~= "pu_rui_si" then
            entries[#entries + 1] = Art.Paper({
                Art.Picture(Art.Character(item), {width = "100%", height = 220}),
                Art.Text(item.name, 18, C.ink, {fontWeight = "bold"}),
                Art.Text(item.skillDesc or item.desc, 12, C.muted, {width = "100%"}),
            }, {padding = 12, minWidth = 0})
        end
    end
    for _, item in ipairs(GameData.Restaurants) do
        entries[#entries + 1] = Art.Paper({Art.Picture(Art.Background(item), {width = "100%", height = 132, backgroundFit = "cover"}),
            Art.Text(item.name, 16), Art.Text("TIER " .. item.tier, 11, C.purple)}, {padding = 10, minWidth = 0})
    end
    local grid = UI.SimpleGrid {width = "100%", minColumnWidth = 210, gap = 14, children = entries}
    return Art.Root({Art.Safe({Heading("ART BOOK / 美术图鉴", "桌边人物与风景", "这里只翻阅美术，不改变游戏进度。"),
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, children = {
            UI.Panel {width = "100%", padding = 18, children = {grid}}}},
        Art.Button("返回主菜单", function() Navigate("menu") end, true, {margin = 12}),
    })})
end

function Screens.Shutdown()
    Playing.Shutdown()
    onScreenChange_ = nil
    resultCache = {}
end

return Screens
