-- ============================================================================
-- 《酒桌文化》v1.3.0 - 职场应酬生存模拟器
-- 主入口文件
-- ============================================================================

local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local Screens = require("UI.Screens")
local DiceDemo = require("UI.DiceDemo")
local Art = require("UI.ArtTheme")
local Preferences = require("UI.Preferences")

-- ============================================================================
-- 全局变量
-- ============================================================================
---@type any
local uiRoot_ = nil

-- 资源就绪门：预览走网络下载，图片可能在脚本首帧尚未就绪。
-- UI 库的图片缓存会把首次加载失败永久缓存，所以必须先等下载完成再进主菜单。
local assetsReady_ = false
local waitElapsed_ = 0
local MAX_ASSET_WAIT = 12.0

local function ShowLoadingScreen()
    local root = UI.Panel {
        width = "100%", height = "100%",
        justifyContent = "center", alignItems = "center", gap = 12,
        backgroundColor = Art.C.paper,
        children = {
            Art.Title("酒桌文化", 30, Art.C.ink, {width = "100%", textAlign = "center"}),
            Art.Text("正在准备饭局…", 13, Art.C.muted, {width = "100%", textAlign = "center"}),
        },
    }
    UI.SetRoot(root, true)
    uiRoot_ = root
end

local function EnterMenu()
    if assetsReady_ then return end
    assetsReady_ = true
    print("[酒桌文化] 资源就绪，进入主菜单")
    SwitchScreen("menu")
end

---@param eventType string
---@param eventData UpdateEventData
function HandleAssetWait(eventType, eventData)
    if assetsReady_ then return end
    waitElapsed_ = waitElapsed_ + eventData["TimeStep"]:GetFloat()
    if waitElapsed_ >= MAX_ASSET_WAIT then
        print("[酒桌文化] 资源等待超时，先进入主菜单")
        EnterMenu()
    end
end

-- ============================================================================
-- 生命周期
-- ============================================================================

function Start()
    graphics.windowTitle = "酒桌文化"

    -- 初始化随机种子
    math.randomseed(os.time())

    -- 初始化 UI 系统
    UI.Init({
        theme = "default-dark",
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/NotoSansSC-Regular.ttf",
                bold = "Fonts/NotoSansSC-Bold.ttf",
            } },
            { family = "menu", weights = {
                normal = "Fonts/NotoSansSC-Bold.ttf",
                bold = "Fonts/NotoSansSC-Bold.ttf",
            } },
        },
        scale = UI.Scale.DEFAULT,
    })

    assetsReady_, waitElapsed_ = false, 0
    Preferences.Load()

    -- 注册屏幕切换回调
    Screens.SetOnScreenChange(SwitchScreen)

    -- 先显示加载页，等预下载完成再进主菜单
    ShowLoadingScreen()
    SubscribeToEvent("Update", "HandleAssetWait")
    cache:ObserveDownloads(
        function(completed, total, bytes) end,
        function(bytes) EnterMenu() end
    )
    print("[酒桌文化] v1.3.0 启动，等待资源就绪")
end

function Stop()
    Preferences.CloseAll()
    Screens.Shutdown()
    UI.Shutdown()
end

-- ============================================================================
-- 屏幕切换
-- ============================================================================
local screenTitles = {
    select_mode = "选择模式", select_workplace = "赴宴准备", select_character = "身份档案", day_start = "今日手记",
    rest_day = "休息日", select_restaurant = "挑选场地", select_drink_type = "挑选酒类",
    select_drink_brand = "挑选品牌", select_dish = "挑选菜品", playing = "饭局进行中",
    day_result = "散席复盘", game_over = "旅程结束", dice_demo = "摇骰练习", art_gallery = "人物图鉴",
}

local function WithNavigation(content, screenName)
    local returnButton = Art.Button("返回主菜单", function()
        local function leave()
            GameLogic.Reset()
            SwitchScreen("menu")
        end
        if screenName == "dice_demo" or screenName == "art_gallery" or screenName == "game_over" then
            leave()
        else
            Preferences.ConfirmReturn(leave)
        end
    end, true, {id = "return_to_menu", width = 112, minHeight = 40, paddingVertical = 6, paddingHorizontal = 8, fontSize = 11})
    local settings = Art.Button("设置", function() Preferences.ShowSettings() end, true,
        {id = "open_settings", width = 64, minHeight = 40, paddingVertical = 6, paddingHorizontal = 8, fontSize = 11})
    local toolbar = Art.Safe({UI.Panel {width = "100%", paddingHorizontal = 12, paddingVertical = 6,
        flexDirection = "row", alignItems = "center", gap = 8, backgroundColor = Art.C.dark, children = {
            Art.Text(screenTitles[screenName] or "酒桌文化", 11, Art.C.paper,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, maxLines = 1}), returnButton, settings,
        }}}, {height = "auto", flexShrink = 0, backgroundColor = Art.C.dark})
    content:SetStyle({height = "auto", flexGrow = 1, flexBasis = 0, flexShrink = 1, minHeight = 0})
    return UI.Panel {width = "100%", height = "100%", children = {toolbar, content}}
end

function SwitchScreen(screenName)
    print("[Screen] → " .. tostring(screenName))
    Preferences.CloseAll()

    ---@type any
    local newRoot = nil

    if screenName == "menu" then
        newRoot = Screens.CreateMainMenu()
    elseif screenName == "select_mode" then
        newRoot = Screens.CreateModeSelect()
    elseif screenName == "select_workplace" then
        newRoot = Screens.CreateWorkplaceSelect()
    elseif screenName == "select_character" then
        newRoot = Screens.CreateCharacterSelect()
    elseif screenName == "day_start" then
        newRoot = Screens.CreateDayStart()
    elseif screenName == "rest_day" then
        newRoot = Screens.CreateRestDay()
    elseif screenName == "select_restaurant" then
        newRoot = Screens.CreateRestaurantSelect()
    elseif screenName == "select_drink_type" then
        newRoot = Screens.CreateDrinkTypeSelect()
    elseif screenName == "select_drink_brand" then
        newRoot = Screens.CreateDrinkBrandSelect()
    elseif screenName == "select_dish" then
        newRoot = Screens.CreateDishSelect()
    elseif screenName == "playing" then
        newRoot = Screens.CreateGameScreen()
    elseif screenName == "day_result" then
        newRoot = Screens.CreateDayResult()
    elseif screenName == "game_over" then
        newRoot = Screens.CreateGameOver()
    elseif screenName == "art_gallery" then
        newRoot = Screens.CreateArtGallery()
    elseif screenName == "dice_demo" then
        newRoot = DiceDemo.CreateScreen(function() SwitchScreen("menu") end)
    end

    if newRoot then
        if screenName ~= "menu" then newRoot = WithNavigation(newRoot, screenName) end
        UI.SetRoot(newRoot, true)
        uiRoot_ = newRoot
    end
end
