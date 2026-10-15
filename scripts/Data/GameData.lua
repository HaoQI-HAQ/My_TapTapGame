-- ============================================================================
-- 《酒桌文化》v1.2.1 数据层
-- 职级系统 / 角色(含起始职级) / 场景Tier解锁 / 酒水 / 对话事件
-- ============================================================================

local GameData = {}

-- ============================================================================
-- 职级阶梯 (Lv.1 ~ Lv.8)
-- ============================================================================
GameData.Levels = {
    { lv = 1, name = "实习生",   icon = "🆕", money = 500,    tierMax = 1 },
    { lv = 2, name = "打工牛马", icon = "🐴", money = 2000,   tierMax = 1 },
    { lv = 3, name = "专业岗",   icon = "🎨", money = 8000,   tierMax = 2 },
    { lv = 4, name = "小组长",   icon = "📋", money = 8000,   tierMax = 2 },
    { lv = 5, name = "项目主管", icon = "🧚", money = 15000,  tierMax = 3 },
    { lv = 6, name = "部门总监", icon = "📊", money = 30000,  tierMax = 3 },
    { lv = 7, name = "副总/合伙人", icon = "👴", money = 50000, tierMax = 4 },
    { lv = 8, name = "老板",     icon = "👔", money = 100000, tierMax = 4 },
}

--- 根据职级获取可用Tier范围
function GameData.GetTierRange(level)
    -- Lv.1-2 → Tier 1; Lv.3-4 → Tier 1-2; Lv.5-6 → Tier 2-3; Lv.7-8 → Tier 3-4
    if level <= 2 then return 1, 1
    elseif level <= 4 then return 1, 2
    elseif level <= 6 then return 2, 3
    else return 3, 4
    end
end

-- ============================================================================
-- 职场环境
-- ============================================================================
GameData.Workplaces = {
    { id = "internet", name = "互联网大厂",  icon = "💻", desc = "内卷、黑话多、变化快", difficulty = 3 },
    { id = "state",    name = "国企/央企",   icon = "🏛️", desc = "讲究排面、论资排辈", difficulty = 4 },
    { id = "realestate", name = "地产/基建", icon = "🏗️", desc = "豪爽、酒量是入场券", difficulty = 5 },
    { id = "finance",  name = "金融/银行",   icon = "🏦", desc = "高端、保守、重关系", difficulty = 4 },
    { id = "media",    name = "广告/传媒",   icon = "🎬", desc = "创意至上、social能力", difficulty = 3 },
    { id = "game",     name = "游戏公司",    icon = "🎮", desc = "宅、社恐多、加班狠", difficulty = 2 },
    { id = "startup",  name = "创业公司",    icon = "📱", desc = "画饼、鸡血、不确定性", difficulty = 2 },
    { id = "factory",  name = "制造业/工厂", icon = "🏭", desc = "实在、直来直去", difficulty = 2 },
}

