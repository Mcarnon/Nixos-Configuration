-- 深浅色模式的唯一判定入口（neovim 侧）。
--
-- 为什么不用 cyberdream 自带的 variant = "auto"：它只看 `vim.o.background`，
-- 而这个值只是 nvim 启动时向终端查询一次的结果。foot 切深浅色走的是
-- SIGUSR1/SIGUSR2（见 modules/home/desktop/clavis/bin/clavis-theme-sync），
-- 不会通知已经在跑的客户端，所以 nvim 启动之后 background 就一直是旧值，
-- 切完主题再回到 nvim 还是一片相反的配色。
--
-- 这里直接读 Clavis 的 config.json —— 和 foot-themed / clavis-theme-sync 用的是
-- 同一个 source of truth。autocmds.lua 在重新聚焦时重读，所以切完主题切回
-- nvim 就能立刻跟上。读不到时（没装 Clavis、root、临时 nvim）mode() 返回 nil，
-- variant() 退回 nvim 启动时探测到的 vim.o.background，深色仍然是手选的 muted。

local M = {}

--- config.json 的路径，优先级与 foot-themed 一致。
---@return string
local function config_path()
    local override = vim.env.CLAVIS_CONFIG
    if override and override ~= "" then
        return override
    end
    local xdg = vim.env.XDG_CONFIG_HOME
    if xdg and xdg ~= "" then
        return xdg .. "/clavis/config.json"
    end
    return (vim.env.HOME or "") .. "/.config/clavis/config.json"
end

--- Clavis 当前的 theme.mode。
---@return "light"|"dark"|nil
function M.mode()
    local file = io.open(config_path(), "r")
    if not file then
        return nil
    end
    local ok, data = pcall(vim.json.decode, file:read("*a"))
    file:close()
    if not ok or type(data) ~= "table" then
        return nil
    end
    local mode = data.theme and data.theme.mode
    if mode == "light" or mode == "dark" then
        return mode
    end
    return nil
end

--- 对应的 cyberdream variant：深色沿用原来手选的 muted，亮色用 light。
---@return "light"|"muted"
function M.variant()
    local mode = M.mode()
    if mode == "light" then
        return "light"
    elseif mode == "dark" then
        return "muted"
    end
    -- 读不到 Clavis：信 nvim 启动时的终端探测结果，深色保持 muted。
    if vim.o.background == "light" then
        return "light"
    end
    return "muted"
end

return M
