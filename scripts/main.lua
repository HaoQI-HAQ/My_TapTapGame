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
            } }
        },
        scale = UI.Scale.DEFAULT,
    })

    -- 注册屏幕切换回调
    Screens.SetOnScreenChange(SwitchScreen)

    -- 显示主菜单
    SwitchScreen("menu")

    print("[酒桌文化] v1.2.1 启动成功")
end

function Stop()
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