-- ============================================================================
-- 角色 (含起始职级和特殊能力)
-- ============================================================================
GameData.Characters = {
    {
        id = "intern", name = "实习生", icon = "🆕", startLevel = 1,
        portrait = "image/Art/Characters/intern_portrait.png",
        illustration = "image/Art/Characters/intern_normal.png",
        skill = "萌新光环", skillDesc = "每场酒局第一次失误不扣好感",
        desc = "什么都不懂但什么都想学", difficulty = 1,
    },
    {
        id = "worker", name = "打工牛马", icon = "🐴", startLevel = 2,
        portrait = "image/Art/Characters/worker_portrait.png",
        illustration = "image/Art/Characters/worker_normal.png",
        skill = "已读不回", skillDesc = "每场可跳过一次强制对话",
        desc = "社畜本畜，卑微但有梗", difficulty = 2,
    },
    {
        id = "designer", name = "设计师", icon = "🎨", startLevel = 3,
        portrait = "image/Art/Characters/designer_portrait.png",
        illustration = "image/Art/Characters/designer_normal.png",
        skill = "五彩斑斓黑", skillDesc = "对话中可解锁隐藏创意选项",
        desc = "需求听不懂但画得出来", difficulty = 3,
    },
    {
        id = "dev", name = "程序员", icon = "🔧", startLevel = 3,
        portrait = "image/Art/Characters/dev_portrait.png",
        illustration = "image/Art/Characters/dev_normal.png",
        skill = "Debug", skillDesc = "清醒度下降速度减半",
        desc = "高薪但社恐，喝多了可能写代码", difficulty = 3,
    },
    {
        id = "sales", name = "销售冠军", icon = "🎤", startLevel = 3,
        portrait = "image/Art/Characters/sales_portrait.png",
        illustration = "image/Art/Characters/sales_normal.png",
        skill = "话术王", skillDesc = "好感度增减幅度×1.5",
        desc = "能把梳子卖给和尚", difficulty = 3,
    },
    {
        id = "hr", name = "HR", icon = "📊", startLevel = 3,
        portrait = "image/Art/Characters/hr_portrait.png",
        illustration = "image/Art/Characters/hr_normal.png",
        skill = "背调", skillDesc = "每场可查看对方一个隐藏属性",
        desc = "笑里藏刀，信息就是武器", difficulty = 3,
    },
    {
        id = "pm", name = "产品经理", icon = "📋", startLevel = 4,
        portrait = "image/Art/Characters/pm_portrait.png",
        illustration = "image/Art/Characters/pm_normal.png",
        skill = "需求变更", skillDesc = "每场可推翻一次已选选项重选",
        desc = "永远在改需求", difficulty = 4,
    },
    {
        id = "veteran", name = "老油条", icon = "👴", startLevel = 5,
        portrait = "image/Art/Characters/veteran_portrait.png",
        illustration = "image/Art/Characters/veteran_normal.png",
        skill = "太极推手", skillDesc = "每场可将一个负面效果转嫁",
        desc = "在公司活了二十年的终极形态", difficulty = 5,
    },
    {
        id = "boss", name = "区域老板", icon = "👔", startLevel = 7,
        portrait = "image/Art/Characters/boss_portrait.png",
        illustration = "image/Art/Characters/boss_normal.png",
        skill = "我请客", skillDesc = "可强制买单提升全场面子值+20",
        desc = "🔥 Hard Mode：仅2天，决胜局面对普老板·普瑞斯",
        difficulty = 6,
        isRegionalBoss = true,
    },
}

-- ============================================================================
-- 餐厅场景（按 Tier 分组）
-- ============================================================================
GameData.Restaurants = {
    -- Tier 1：接地气
    { id = "bbq",       name = "路边烧烤摊", tier = 1, icon = "🏮", costPerPerson = 80,  faceBonus = 2,  background = "image/Art/Backgrounds/bg_bbq.png", desc = "塑料凳子配扎啤" },
    { id = "flyshop",   name = "苍蝇小馆",   tier = 1, icon = "🍜", costPerPerson = 60,  faceBonus = 1,  background = "image/Art/Backgrounds/bg_flyshop.png", desc = "菜好吃但环境简陋" },
    { id = "hotpot",    name = "街边火锅",   tier = 1, icon = "🫕", costPerPerson = 120, faceBonus = 5,  background = "image/Art/Backgrounds/bg_hotpot.png", desc = "火锅面前人人平等" },
    { id = "dapaidang", name = "大排档",     tier = 1, icon = "🍲", costPerPerson = 100, faceBonus = 3,  background = "image/Art/Backgrounds/bg_dapaidang.png", desc = "热闹、嘈杂、适合吹牛" },
    -- Tier 2：体面
    { id = "biz_chinese", name = "商务中餐厅", tier = 2, icon = "🍱", costPerPerson = 400, faceBonus = 12, background = "image/Art/Backgrounds/bg_biz_chinese.png", desc = "包间、转盘、标配商务宴" },
    { id = "izakaya",     name = "日料居酒屋", tier = 2, icon = "🍣", costPerPerson = 350, faceBonus = 10, background = "image/Art/Backgrounds/bg_izakaya.png", desc = "清酒配刺身，文艺范儿" },
    { id = "steak",       name = "西餐牛排馆", tier = 2, icon = "🥩", costPerPerson = 500, faceBonus = 14, background = "image/Art/Backgrounds/bg_steak.png", desc = "刀叉礼仪也是考验" },
    { id = "craftbeer",   name = "精酿酒吧",   tier = 2, icon = "🍺", costPerPerson = 250, faceBonus = 8,  background = "image/Art/Backgrounds/bg_craftbeer.png", desc = "年轻人的主场" },
    -- Tier 3：高端
    { id = "private",  name = "私房菜会所",      tier = 3, icon = "🏯", costPerPerson = 1500, faceBonus = 25, background = "image/Art/Backgrounds/bg_private.png", desc = "低调有排面，懂的都懂" },
    { id = "michelin", name = "米其林餐厅",      tier = 3, icon = "🦞", costPerPerson = 2000, faceBonus = 30, background = "image/Art/Backgrounds/bg_michelin.png", desc = "分子料理配红酒" },
    { id = "omakase",  name = "高端日料Omakase", tier = 3, icon = "🐟", costPerPerson = 1800, faceBonus = 28, background = "image/Art/Backgrounds/bg_omakase.png", desc = "主厨决定吃什么" },
    -- Tier 4：离谱
    { id = "fivestar", name = "五星酒店中餐", tier = 4, icon = "🏰", costPerPerson = 3000, faceBonus = 40, background = "image/Art/Backgrounds/bg_fivestar.png", desc = "顶级排面" },
    { id = "yacht",    name = "游艇晚宴",     tier = 4, icon = "🛥️", costPerPerson = 5000, faceBonus = 50, background = "image/Art/Backgrounds/bg_yacht.png", desc = "海上没信号" },
}

