-- ============================================================================
-- 2D UI 中的立体骰子：空间旋转 → 透视投影 → NanoVG 贴图三角形。
-- 不创建 3D Scene / Camera / PhysicsWorld。UI 框架管理分辨率及渲染事件。
-- 六面始终绑定立方体，翻滚和结果共用同一模型，不随机换面或切回平面图。
-- ============================================================================
local Widget = require("urhox-libs/UI/Core/Widget")
local ImageCache = require("urhox-libs/UI/Core/ImageCache")

local Dice3D = {}
local SHAKE_TIME, FLIGHT_TIME, SETTLE_TIME = 0.20, 0.94, 0.52
local CAMERA_DISTANCE, GRID = 5.8, 4

-- 面图路径直接读取本地资源；crop 是原图有效区域，不修改原始图片。
local SKINS = {
    classic = {
        color = { 234, 231, 224 }, edge = { 255, 255, 255 },
        faces = {
            { path = "image/classic_1_20261008125953.png", crop = { 37, 34, 438, 443 } },
            { path = "image/classic_2_20261008125948.png", crop = { 51, 58, 410, 397 } },
            { path = "image/classic_3_20261008125951.png", crop = { 52, 57, 408, 399 } },
            { path = "image/classic_4_20261008125952.png", crop = { 46, 54, 419, 406 } },
            { path = "image/classic_5_20261008125952.png", crop = { 52, 61, 406, 397 } },
            { path = "image/classic_6_20261008125952.png", crop = { 40, 40, 430, 430 } },
        },
    },
    cthulhu = {
        color = { 32, 61, 51 }, edge = { 149, 178, 128 },
        faces = {
            { path = "image/cthulhu_1_20261008125827.png", crop = { 20, 25, 473, 463 } },
            { path = "image/cthulhu_2_20261008125827.png", crop = { 21, 21, 469, 467 } },
            { path = "image/cthulhu_3_20261008125829.png", crop = { 16, 33, 481, 443 } },
            { path = "image/cthulhu_4_20261008125827.png", crop = { 20, 25, 472, 458 } },
            { path = "image/cthulhu_5_20261008125827.png", crop = { 16, 24, 477, 457 } },
            { path = "image/cthulhu_6_20261008125833.png", crop = { 25, 25, 462, 460 } },
        },
    },
}

-- normal / right / up 构成每个面的固定局部坐标，相对面之和为 7。
-- 摄像机在 -Z 看原点，+Y 向上；朝结果面的姿态先对齐再叠展示倾角。
local FACES = {
    { normal = Vector3(0, 0, -1), right = Vector3(1, 0, 0), up = Vector3(0, 1, 0), align = Quaternion.IDENTITY },
    { normal = Vector3(1, 0, 0), right = Vector3(0, 0, 1), up = Vector3(0, 1, 0), align = Quaternion(90, Vector3.UP) },
    { normal = Vector3(0, 1, 0), right = Vector3(1, 0, 0), up = Vector3(0, 0, 1), align = Quaternion(-90, Vector3.RIGHT) },
    { normal = Vector3(0, -1, 0), right = Vector3(1, 0, 0), up = Vector3(0, 0, -1), align = Quaternion(90, Vector3.RIGHT) },
    { normal = Vector3(-1, 0, 0), right = Vector3(0, 0, -1), up = Vector3(0, 1, 0), align = Quaternion(-90, Vector3.UP) },
    { normal = Vector3(0, 0, 1), right = Vector3(-1, 0, 0), up = Vector3(0, 1, 0), align = Quaternion(180, Vector3.UP) },
}
local PRESENTATION = Quaternion(-18, 26, 0)

---@class Dice3DProps : WidgetProps
---@field styleKey? string
---@field onRollStart? fun(result: integer)
---@field onLand? fun()
---@field onComplete? fun(result: integer)

---@class Dice3DView : Widget
---@field props Dice3DProps
---@field orientation_ Quaternion
---@field startOrientation_ Quaternion
---@field settleOrientation_ Quaternion
---@field targetOrientation_ Quaternion
---@field result_ integer
---@field timer_ number
---@field phase_ string
---@field offsetX_ number
---@field elevation_ number
---@field scaleX_ number
---@field scaleY_ number
---@field turnsX_ number
---@field turnsY_ number
---@field turnsZ_ number
---@field assetsChecked_ boolean
---@field alive_ boolean
local Dice3DView = Widget:Extend("Dice3DView")

