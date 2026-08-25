# nixosSystem 聚合：唯一入口，roles/ 按需开关
{
  imports = [
    ./core
    ./desktop
    ./hardware
    ./network
    ./security
    ./i18n
  ];
}
