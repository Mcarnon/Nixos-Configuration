# Role: home common — every user
{
  imports = [
    ../../modules/home/shell
    ../../modules/home/apps
  ];

  programs.git = {
    enable = true;
    settings.user = {
      name = "Mcarnon";
      email = "3273556124@qq.com";
    };
  };
}