---@param props Dice3DProps
function Dice3DView:Init(props)
    Widget.Init(self, props)
    self.orientation_ = PRESENTATION
    self.startOrientation_ = PRESENTATION
    self.settleOrientation_ = PRESENTATION
    self.targetOrientation_ = PRESENTATION
    self.result_, self.timer_, self.phase_ = 1, 0, "idle"
    self.offsetX_, self.elevation_ = 0, 0
    self.scaleX_, self.scaleY_ = 1, 1
    self.turnsX_, self.turnsY_, self.turnsZ_ = 0, 0, 0
    self.assetsChecked_, self.alive_ = false, true
end

function Dice3DView:IsRolling()
    return self.phase_ ~= "idle"
end

--- result 可省略随机掷，也可以传入业务层 / 服务器已决定的结果。
---@param result? integer
---@return boolean
function Dice3DView:Roll(result)
    if not self.alive_ or self:IsRolling() then return false end
    if result ~= nil and (result < 1 or result > 6 or result % 1 ~= 0) then return false end
    self.result_ = result or math.random(1, 6)
    self.startOrientation_ = self.orientation_
    self.targetOrientation_ = PRESENTATION * FACES[self.result_].align
    self.turnsX_ = math.random(680, 940)
    self.turnsY_ = math.random(900, 1160)
    self.turnsZ_ = math.random(-270, 270)
    self.timer_, self.phase_ = 0, "shake"
    print("[Dice3D] 开始翻滚: " .. tostring(self.props.styleKey) .. "，结果=" .. self.result_)
    if self.props.onRollStart then self.props.onRollStart(self.result_) end
    return true
end

local function Smooth(t)
    return t * t * (3 - 2 * t)
end

function Dice3DView:ApplyPose()
    local t = self.timer_
    if self.phase_ == "shake" then
        local p = t / SHAKE_TIME
        self.offsetX_ = math.sin(p * math.pi * 6) * 7 * math.sin(p * math.pi)
        self.elevation_ = 0
        self.orientation_ = Quaternion(0, 0, self.offsetX_ * 0.9) * self.startOrientation_
    elseif self.phase_ == "flight" then
        local p = t / FLIGHT_TIME
        local spin = 1 - (1 - p) ^ 2
        self.orientation_ = Quaternion(self.turnsX_ * spin, self.turnsY_ * spin, self.turnsZ_ * spin) * self.startOrientation_
        self.offsetX_ = math.sin(p * math.pi * 2) * 22 * (1 - p)
        self.elevation_ = math.sin(p * math.pi) * 0.66 + math.abs(math.sin(p * math.pi * 3)) * 0.13 * (1 - p)
        self.scaleX_, self.scaleY_ = 1 + self.elevation_ * 0.12, 1 + self.elevation_ * 0.12
    elseif self.phase_ == "settle" then
        local p = t / SETTLE_TIME
        self.orientation_ = self.settleOrientation_:Slerp(self.targetOrientation_, Smooth(p))
        self.offsetX_ = 0
        self.elevation_ = math.abs(math.sin(p * math.pi * 2)) * 0.13 * (1 - p) ^ 2
        local squash = math.sin(p * math.pi * 4) * (1 - p) ^ 2 * 0.09
        self.scaleX_, self.scaleY_ = 1 + squash, 1 - squash
    end
end

