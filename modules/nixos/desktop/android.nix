# Android 开发环境（系统会话级）。
#
# SDK/工具链包由 Home Manager 安装；这里只负责把路径写进 PAM session。
# 不能只写在 home.sessionVariables：NixOS 下后者只进入登录 shell，
# 从 niri 桌面图标启动的 GUI 工具拿不到 ANDROID_HOME。
{
  pkgs,
  ...
}:
let
  androidHome = "${pkgs.androidSdk}/libexec/android-sdk";
in
{
  environment.sessionVariables = {
    ANDROID_HOME = androidHome;
    ANDROID_SDK_ROOT = androidHome;
    ANDROID_NDK_ROOT = "${androidHome}/ndk-bundle";
    JAVA_HOME = "${pkgs.jdk21.home}";

    # AGP 默认会从 Maven 解包一个未经过 Nix patch 的 aapt2，
    # 在 NixOS 上会因动态链接器路径无法运行；强制使用 SDK 内已修补的版本。
    GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidHome}/build-tools/37.0.0/aapt2";
  };
}
