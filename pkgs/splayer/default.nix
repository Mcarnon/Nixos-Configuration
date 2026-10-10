# splayer — 旧版 SPlayer（SPlayer-Dev/SPlayer，v3.1.1 是 2026-06-05 归档前的最后一版）。
#
# 为什么不用 nixpkgs 的 `splayer-next`：
#   SPlayer-Next 是同一个 SPlayer-Dev 组织的后继项目（README 标题就是
#   "Successor to SPlayer"），旧仓库已于 2026-07-17 归档成只读，官方让用户迁到
#   SPlayer-Next。本包是**故意**装归档版的旧 SPlayer 界面，不是漏更新。
#
# 为什么解包官方 AppImage，而不是像 splayer-next 那样从源码构建：
#   归档仓库的 pnpm 10 lockfile 要在 electron 43 上重编 better-sqlite3 和三个
#   Rust napi 模块（external-media-integration / taskbar-lyric / tools），收益仅是
#   electron 版本，而官方已经发布了 x86_64 AppImage —— 里面就是 electron 41.7.1 +
#   resources/app.asar + 官方编好的 native 模块，与官方 Linux 发行版一致。
#   代价是 electron 没打 nix 补丁：靠 autoPatchelfHook 补解释器/RPATH，并在 wrapper
#   里补上 Wayland 装饰 / IME 参数。
#   实测内存/性能与官方一致：解包发生在 build 期，运行时不做 FUSE 挂载。
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  copyDesktopItems,
  squashfsTools,
  zlib,
  alsa-lib,
  at-spi2-atk,
  at-spi2-core,
  atk,
  cairo,
  cups,
  dbus,
  gtk3,
  libGL,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXtst,
  libdrm,
  libgbm,
  libxcb,
  libxkbcommon,
  libxshmfence,
  nspr,
  nss,
  pango,
  makeWrapper,
  makeDesktopItem,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "splayer";
  version = "3.1.1";

  # hash 直接取自上游 electron-builder 的 latest-linux.yml（AppImage 同一份产物，
  # 与 latest.yml / .deb / .rpm 一起签名发布）；FOD 自己会校验。
  src = fetchurl {
    url = "https://github.com/SPlayer-Dev/SPlayer/releases/download/v${finalAttrs.version}/splayer-${finalAttrs.version}-x86_64.AppImage";
    hash = "sha512-9rjZM+X9F/XGhaEXKl6cL6BHu/uZmQjiGY9r0Y2wzkF9InhV2ys0+OMzSYdEMFOXWzXybmQzCl20/7niJ/qg0Q==";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems # 装下面的 desktopItems
    makeWrapper
    squashfsTools # unsquashfs：type-2 AppImage 解包用
    zlib # AppImage runtime 自己链的 libz.so.1

    # electron 41 主程序的运行时依赖。NixOS 没有 /usr/lib，缺一个就是 ldd 的
    # "not found"；autoPatchelfHook 会自动收集这些包的 lib 目录。
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    dbus
    gtk3
    libGL
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXi
    libXrandr
    libXtst
    libdrm
    libgbm
    libxcb
    libxkbcommon
    libxshmfence
    nspr
    nss
    pango
  ];

  dontConfigure = true;
  # 注意：这里不能写 dontBuild —— 那会让 nix 整个跳过 buildPhase，而解包正是
  # buildPhase 干的活（曾经因此静默地什么也没解就进了 installPhase）。
  # AppImage 不是 nix 认识的压缩格式，unpackPhase 会报 "do not know how to unpack"；
  # 解包由 buildPhase 的 --appimage-extract 自己做。
  dontUnpack = true;
  # 手动 patch（见 installPhase）：默认的 postFixup 递归 patch 会把 electron 41 自带的
  # libffmpeg/libEGL/libGLESv2 也换成 nixpkgs 的版本，那套 .so 是和 electron 41 配套的。
  dontAutoPatchelf = true;
  dontPatchELF = true;
  dontStrip = true; # 内置 .asar / .node 模块不需要 strip

  buildPhase = ''
    runHook preBuild
    # store 里的文件是 444，chmod 改不了；cp 又会把源 mode 一起带过来，所以拷完
    # 必须自己把 u+w 加回来 —— 否则 patchelf 的 O_RDWR open 会 "Permission denied"。
    cp "$src" app.AppImage
    chmod u+w,+x app.AppImage
    # AppImage 的 ELF 解释器是 /lib64/ld-linux-x86-64.so.2，构建沙箱里没有这个路径，
    # 不改解释器就是 "cannot execute: required file not found"。
    # --libs 要显式给：auto-patchelf 只在自己的搜索路径里找，不读 NIX_LDFLAGS 的 -L。
    auto-patchelf --paths app.AppImage --libs "${zlib}/lib"
    # type-2 AppImage：--appimage-extract 走 squashfs，不需要 FUSE。显式 cd 进子目录，
    # 避免 runtime 把 squashfs-root 写到只读的 store 路径旁边。
    mkdir extract
    cd extract
    ./../app.AppImage --appimage-extract
    cd ..
    if [ ! -d extract/squashfs-root ]; then
      echo "splayer: AppImage 解包失败（没看到 extract/squashfs-root）" >&2
      exit 1
    fi
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    # 这个 AppImage 的 AppDir 是 electron-builder 的新布局：electron 应用本体直接
    # 平铺在根目录（SPlayer + resources/ + locales/ + *.pak + lib*.so），
    # usr/ 里只有 bin、图标和 desktop —— 不是老式的 usr/lib/<pkgname>/。
    root=extract/squashfs-root
    if [ ! -x "$root/SPlayer" ] || [ ! -d "$root/resources" ]; then
      echo "splayer: AppDir 布局不符合预期（缺 SPlayer 或 resources/）" >&2
      echo "splayer: 顶层内容：$(ls "$root")" >&2
      exit 1
    fi

    mkdir -p "$out/share/splayer"
    cp -r "$root/." "$out/share/splayer/"
    # AppRun / .DirIcon 是 AppImage 自己的启动器，用不到
    rm -f "$out/share/splayer/AppRun" "$out/share/splayer/.DirIcon"

    # 上游图标：electron-builder 从 public/icons/favicon-512x512.png 生成后放在根目录
    install -Dm644 "$root/SPlayer.png" "$out/share/icons/hicolor/512x512/apps/splayer.png"

    # 只补 electron 主程序和 crashpad handler 的解释器/RPATH。--no-recurse 是关键：
    # 同目录下的 libffmpeg.so / libEGL.so / libGLESv2.so / libvulkan.so.1 是 electron 41
    # 配套的那一套，递归替换会出 ABI 问题，它们继续按 $ORIGIN 加载即可。
    # electron 自己那套 libffmpeg.so 就在同一个目录里，必须把它加进搜索路径 ——
    # 否则 auto-patchelf 会去 store 里找一个 nixpkgs 的 ffmpeg 顶替它。
    addAutoPatchelfSearchPath "$out/share/splayer"
    autoPatchelf --no-recurse -- \
      "$out/share/splayer/SPlayer" \
      "$out/share/splayer/chrome_crashpad_handler"

    # 兜底检查：store 里没有 /lib、/usr/lib，任何 "not found" 都意味着这个包根本起不
    # 来。与其装出一个点开就报错的东西，不如构建时就炸。
    missing=""
    for exe in "$out/share/splayer/SPlayer" "$out/share/splayer/chrome_crashpad_handler"; do
      for lib in $(ldd "$exe" 2>/dev/null | grep "not found" | awk '{print $1}'); do
        case " $missing " in
          *" $lib "*) ;;
          *) missing="$missing $lib" ;;
        esac
      done
    done
    if [ -n "$missing" ]; then
      echo "splayer: 以下运行时库没解析到，需要加进 nativeBuildInputs：$missing" >&2
      exit 1
    fi

    makeWrapper "$out/share/splayer/SPlayer" "$out/bin/splayer" \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true --wayland-text-input-version=3}}" \
      --inherit-argv0

    runHook postInstall
  '';

  # 上游 electron-builder 的 appId 是 com.imsyy.splayer；旧版不单独发布 .desktop，
  # 这里自己生成，顺带把 orpheus 协议注册上（和上游 linux.desktop.entry 一致）。
  desktopItems = [
    (makeDesktopItem {
      name = "com.imsyy.splayer";
      desktopName = "SPlayer";
      exec = "splayer %U";
      terminal = false;
      type = "Application";
      icon = "splayer";
      startupWMClass = "SPlayer";
      comment = "A cross-platform music player with word-by-word lyrics, desktop lyrics and streaming server support";
      categories = [
        "AudioVideo"
        "Audio"
        "Music"
      ];
      mimeTypes = [ "x-scheme-handler/orpheus" ];
      extraConfig.X-KDE-Protocols = "orpheus";
    })
  ];

  meta = {
    description = "旧版 SPlayer：网易云音乐第三方客户端（逐字歌词/桌面歌词/流媒体服务）";
    homepage = "https://github.com/SPlayer-Dev/SPlayer";
    license = lib.licenses.agpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "splayer";
  };
})