-- ============================================================================
-- 酒水类型（图标仅表示种类，不是任何品牌的瓶身或商标）
-- ============================================================================
GameData.DrinkTypes = {
    { id = "beer",     name = "啤酒",     icon = "🍺", faceBase = 1, soberHit = 10, thumbnail = "image/Art/Drinks/icon_drink_beer.png" },
    { id = "wine",     name = "红酒",     icon = "🍷", faceBase = 3, soberHit = 15, thumbnail = "image/Art/Drinks/icon_drink_wine.png" },
    { id = "baijiu",   name = "白酒",     icon = "🥃", faceBase = 4, soberHit = 25, thumbnail = "image/Art/Drinks/icon_drink_baijiu.png" },
    { id = "cocktail", name = "鸡尾酒",   icon = "🍸", faceBase = 2, soberHit = 12, thumbnail = "image/Art/Drinks/icon_drink_cocktail.png" },
    { id = "foreign",  name = "洋酒",     icon = "🥂", faceBase = 5, soberHit = 20, thumbnail = "image/Art/Drinks/icon_drink_foreign.png" },
    { id = "sake",     name = "清酒/梅酒", icon = "🍶", faceBase = 2, soberHit = 8,  thumbnail = "image/Art/Drinks/icon_drink_sake.png" },
    { id = "tea",      name = "以茶代酒", icon = "🫖", faceBase = 0, soberHit = 0,  thumbnail = "image/Art/Drinks/icon_drink_tea.png" },
}

-- ============================================================================
-- 酒品牌
-- ============================================================================
GameData.DrinkBrands = {
    baijiu = {
        { name = "飞天茅台",     price = 3000, face = 30, special = "国企场景好感+10" },
        { name = "五粮液",       price = 1200, face = 20, special = "百搭之选" },
        { name = "国窖1573",     price = 1500, face = 22, special = "品味不错" },
        { name = "剑南春",       price = 500,  face = 12, special = "务实之选" },
        { name = "牛栏山二锅头", price = 30,   face = 2,  special = "可能触发隐藏线" },
        { name = "江小白",       price = 50,   face = 3,  special = "年轻人没毛病" },
    },
    wine = {
        { name = "拉菲正牌", price = 8000, face = 35, special = "谁买谁是大哥" },
        { name = "奔富Bin389", price = 500, face = 15, special = "商务标配" },
        { name = "长城干红",  price = 80,  face = 5,  special = "实在人" },
        { name = "张裕解百纳", price = 100, face = 6,  special = "国产之光" },
    },
    foreign = {
        { name = "人头马XO",   price = 2500,  face = 28, special = "经典选择" },
        { name = "路易十三",   price = 20000, face = 50, special = "大日子？" },
        { name = "麦卡伦18年", price = 3000,  face = 30, special = "懂威士忌" },
        { name = "芝华士12年", price = 300,   face = 10, special = "入门不丢面" },
        { name = "杰克丹尼",   price = 200,   face = 8,  special = "年轻人的选择" },
    },
    beer = {
        { name = "青岛大绿棒子", price = 10,  face = 1,  special = "烧烤绝配" },
        { name = "百威",         price = 15,  face = 2,  special = "中规中矩" },
        { name = "科罗娜",       price = 25,  face = 4,  special = "塞柠檬那个" },
        { name = "精酿IPA",      price = 60,  face = 6,  special = "你们喝的都是水" },
        { name = "修道院啤酒",   price = 150, face = 10, special = "啤酒里的贵族" },
    },
    cocktail = {
        { name = "长岛冰茶", price = 80,  face = 5, special = "后劲大" },
        { name = "莫吉托",   price = 60,  face = 4, special = "清爽" },
        { name = "马天尼",   price = 100, face = 7, special = "007同款" },
        { name = "B52轰炸机", price = 90,  face = 6, special = "一口闷" },
    },
    sake = {
        { name = "獭祭纯米大吟酿", price = 400, face = 12, special = "日料绝配" },
        { name = "梅乃宿梅酒",     price = 150, face = 6,  special = "女士最爱" },
        { name = "久保田千寿",     price = 300, face = 10, special = "中规中矩" },
    },
    tea = {
        { name = "铁观音",  price = 50,  face = 3, special = "养生达人" },
        { name = "大红袍",  price = 200, face = 8, special = "茶也能有排面" },
        { name = "普洱",    price = 80,  face = 4, special = "稳重" },
    },
}

