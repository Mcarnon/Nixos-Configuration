{ config, lib, ... }:
{
  i18n.defaultLocale = "en_US.UTF-8";

  # Uncomment to support a Chinese locale as well:
  # i18n.supportedLocales = [
  #   "en_US.UTF-8/UTF-8"
  #   "zh_CN.UTF-8/UTF-8"
  # ];

  time.timeZone = config.my.timeZone;

  console.keyMap = "us";
}
