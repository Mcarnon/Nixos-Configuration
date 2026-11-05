# Android 应用开发工具（用户级）。
#
# SDK 由 pkgs/android-sdk 在 Nix store 中组装；ANDROID_HOME 等环境变量
# 在 modules/nixos/desktop/android.nix 中以系统会话变量注入，确保 GUI 也能读取。
{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    android-studio # IDE（自带 JBR；SDK 复用下方 ANDROID_HOME，不再是 android-studio-full）
    androidSdk # sdkmanager / adb / emulator / platform / build-tools / NDK
    jdk21 # Gradle / sdkmanager 的 JDK
    gradle # 全局 Gradle；项目通常用 wrapper
    kotlin # kotlinc / kotlin REPL
    scrcpy # USB / 无线设备投屏与控制
  ];
}