---@param dt number
function Dice3DView:Update(dt)
    if not self.alive_ or self.phase_ == "idle" or dt <= 0 then return end
    -- 累积真实时间并跨阶段结转，低帧率也不会卡死或丢失完成回调。
    local remaining = dt
    while remaining > 0 and self.phase_ ~= "idle" do
        local duration = self.phase_ == "shake" and SHAKE_TIME or (self.phase_ == "flight" and FLIGHT_TIME or SETTLE_TIME)
        local step = math.min(remaining, math.max(0, duration - self.timer_))
        self.timer_ = self.timer_ + step
        remaining = remaining - step
        self:ApplyPose()
        if self.timer_ >= duration - 0.000001 then
            self.timer_ = 0
            if self.phase_ == "shake" then
                self.phase_ = "flight"
            elseif self.phase_ == "flight" then
                self.settleOrientation_ = self.orientation_
                self.phase_ = "settle"
                if self.props.onLand then self.props.onLand() end
            else
                self.phase_ = "idle"
                self.orientation_ = self.targetOrientation_
                self.offsetX_, self.elevation_ = 0, 0
                self.scaleX_, self.scaleY_ = 1, 1
                print("[Dice3D] 落定: " .. self.result_)
                if self.props.onComplete then self.props.onComplete(self.result_) end
            end
        end
    end
end

---@class DiceProjectedPoint
---@field x number
---@field y number

---@param v Vector3
---@param cx number
---@param cy number
---@param pixels number
---@return DiceProjectedPoint
local function Project(v, cx, cy, pixels)
    local perspective = CAMERA_DISTANCE / (CAMERA_DISTANCE + v.z)
    return { x = cx + v.x * pixels * perspective, y = cy - v.y * pixels * perspective }
end

---@param nvg NVGContextWrapper
---@param points DiceProjectedPoint[]
local function Polygon(nvg, points)
    nvgBeginPath(nvg)
    nvgMoveTo(nvg, points[1].x, points[1].y)
    for i = 2, #points do nvgLineTo(nvg, points[i].x, points[i].y) end
    nvgClosePath(nvg)
end

-- 用 (u,v)→屏幕三角形的仿射矩阵贴图。4×4 分片近似透视，保留 UI 的祖先变换。
---@param nvg NVGContextWrapper
---@param image integer
---@param crop number[]
---@param p DiceProjectedPoint[]
---@param uv number[][]
local function TextureTriangle(nvg, image, crop, p, uv)
    local u0, v0 = uv[1][1], uv[1][2]
    local du1, dv1 = uv[2][1] - u0, uv[2][2] - v0
    local du2, dv2 = uv[3][1] - u0, uv[3][2] - v0
    local det = du1 * dv2 - du2 * dv1
    local dx1, dy1 = p[2].x - p[1].x, p[2].y - p[1].y
    local dx2, dy2 = p[3].x - p[1].x, p[3].y - p[1].y
    local a, c = (dx1 * dv2 - dx2 * dv1) / det, (dx2 * du1 - dx1 * du2) / det
    local b, d = (dy1 * dv2 - dy2 * dv1) / det, (dy2 * du1 - dy1 * du2) / det
    if math.abs(a * d - b * c) < 0.01 then return end
    nvgSave(nvg)
    -- 扩大内部三角形 0.35px 抑制抗锯齿细缝，面的外轮廓有实体底色兜底。
    local cx, cy = (p[1].x + p[2].x + p[3].x) / 3, (p[1].y + p[2].y + p[3].y) / 3
    local expanded = {}
    for i = 1, 3 do
        local dx, dy = p[i].x - cx, p[i].y - cy
        local len = math.sqrt(dx * dx + dy * dy)
        expanded[i] = { x = p[i].x + dx / math.max(len, 1) * 0.35, y = p[i].y + dy / math.max(len, 1) * 0.35 }
    end
    Polygon(nvg, expanded)
    nvgTransform(nvg, a, b, c, d, p[1].x - a * u0 - c * v0, p[1].y - b * u0 - d * v0)
    nvgFillPaint(nvg, nvgImagePattern(nvg, -crop[1] / crop[3], -crop[2] / crop[4], 512 / crop[3], 512 / crop[4], 0, image, 1))
    nvgFill(nvg)
    nvgRestore(nvg)
end

