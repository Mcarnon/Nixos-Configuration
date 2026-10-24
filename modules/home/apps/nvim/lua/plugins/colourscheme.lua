-- cyberdream 自带的 light variant 在白底上有几档角色对比度不足，直接用会重演
-- foot 亮色那套「字贴背景」的问题（实测 vs foot 亮色背景 #f6fafe）：
--
--   grey    #7b8496  3.6:1  —— Comment / LineNr / FoldColumn / InlayHint
--   orange  #d17c00  3.0:1  —— Number / Keyword / Label / WarningMsg
--   cyan    #008c99  3.8:1  —— Boolean / PreProc / FloatTitle / markdownCode
--   yellow  #997b00  3.9:1  —— DiagnosticWarn / Question
--   pink    #f40064  4.0:1  —— Constant / Special
--   green   #008b0c  4.3:1  —— String / Added
--   magenta #d100bf  4.5:1  —— Statement
--
-- 只覆盖 light 这几项（同色相压暗到 ≥ 4.5:1）；深色 muted 在 #0f1417 上是够的，
-- 保持插件原样。
local light_fixes = {
    grey = "#5b636e", -- 5.8:1
    orange = "#a35f00", -- 4.8:1
    cyan = "#00707d", -- 5.5:1
    yellow = "#7d6500", -- 5.4:1
    pink = "#c2004d", -- 5.9:1
    green = "#00730a", -- 5.8:1
    magenta = "#b0009f", -- 6.0:1
}

-- 亮色下选中/引用等「彩字叠在选中底色上」的场景。插件默认的 bg_highlight
-- (#acacac) 做底色时彩字只剩 1.4–2.8:1；这里单独给这些组换一块浅底，选区在
-- 白底上仍能看出（~1.3:1），彩字回到 3.6–4.6:1。bg_highlight 本身不动，否则
-- 分割线/浮窗边框/ColorColumn 也会跟着淡到看不见。
local light_selection = "#d3dde3"

return {
    "scottmckendry/cyberdream.nvim",
    dev = true,
    lazy = false,
    priority = 1000,
    opts = function()
        -- 深/浅色跟 Clavis 的 theme.mode 走，判定逻辑见 core/theme.lua。
        local mode = require("core.theme").mode()
        if mode then
            -- 同时把 nvim 自己的 background 对上，供没有 cyberdream 扩展的插件
            -- 和内置高亮使用。
            vim.o.background = mode
        end
        return {
            variant = require("core.theme").variant(),
            transparent = true,
            italic_comments = true,
            hide_fillchars = true,
            terminal_colors = false,
            -- cache 只会缓存一份产物，切深浅色后要先渲染旧缓存、再弹「正在重建」
            -- 提示；theme.setup() 本身很快，关掉换来即时且无提示的切换。
            cache = false,
            borderless_pickers = true,
            colors = {
                light = light_fixes,
            },
            overrides = function(c)
                -- 在 setup 时判色，而不是在 opts 里闭包捕获：运行中切主题会重新
                -- 调到这里（见 core/autocmds.lua 的 FocusGained）。
                local now = require("core.theme").mode()
                local is_light = now == "light" or (now == nil and vim.o.background == "light")

                local h = {
                    CursorLine = { bg = c.bg },
                    CursorLineNr = { fg = c.magenta },
                }
                if is_light then
                    -- LineNr = blend(bg_highlight, fg, 0.9)（九成取灰），亮色下只有
                    -- 2.6:1；行号本身是文字，压到 #68707a（4.8:1）。
                    h.LineNr = { fg = "#68707a" }
                    h.Visual = { bg = light_selection }
                    h.VisualNOS = { bg = light_selection }
                    h.MatchParen = { fg = c.pink, bg = light_selection }
                    h.Substitute = { fg = c.red, bg = light_selection }
                    -- PmenuSel 一起换，否则选中行（#acacac）和匹配片段的底色
                    -- 会不一致。
                    h.PmenuSel = { fg = c.fg, bg = light_selection }
                    h.PmenuMatch = { fg = c.cyan, bg = light_selection }
                    h.PmenuMatchSel = { fg = c.cyan, bg = light_selection }
                    h.BlinkCmpMenuSelection = { bg = light_selection }
                    h.LspReferenceText = { bg = light_selection }
                    h.LspReferenceRead = { bg = light_selection }
                    h.LspReferenceWrite = { bg = light_selection }
                    h.HopPreview = { fg = c.fg, bg = light_selection }
                end
                return h
            end,
        }
    end,
}
