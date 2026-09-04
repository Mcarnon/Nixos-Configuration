-- mpv-hook.lua — 视频壁纸播放时提取第一帧缩略图给 Noctalia 做 Material You 配色。
--
-- 参考 NyxNiri 的 mpv-hook.lua 实现。
-- 由 mpvpaper --script= 加载，监听 file-loaded 事件：
--   1. 用 ffmpeg 截取视频第 1 帧为 JPEG 缩略图
--   2. 通过 noctalia msg wallpaper-set 设置缩略图为 Noctalia 壁纸
--   3. Noctalia 自动从缩略图提取 Material You 配色
--
-- 依赖：ffmpeg（系统 PATH）

local mp = require "mp"
local utils = require "mp.utils"

local cache_dir = os.getenv("HOME") .. "/.cache/noctalia/mpvpaper"

-- 确保缓存目录存在
local function ensure_dir(path)
    utils.subprocess({
        args = { "mkdir", "-p", path },
        playback_only = false,
    })
end

-- 计算文件 MD5 作为缩略图文件名（避免重复提取）
local function md5_file(path)
    local result = utils.subprocess({
        args = { "md5sum", path },
        playback_only = false,
    })
    if result.status == 0 then
        return string.match(result.stdout, "^([a-f0-9]+)")
    end
    return nil
end

-- 提取第一帧缩略图并设置给 Noctalia
local function extract_and_set_thumbnail(video_path)
    ensure_dir(cache_dir)

    local hash = md5_file(video_path)
    if not hash then
        mp.msg.warn("mpv-hook: failed to compute md5 for " .. video_path)
        return
    end

    local thumb_path = cache_dir .. "/" .. hash .. ".jpg"

    -- 如果缩略图已存在则跳过
    local f = io.open(thumb_path, "r")
    if f then
        f:close()
    else
        -- ffmpeg 截取第 1 帧（-ss 00:00:01 取第 1 秒，避免黑帧）
        local result = utils.subprocess({
            args = {
                "ffmpeg", "-y",
                "-ss", "00:00:01",
                "-i", video_path,
                "-vframes", "1",
                "-q:v", "2",
                thumb_path,
            },
            playback_only = false,
        })
        if result.status ~= 0 then
            mp.msg.warn("mpv-hook: ffmpeg thumbnail failed: " .. (result.stderr or ""))
            return
        end
    end

    -- 设置缩略图为 Noctalia 壁纸（触发 Material You 配色提取）
    utils.subprocess({
        args = { "noctalia", "msg", "wallpaper-set", thumb_path },
        playback_only = false,
    })
    mp.msg.info("mpv-hook: thumbnail set for color sync: " .. thumb_path)
end

-- 监听文件加载事件
mp.register_event("file-loaded", function()
    local path = mp.get_property("path")
    if path then
        -- 异步提取，不阻塞视频播放
        mp.add_timeout(0.5, function()
            extract_and_set_thumbnail(path)
        end)
    end
end)