---@param nvg NVGContextWrapper
function Dice3DView:Render(nvg)
    local l = self:GetAbsoluteLayout()
    if l.w <= 0 or l.h <= 0 then return end
    local skin = SKINS[self.props.styleKey or "classic"] or SKINS.classic
    local side = math.min(l.w, l.h)
    local pixels = side * 0.245
    local cx, floorY = l.x + l.w * 0.5, l.y + l.h * 0.88
    local cy = l.y + l.h * 0.59 - self.elevation_ * side * 0.31
    local centerX = cx + self.offsetX_ * side / 280

    nvgSave(nvg)
    nvgIntersectScissor(nvg, l.x, l.y, l.w, l.h)
    -- 阴影不参与旋转；升空后更小、更淡。
    nvgBeginPath(nvg)
    nvgEllipse(nvg, cx + self.offsetX_ * 0.4, floorY, side * (0.29 - self.elevation_ * 0.10), side * 0.034)
    nvgFillColor(nvg, nvgRGBA(0, 0, 0, math.floor(72 - self.elevation_ * 48)))
    nvgFill(nvg)

    local visible = {}
    for index, face in ipairs(FACES) do
        local normal = self.orientation_ * face.normal
        -- 带透视的背面剔除，不能只用 normal.z 判断。
        if normal.z * CAMERA_DISTANCE + 1 < -0.01 then
            visible[#visible + 1] = { index = index, normal = normal }
        end
    end
    table.sort(visible, function(a, b) return a.normal.z > b.normal.z end)

    for _, item in ipairs(visible) do
        local face = FACES[item.index]
        local texture = skin.faces[item.index]
        local image = ImageCache.Get(texture.path) --[[@as integer]]
        if image == 0 and not self.assetsChecked_ then print("[Dice3D] 贴图暂未就绪: " .. texture.path) end
        ---@type DiceProjectedPoint[][]
        local points = {}
        for row = 0, GRID do
            points[row + 1] = {}
            for col = 0, GRID do
                local localPoint = face.normal + face.right * (2 * col / GRID - 1) + face.up * (1 - 2 * row / GRID)
                local rotated = self.orientation_ * localPoint
                local scaled = Vector3(rotated.x * self.scaleX_, rotated.y * self.scaleY_, rotated.z)
                points[row + 1][col + 1] = Project(scaled, centerX, cy, pixels)
            end
        end
        local corners = { points[1][1], points[1][GRID + 1], points[GRID + 1][GRID + 1], points[GRID + 1][1] }
        -- 图片透明圆角处由实体面补齐，避免看穿立方体。
        Polygon(nvg, corners)
        nvgFillColor(nvg, nvgRGBA(skin.color[1], skin.color[2], skin.color[3], 255))
        nvgFill(nvg)
        if image > 0 then
            for row = 1, GRID do
                for col = 1, GRID do
                    local u0, v0, u1, v1 = (col - 1) / GRID, (row - 1) / GRID, col / GRID, row / GRID
                    TextureTriangle(nvg, image, texture.crop, { points[row][col], points[row][col + 1], points[row + 1][col + 1] }, { {u0,v0}, {u1,v0}, {u1,v1} })
                    TextureTriangle(nvg, image, texture.crop, { points[row][col], points[row + 1][col + 1], points[row + 1][col] }, { {u0,v0}, {u1,v1}, {u0,v1} })
                end
            end
        end
        -- 静态贴图之外的动态方向光：侧面更暗，翻滚时明暗随面法线改变。
        local n = item.normal
        local brightness = 0.69 + math.max(0, -0.35 * n.x + 0.65 * n.y - 0.67 * n.z) * 0.30
        Polygon(nvg, corners)
        nvgFillColor(nvg, nvgRGBA(0, 0, 0, math.floor((1 - brightness) * 255)))
        nvgFill(nvg)
        nvgStrokeColor(nvg, nvgRGBA(skin.edge[1], skin.edge[2], skin.edge[3], 92))
        nvgStrokeWidth(nvg, 0.9)
        nvgStroke(nvg)
    end
    self.assetsChecked_ = true
    nvgRestore(nvg)
end

function Dice3DView:Destroy()
    self.alive_ = false
    self.phase_ = "idle"
    -- 图片由共享 ImageCache 管理，不释放其他控件可能仍使用的图片。
    Widget.Destroy(self)
end

---@param props Dice3DProps
---@return Dice3DView
function Dice3D.View(props)
    return Dice3DView:new(props)
end

return Dice3D
