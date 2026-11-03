# Nix 托管的 Android SDK：命令行工具、模拟器与常用 API 一起固定版本。
#
# SDK Manager 会把 SDK 下载到 $HOME，和 NixOS 的声明式环境容易漂移。
# 这里在 Nix store 里组装一套只读 SDK，并通过 ANDROID_HOME 暴露给
# Gradle；需要新 API/构建工具时改这里再 switch。
{
  androidenv,
}:
(androidenv.composeAndroidPackages {
  # 命令行工具 / 平台工具 / 模拟器跟随 nixpkgs 中固定的 Android repo。
  cmdLineToolsVersion = "latest";
  toolsVersion = "latest";
  platformToolsVersion = "latest";

  # 覆盖当前主流项目：API 35、36，以及仓库中最新平台。
  # 显式带上 37.0.0 是为了让 GRADLE_OPTS 里的 aapt2 覆盖路径保持稳定。
  buildToolsVersions = [
    "35.0.0"
    "36.0.0"
    "37.0.0"
  ];
  platformVersions = [
    "35"
    "36"
    "37.1"
  ];

  # 模拟器 + 一个 x86_64 Google APIs 系统镜像（当前平台没有镜像时，
  # composeAndroidPackages 会自动选用有镜像的 API 版本）。
  includeEmulator = true;
  includeSystemImages = true;
  systemImageTypes = [ "google_apis" ];
  abiVersions = [ "x86_64" ];

  # 原生开发常用组件。
  includeCmake = true;
  cmakeVersions = [ "latest" ];
  includeNDK = true;
  ndkVersions = [ "latest" ];

  useGoogleAPIs = true;
  includeSources = false;
  extraLicenses = [ "android-sdk-preview-license" ];
}).androidsdk
