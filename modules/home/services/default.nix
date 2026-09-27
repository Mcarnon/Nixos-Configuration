{
  imports = [
    # 暂时禁用 Miyu（排查桌面外壳时先把它从会话里摘掉）。
    # 恢复只需去掉这行注释；overlay 里的 pkgs.miyu 和 .#miyu 都还在。
    # ./miyu.nix
  ];
}