-- 品牌只复用酒类图标；显示时必须保留 thumbnailLabel，不能冒充品牌立绘。
for _, drinkType in ipairs(GameData.DrinkTypes) do
    for _, brand in ipairs(GameData.DrinkBrands[drinkType.id] or {}) do
        brand.thumbnail = drinkType.thumbnail
        brand.thumbnailKind = "drink_type"
        brand.thumbnailLabel = drinkType.name .. "类型示意（非品牌立绘）"
        brand.desc = brand.special .. " · " .. brand.thumbnailLabel
    end
end

-- ============================================================================
-- 推荐菜：需求表21项 + 本轮明确补足的解酒水果 fruit（第22项）
-- 未量化的“解酒”在本轮设清醒+5；fruit ¥80/清醒+10，所有Tier均可选。
-- ============================================================================
GameData.Dishes = {
    { id = "kebab", name = "烤串拼盘", tier = 1, price = 80, face = 0, vibe = 5, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_kebab.png" },
    { id = "crayfish", name = "小龙虾", tier = 1, price = 120, face = 0, vibe = 8, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_crayfish.png" },
    { id = "peanuts", name = "花生毛豆", tier = 1, price = 20, face = 0, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_peanuts.png" },
    { id = "lamb", name = "烤全羊", tier = 1, price = 580, face = 15, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_lamb.png" },
    { id = "beerduck", name = "啤酒鸭", tier = 1, price = 68, face = 0, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_beerduck.png" },
    { id = "hotpot", name = "牛油火锅", tier = 1, price = 200, face = 0, vibe = 10, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_hotpot.png" },
    { id = "cucumber", name = "拍黄瓜", tier = 1, price = 18, face = 0, vibe = 0, sober = 5, thumbnail = "image/Art/Dishes/icon_dish_cucumber.png" },
    { id = "kungpao", name = "宫保鸡丁", tier = 2, price = 68, face = 0, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_kungpao.png" },
    { id = "squirrelfish", name = "松鼠桂鱼", tier = 2, price = 288, face = 10, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_squirrelfish.png" },
    { id = "sashimi", name = "刺身拼盘", tier = 2, price = 380, face = 12, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_sashimi.png" },
    { id = "wagyu", name = "和牛烧肉", tier = 2, price = 480, face = 15, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_wagyu.png" },
    { id = "tomahawk", name = "战斧牛排", tier = 2, price = 588, face = 18, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_tomahawk.png" },
    { id = "beerplatter", name = "精酿拼盘", tier = 2, price = 158, face = 0, vibe = 12, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_beerplatter.png" },
    { id = "buddhajump", name = "佛跳墙", tier = 3, price = 888, face = 20, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_buddhajump.png" },
    { id = "lobster", name = "龙虾刺身", tier = 3, price = 1280, face = 25, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_lobster.png" },
    { id = "matsutake", name = "松茸炖鸡", tier = 3, price = 680, face = 18, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_matsutake.png" },
    { id = "cabbage", name = "开水白菜", tier = 3, price = 388, face = 30, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_cabbage.png" },
    { id = "omakase", name = "Omakase寿司", tier = 3, price = 1500, face = 28, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_omakase.png" },
    { id = "abalone", name = "鲍鱼捞饭", tier = 4, price = 1680, face = 35, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_abalone.png" },
    { id = "caviar", name = "鱼子酱", tier = 4, price = 2800, face = 40, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_caviar.png" },
    { id = "truffle", name = "白松露意面", tier = 4, price = 1980, face = 38, vibe = 0, sober = 0, thumbnail = "image/Art/Dishes/icon_dish_truffle.png" },
    { id = "fruit", name = "解酒水果", tier = 1, price = 80, face = 0, vibe = 0, sober = 10, allTiers = true, addedThisRound = true, desc = "本轮补足的第22道菜，清醒+10（最高100）", thumbnail = "image/Art/Dishes/icon_dish_fruit.png" },
}

-- 普通对手由所选餐厅Tier决定：T1同事、T2领导、T3-4客户。
GameData.Opponents = {
    { id = "colleague", name = "同事", minTier = 1, maxTier = 1, portrait = "image/Art/NPC/colleague_normal.png" },
    { id = "leader", name = "直属领导", minTier = 2, maxTier = 2, portrait = "image/Art/NPC/leader_normal.png" },
    { id = "client", name = "客户", minTier = 3, maxTier = 4, portrait = "image/Art/NPC/client_normal.png" },
}

-- 综合评分权重不变；低职级考核不要求买昂贵排面，按Lv分段公开门槛。
-- Lv1-2需45分，Lv3-4需48，Lv5-6需52，Lv7-8需55；+2仍需极佳属性。
GameData.PromotionRules = {
    exceptionalLevels = 2,
    scoreThresholds = { 45, 45, 48, 48, 52, 52, 55, 55 },
    minFavor = 70, minSober = 60, minDignity = 30, minPro = 5,
    description = "普通角色：达本职级晋升分数（Lv1-2:45/Lv3-4:48/Lv5-6:52/Lv7-8:55）、好感>=70、清醒>=60、尊严>=30、专业>=5，跨级晋升+2（最高Lv.8）；区域老板仍+1",
}

-- ============================================================================
-- 对话事件库
-- ============================================================================
GameData.DialogEvents = {
    -- 通用事件
    {
        id = "toast_general", type = "drink", trigger = "any",
        text = "对方举杯：\"来来来，走一个！\"",
        choices = {
            { text = "感情深一口闷！",         effects = { sober = -20, vibe = 10 } },
            { text = "我少喝点，明天还有会",   effects = { vibe = -5 } },
            { text = "我先干为敬，您随意",     effects = { favor = 5, sober = -15 } },
            { text = "我以茶代酒行不行？",     effects = { face = -10 } },
        },
    },
    {
        id = "brag_project", type = "dialogue", trigger = "any",
        text = "对方：\"听说你们那个项目最近搞得不错啊？\"",
        choices = {
            { text = "还行还行，团队给力",       effects = { favor = 3, dignity = 2 } },
            { text = "都是领导指导有方",         effects = { favor = 8, dignity = -5 } },
            { text = "一般般吧，也就年营收破亿", effects = { favor = -3, dignity = 5 } },
            { text = "别提了，天天加班快猝死了", effects = { vibe = 5, favor = -2 } },
        },
    },
    {
        id = "spill_wine", type = "accident", trigger = "any",
        text = "【突发】你不小心把酒洒在对方衣服上了！",
        choices = {
            { text = "疯狂道歉+掏钱赔",               effects = { money = -500, favor = -3 } },
            { text = "哥，这是财源广进的加持！",       effects = { favor = 5 } },
            { text = "假装没看见继续聊",               effects = { dignity = -10 } },
            { text = "我衣服更贵我先哭一会儿",         effects = { vibe = 5, favor = 2 } },
        },
    },
    {
        id = "phone_ring", type = "accident", trigger = "any",
        text = "【突发】你手机突然响了，来电显示是'老婆/对象'...",
        choices = {
            { text = "不好意思失陪一下（出去接）", effects = { vibe = -5 } },
            { text = "（直接挂掉）没事，继续聊",   effects = { favor = 3, dignity = -5 } },
            { text = "当着面接：亲爱的我在应酬...", effects = { vibe = 8, favor = -2 } },
            { text = "（静音）工作时间嘛",         effects = { favor = 5, dignity = -3 } },
        },
    },
    {
        id = "order_more", type = "dialogue", trigger = "any",
        text = "服务员过来问：\"还要加点什么吗？\"",
        choices = {
            { text = "再来一轮酒！",       effects = { sober = -15, vibe = 8, money = -200 } },
            { text = "来个果盘解解酒",     effects = { sober = 5, money = -80 } },
            { text = "不用了谢谢",         effects = { vibe = -3 } },
            { text = "有什么招牌甜品？",   effects = { vibe = 3, money = -100 } },
        },
    },
    {
        id = "gossip", type = "dialogue", trigger = "any",
        text = "对方神秘兮兮：\"跟你说个八卦，XX部门要裁员了...\"",
        choices = {
            { text = "真的假的？快说快说！",     effects = { favor = 5, dignity = -3 } },
            { text = "这种事还是少传为好",       effects = { dignity = 8, favor = -3 } },
            { text = "我早知道了（其实不知道）", effects = { pro = 3, favor = -2 } },
            { text = "有我的份吗哈哈",           effects = { vibe = 8, favor = 3 } },
        },
    },
    -- 互联网专属
    {
        id = "buzzword_align", type = "dialogue", trigger = "internet",
        text = "对方：\"这个需求我们需要拉齐一下认知颗粒度，你怎么看？\"",
        choices = {
            { text = "对，先建立闭环方法论",      effects = { pro = 5 } },
            { text = "说人话。",                   effects = { dignity = 10, favor = -5 } },
            { text = "我觉得可以先对齐一下OKR",   effects = { pro = 3 } },
            { text = "（掏出手机假装看消息）",     effects = {} },
        },
    },
    {
        id = "oc_overtime", type = "dialogue", trigger = "internet",
        text = "对方：\"你们组最近加班多不多？\"",
        choices = {
            { text = "还好，主要是热爱",           effects = { favor = 3, dignity = -8 } },
            { text = "多啊，不然怎么配得上工资",   effects = { vibe = 3 } },
            { text = "劳动法了解一下？",           effects = { dignity = 12, favor = -8 } },
            { text = "那不是加班，那是在摸鱼",     effects = { vibe = 8, favor = 2 } },
        },
    },
    -- 国企专属
    {
        id = "state_toast_order", type = "drink", trigger = "state",
        text = "领导端起酒杯看着你：\"小X，今天这酒先敬谁？\"",
        choices = {
            { text = "当然先敬领导您",       effects = { favor = 10, dignity = -5 } },
            { text = "按座位顺序来吧",       effects = { pro = 5 } },
            { text = "我先自罚三杯！",       effects = { sober = -30, vibe = 10, favor = 5 } },
            { text = "（紧张到手抖酒洒了）", effects = { vibe = -5, dignity = -3 } },
        },
    },
    {
        id = "state_leader_pressure", type = "dialogue", trigger = "state",
        text = "领导叹气：\"最近压力大啊，上面的任务一个接一个。\"",
        choices = {
            { text = "您太辛苦了，注意身体",       effects = { favor = 3 } },
            { text = "有您扛着我们才有今天",       effects = { favor = 8, dignity = -5 } },
            { text = "是啊，我看您头发都少了",     effects = { favor = -5, vibe = 8 } },
            { text = "先干为敬，祝您项目大卖",     effects = { sober = -10, vibe = 5 } },
        },
    },
    -- 地产专属
    {
        id = "realestate_drink_challenge", type = "drink", trigger = "realestate",
        text = "对方一拍桌子：\"小伙子，能喝不？来，一人三杯白的！\"",
        choices = {
            { text = "来！怕你不成！",       effects = { sober = -40, favor = 15, vibe = 10 } },
            { text = "我...我肝不太好",      effects = { favor = -10, dignity = 3 } },
            { text = "三杯算什么，六杯！",   effects = { sober = -60, favor = 20 } },
            { text = "哥先来，我随后跟上",   effects = { favor = 5, sober = -20 } },
        },
    },
    -- 金融专属
    {
        id = "finance_wine_knowledge", type = "dialogue", trigger = "finance",
        text = "对方晃着酒杯：\"你觉得这支酒怎么样？\"",
        choices = {
            { text = "单宁细腻，余味悠长",             effects = { pro = 8, face = 5 } },
            { text = "好喝！（其实没品出来）",         effects = { favor = 2 } },
            { text = "说实话和超市的差不多",           effects = { dignity = 10, favor = -8 } },
            { text = "配上松露应该更好",               effects = { face = 8, pro = 5 } },
        },
    },
    -- 游戏公司专属
    {
        id = "game_socially_awkward", type = "dialogue", trigger = "game",
        text = "全桌沉默了三秒，有人掏出手机看消息...",
        choices = {
            { text = "（也掏出手机打开游戏）",   effects = { vibe = -3, dignity = 5 } },
            { text = "你们最近在肝什么游戏？",   effects = { vibe = 8, favor = 3 } },
            { text = "来聊聊今年TGA预测？",      effects = { vibe = 10, pro = 3 } },
            { text = "不如我们来玩个桌游？",     effects = { vibe = 12 } },
        },
    },
    -- 醉酒事件
    {
        id = "drunk_truth", type = "drunk", trigger = "any",
        text = "【你有点上头了】嘴巴已经不太听使唤...",
        choices = {
            { text = "我跟你说...嗝...我超喜欢公司的...", effects = { favor = 5, dignity = -15 } },
            { text = "说实话...我想辞职很久了...",         effects = { favor = -20, dignity = 15 } },
            { text = "再来一杯！谁怕谁啊！",             effects = { sober = -25, vibe = 5 } },
            { text = "那个...那什么...就那个嘛...",       effects = {} },
        },
    },
    -- 摊牌事件
    {
        id = "final_showdown", type = "final", trigger = "any",
        text = "对方放下酒杯，认真看着你：\"今天跟你聊得不错，说正事吧...\"",
        choices = {
            { text = "（正襟危坐）您请说",       effects = { pro = 5, favor = 3 } },
            { text = "哈哈还以为你要表白呢",     effects = { vibe = 5, favor = -3 } },
            { text = "是关于晋升的事吗？",       effects = { favor = 2, dignity = 3 } },
            { text = "（深呼一口气）我准备好了", effects = { favor = 5 } },
        },
    },
    -- 广告传媒专属
    {
        id = "media_creative_pitch", type = "dialogue", trigger = "media",
        text = "对方：\"我有个big idea，现在的年轻人就喜欢那种...你懂的？\"",
        choices = {
            { text = "懂懂懂，Z世代嘛",         effects = { pro = 3, favor = 3 } },
            { text = "具体说说？我不太确定",     effects = { dignity = 5, favor = -2 } },
            { text = "对对对，颠覆性的！",       effects = { favor = 5, dignity = -3 } },
            { text = "我觉得你想说'出圈'",       effects = { pro = 5, vibe = 3 } },
        },
    },
}

-- ============================================================================
-- 最终Boss（沿用 HiddenBosses API；不加入9个可玩角色，也不是HR）
-- ============================================================================
GameData.HiddenBosses = {
    {
        id = "pu_rui_si", name = "普老板·普瑞斯", displayName = "普老板", icon = "👔",
        background = "image/Art/Backgrounds/bg_yacht.png", -- 兼容字段；当前场景仍使用所选餐厅背景
        portrait = "image/Art/NPC/pu_rui_si_normal.png",
        illustration = "image/Art/Characters/pu_rui_si_body.png",
        finalPortrait = "image/Art/NPC/pu_rui_si_final.png",
        portraits = {
            normal = "image/Art/NPC/pu_rui_si_normal.png",
            smile = "image/Art/Characters/pu_rui_si_smile.png",
            skeptical = "image/Art/Characters/pu_rui_si_skeptical.png",
            drunk = "image/Art/Characters/pu_rui_si_drunk.png",
            final = "image/Art/NPC/pu_rui_si_final.png",
        },
        isBoss = true,
        desc = "普瑞斯，称普老板；区域老板Day2必遇，普通角色最终日确定遇见",
    },
}

-- 普老板专属考核，按回合顺序轮换，不参与普通随机事件池。
GameData.BossEvents = {
    {
        id = "pu_strategy", type = "boss", trigger = "pu_rui_si",
        text = "普老板·普瑞斯没有碰酒杯：\"我看的是结果。给你一个季度，你怎么让这个项目活下来？\"",
        choices = {
            { text = "先核实现金流，给出里程碑和止损线", effects = { pro = 8, favor = 8, dignity = 3 } },
            { text = "您一句话，我保证翻十倍！", effects = { face = 5, favor = -8, pro = -3 } },
            { text = "今晚先喝好，业务明天说", effects = { sober = -15, favor = -10 } },
            { text = "先砍一半人，数据自然好看", effects = { dignity = -10, favor = -5 } },
        },
    },
    {
        id = "pu_accountability", type = "boss", trigger = "pu_rui_si",
        text = "普老板放下一份亏损报告：\"供应商、团队、客户都说不是自己的错。你来负责，第一步做什么？\"",
        choices = {
            { text = "先承担协调责任，公开事实和补救计划", effects = { pro = 6, favor = 7, dignity = 5 } },
            { text = "这是前任留下的锅", effects = { favor = -8, dignity = -5 } },
            { text = "替团队罚三杯，别再问了", effects = { sober = -35, vibe = 8, favor = -5 } },
            { text = "少汇报，先把报表修漂亮", effects = { favor = -10, dignity = -10 } },
        },
    },
    {
        id = "pu_boundary", type = "boss", trigger = "pu_rui_si",
        text = "普老板推开酒瓶：\"客户拿订单换一个不合规的承诺。今晚当着大家的面，你敢不敢拒绝？\"",
        choices = {
            { text = "守住合规底线，并给出可执行的替代方案", effects = { favor = 8, pro = 6, dignity = 8 } },
            { text = "先答应下来，以后再想办法", effects = { face = 8, favor = -10, dignity = -8 } },
            { text = "都听您的，我不做决定", effects = { favor = -5, pro = -3 } },
            { text = "用喝酒把这个问题糊弄过去", effects = { sober = -20, vibe = 5, favor = -8 } },
        },
    },
    {
        id = "pu_final_decision", type = "final", trigger = "pu_rui_si",
        text = "【终局】普老板·普瑞斯合上文件：\"酒量不是任命书。最后一次回答：坐上这个位置，你愿意对谁负责？\"",
        choices = {
            { text = "对团队、客户和结果负责，用承诺和事实接受考核", effects = { pro = 10, favor = 10, dignity = 5, bossApproval = true } },
            { text = "只要您满意，其他都不重要", effects = { favor = -8, dignity = -10 } },
            { text = "对明确的目标负责，也接受失败时的问责", effects = { pro = 8, favor = 8, dignity = 8, bossApproval = true } },
            { text = "先喝完这杯，就算您答应了！", effects = { sober = -30, favor = -15 } },
        },
    },
}

-- ============================================================================
-- 称号系统
-- ============================================================================
GameData.Titles = {
    { id = "fired_fast",  name = "00后整顿职场", desc = "最快被开除" },
    { id = "fish_king",   name = "摸鱼王",       desc = "年度摸鱼冠军" },
    { id = "drink_god",   name = "千杯不醉",     desc = "人形酒桶" },
    { id = "flatter_king", name = "舔王",        desc = "马屁之神" },
    { id = "money_power", name = "钞能力",       desc = "有钱为所欲为" },
    { id = "chaos",       name = "职场泥石流",   desc = "每次选最离谱的" },
    { id = "speed_run",   name = "速通之王",     desc = "最少酒局通关" },
    { id = "uncrowned",   name = "无冕之王",     desc = "差一步就是老板" },
}

-- ============================================================================
-- 结局评定文案 (5天用完时)
-- ============================================================================
GameData.FinalRatings = {
    { id = "almost",    label = "🥇 差一步",   title = "无冕之王",   msg = "再给你一天就好了..." },
    { id = "excellent", label = "🥈 表现优秀", title = "卷王潜力股", msg = "升得很快，可惜时间不够" },
    { id = "progress",  label = "🥉 有所进步", title = "稳步前进",   msg = "慢慢来，来日方长" },
    { id = "stuck",     label = "😐 原地踏步", title = "铁打的工位", msg = "你不会觉得混日子能升职吧？" },
    { id = "regress",   label = "📉 不升反降", title = "逆向升职",   msg = "恭喜，您成功让自己更卑微了" },
}

-- ============================================================================
-- 休息日文案
-- ============================================================================
GameData.RestDayMessages = {
    "你不会觉得每天都有酒局吧？今天摸鱼休息！",
    "难得清闲的一天，肝脏表示感谢。",
    "今天没人约饭，一个人吃了碗拉面回家了。",
    "同事约你但你假装没看到消息，继续躺平。",
}

return GameData
