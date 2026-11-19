# Node.js 工具链（用户级）。
#
# 版本钉 `nodejs_24`（当前 LTS）而不是 `nodejs` 别名：别名会跟着 nixpkgs 升级跳
# 版本（现在解析到 24，将来会是 26），项目的 `engines` / lockfile 会某天突然不
# 满足。要换版本只改这一行。
#
# 包管理器同时给 pnpm 和 yarn：本仓库自己打包 dsh-tui / splayer 走的是 pnpm，
# 本地版本对齐能少一类「本地能装、打包失败」的差异。
#
# 项目级版本仍然建议 direnv + nix-direnv（modules/home/shell/tools.nix 已启用）
# 在项目里 `use flake` / `use nix`，别指望全局 node 满足所有项目。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    nodejs_24 # node + npm（LTS）；npm 自带的 corepack 也在这里
    corepack # 再装一份独立包：Node 25 起不再随发行版附带 corepack
    pnpm
    yarn-berry # 仍有 yarn 项目，corepack 之外留个直接能跑的命令

    typescript # tsc
    typescript-language-server # 编辑器 LSP
    eslint # 既有项目最常见的 lint
    prettier # 既有项目最常见的格式化

    # 原生模块（better-sqlite3 / sharp / node-gyp）需要一套构建链
    gcc # 提供 cc / c++
    gnumake
    pkg-config
    python3 # node-gyp 要求 python3
  ];
}
