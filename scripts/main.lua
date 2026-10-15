-- ============================================================================
-- 《酒桌文化》v1.2.1 - 职场应酬生存模拟器
-- 主入口文件
-- ============================================================================

local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local Screens = require("UI.Screens")
local DiceDemo = require("UI.DiceDemo")

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
        backgroundColor = { 246, 239, 220, 255 },
        children = {
            UI.Label { text = "酒桌文化", fontSize = 36, fontWeight = "bold",
                fontColor = { 30, 28, 34, 255 } },
            UI.Label { text = "正在准备饭局…", fontSize = 15, fontColor = { 106, 96, 99, 255 } },
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
        fonts = {
            { family = "sans", weights = {
                normal = "Fonts/MiSans-Regular.ttf",
            } },
            { family = "menu", weights = {
                normal = "Fonts/NotoSansSC-Black.ttf",
                bold = "Fonts/NotoSansSC-Black.ttf",
            } },
        },
        scale = UI.Scale.DEFAULT,
    })

    -- 注册屏幕切换回调
    Screens.SetOnScreenChange(SwitchScreen)

    -- 先显示加载页，等预下载完成再进主菜单
    ShowLoadingScreen()
    SubscribeToEvent("Update", "HandleAssetWait")
    cache:ObserveDownloads(
        function(completed, total, bytes) end,
        function(bytes) EnterMenu() end
    )
    print("[酒桌文化] v1.2.1 启动，等待资源就绪")
end

function Stop()
    Screens.Shutdown()
    UI.Shutdown()
end

-- ============================================================================
-- 屏幕切换
-- ============================================================================
function SwitchScreen(screenName)
    print("[Screen] → " .. tostring(screenName))

    ---@type any
    local newRoot = nil

    if screenName == "menu" then
        newRoot = Screens.CreateMainMenu()
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
    elseif screenName == "dice_demo" then
        newRoot = DiceDemo.CreateScreen(function() SwitchScreen("menu") end)
    end

    if newRoot then
        UI.SetRoot(newRoot, true)
        uiRoot_ = newRoot
    end
end
