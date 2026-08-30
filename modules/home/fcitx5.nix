# Fcitx5 home-manager config — full port of shorin's Arch config:
#   * config — hotkeys + behaviour
#   * classicui.conf — vertical candidate list + default theme
#   * pinyin/punctuation/chttrans/notifications — addon behaviour
#   * rime — default.custom.yaml + rime_ice.custom.yaml overrides
# System-level fcitx5 (addons, wayland frontend, dbus) lives in
# locales/default.nix + locales/zh-cn.nix. RIME_USER_DIR is set there too.
{
  config,
  pkgs,
  lib,
  ...
}:

{
  # classicui: vertical candidate list (default theme — no runtime theme
  # generator here, so we use the stock theme).
  xdg.configFile."fcitx5/conf/classicui.conf".text = ''
    # 垂直候选列表
    Vertical Candidate List=True
    # 使用鼠标滚轮翻页
    WheelForPaging=True
    # 字体
    Font="Noto Sans CJK SC 11"
    # 菜单字体
    MenuFont="Noto Sans CJK SC 10"
    # 托盘字体
    TrayFont="Noto Sans CJK SC 10"
    # 托盘标签轮廓颜色
    TrayOutlineColor=#000000
    # 托盘标签文本颜色
    TrayTextColor=#ffffff
    # 优先使用文字图标
    PreferTextIcon=False
    # 在图标中显示布局名称
    ShowLayoutNameInIcon=True
    # 使用输入法的语言来显示文字
    UseInputMethodLanguageToDisplayText=True
    # 主题
    Theme=default
    # 深色主题
    DarkTheme=default-dark
    # 跟随系统浅色/深色设置
    UseDarkTheme=False
    # 当被主题和桌面支持时使用系统的重点色
    UseAccentColor=True
    # 在 X11 上针对不同屏幕使用单独的 DPI
    PerScreenDPI=False
    # 固定 Wayland 的字体 DPI
    ForceWaylandDPI=0
    # 在 Wayland 下启用分数缩放
    EnableFractionalScale=True
  '';

  # Global fcitx5 behaviour + hotkeys (ported from shorin-arch-setup).
  xdg.configFile."fcitx5/config" = {
    text = ''
      [Hotkey]
      # Enumerate when holding modifier of Toggle key
      EnumerateWithTriggerKeys=True
      # Enumerate Input Method Forward
      EnumerateForwardKeys=
      # Enumerate Input Method Backward
      EnumerateBackwardKeys=
      # Skip first input method while enumerating
      EnumerateSkipFirst=False
      # Time limit in milliseconds for triggering modifier key shortcuts
      ModifierOnlyKeyTimeout=250

      [Hotkey/TriggerKeys]
      0=Super+space
      1=Zenkaku_Hankaku
      2=Hangul

      [Hotkey/ActivateKeys]
      0=Hangul_Hanja

      [Hotkey/DeactivateKeys]
      0=Hangul_Romaja

      [Hotkey/AltTriggerKeys]
      0=Shift_L

      [Hotkey/EnumerateGroupForwardKeys]
      0=Super+space

      [Hotkey/EnumerateGroupBackwardKeys]
      0=Shift+Super+space

      [Hotkey/PrevPage]
      0=Up

      [Hotkey/NextPage]
      0=Down

      [Hotkey/PrevCandidate]
      0=Shift+Tab

      [Hotkey/NextCandidate]
      0=Tab

      [Hotkey/TogglePreedit]
      0=Control+Alt+P

      [Behavior]
      # Active By Default
      ActiveByDefault=False
      # Reset state on Focus In
      resetStateWhenFocusIn=No
      # Share Input State
      ShareInputState=No
      # Show preedit in application
      PreeditEnabledByDefault=True
      # Show Input Method Information when switch input method
      ShowInputMethodInformation=True
      # Show Input Method Information when changing focus
      showInputMethodInformationWhenFocusIn=False
      # Show compact input method information
      CompactInputMethodInformation=True
      # Show first input method information
      ShowFirstInputMethodInformation=True
      # Default page size
      DefaultPageSize=5
      # Override XKB Option
      OverrideXkbOption=False
      # Custom XKB Option
      CustomXkbOption=
      # Force Enabled Addons
      EnabledAddons=
      # Force Disabled Addons
      DisabledAddons=
      # Preload input method to be used by default
      PreloadInputMethod=True
      # Allow input method in the password field
      AllowInputMethodForPassword=False
      # Show preedit text when typing password
      ShowPreeditForPassword=False
      # Interval of saving user data in minutes
      AutoSavePeriod=30
    '';
    force = true; # fcitx5 rewrites this file at runtime via configtool
  };

  # IM group: rime is the default Chinese engine, US keyboard fallback.
  # force = true because fcitx5 rewrites this file at runtime; without
  # force, every rebuild would leave the user's runtime copy in place
  # and HM would fail to overwrite it.
  xdg.configFile."fcitx5/profile" = {
    text = ''
      [Groups/0]
      Name=Default
      Default Layout=us
      DefaultIM=rime

      [Groups/0/Items/0]
      Name=keyboard-us
      Layout=

      [Groups/0/Items/1]
      Name=rime
      Layout=

      [GroupOrder]
      0=Default
    '';
    force = true;
  };

  # fcitx5-pinyin addon behaviour (ported; only takes effect for the pinyin
  # input method, inactive while rime is the default engine).
  xdg.configFile."fcitx5/conf/pinyin.conf".text = ''
    # 双拼方案
    ShuangpinProfile=Ziranma
    # 显示当前双拼模式
    ShowShuangpinMode=True
    # 每页候选词
    PageSize=5
    # 显示英文候选词
    SpellEnabled=True
    # 显示符号候选词
    SymbolsEnabled=True
    # 显示拆字候选词
    ChaiziEnabled=True
    # 启用 Unicode CJK 拓展区 B 之后的更多字符
    ExtBEnabled=True
    # 输入 h(横)，s(竖)，p(撇)，n(捺)，z(折) 时显示笔画候选词
    StrokeCandidateEnabled=True
    # 启用云拼音
    CloudPinyinEnabled=True
    # 云拼音候选词顺序
    CloudPinyinIndex=2
    # 加载云拼音的时候显示动画
    CloudPinyinAnimation=True
    # 总是显示云拼音的占位符
    KeepCloudPinyinPlaceHolder=False
    # 预编辑模式
    PreeditMode="Composing pinyin"
    # 将嵌入预编辑文本的光标固定在开头
    PreeditCursorPositionAtBeginning=True
    # 在预编辑中显示完整拼音
    PinyinInPreedit=False
    # 启用预测
    Prediction=False
    # Keep the current typed text for next input prediction
    KeepCurrentContext=True
    # 预测数量
    PredictionSize=49
    # 预测时退格键的行为
    BackspaceBehaviorOnPrediction="Backspace when not using on-screen keyboard"
    # 切换输入法时的行为
    SwitchInputMethodBehavior="Commit current preedit"
    # 选择第二个候选词
    SecondCandidate=
    # 选择第三个候选词
    ThirdCandidate=
    # 使用数字键盘选词
    UseKeypadAsSelection=False
    # 使用退格键取消选词
    BackSpaceToUnselect=True
    # 句子数量
    Number of sentence=2
    # 词组候选词数
    WordCandidateLimit=15
    # 输入长于...时提示长词 (设置为 0 时禁用)
    LongWordLengthLimit=4
    # 快速输入的触发键
    QuickPhraseKey=semicolon
    # 使用 V 来触发快速输入
    VAsQuickphrase=True
    # FirstRun
    FirstRun=False

    [ForgetWord]
    0=Control+7

    [PrevPage]
    0=minus
    1=Up
    2=KP_Up
    3=Page_Up

    [NextPage]
    0=equal
    1=Down
    2=KP_Down
    3=Next

    [PrevCandidate]
    0=Shift+Tab

    [NextCandidate]
    0=Tab

    [CurrentCandidate]
    0=space
    1=KP_Space

    [CommitRawInput]
    0=Return
    1=KP_Enter
    2=Control+Return
    3=Control+KP_Enter
    4=Shift+Return
    5=Shift+KP_Enter
    6=Control+Shift+Return
    7=Control+Shift+KP_Enter

    [ChooseCharFromPhrase]
    0=bracketleft
    1=bracketright

    [FilterByStroke]
    0=grave

    [QuickPhraseTriggerRegex]
    0=.(/|@)$
    1=^(www|bbs|forum|mail|bbs)\\.
    2=^(http|https|ftp|telnet|mailto):

    [Fuzzy]
    # ue -> ve
    VE_UE=True
    # 常见错误
    NG_GN=True
    # 内模糊音节 (xian -> xi'an)
    Inner=True
    # 短拼音的内模糊音节 (qie -> qi'e)
    InnerShort=True
    # 匹配不完整的元音 (e -> en, eng, ei)
    PartialFinal=True
    # 输入长度大于 4 时进行部分双拼匹配
    PartialSp=False
    # u <-> v
    V_U=False
    # an <-> ang
    AN_ANG=False
    # en <-> eng
    EN_ENG=False
    # ian <-> iang
    IAN_IANG=False
    # in <-> ing
    IN_ING=False
    # u <-> ou
    U_OU=False
    # uan <-> uang
    UAN_UANG=False
    # c <-> ch
    C_CH=False
    # f <-> h
    F_H=False
    # l <-> n
    L_N=False
    # l <-> r
    L_R=False
    # s <-> sh
    S_SH=False
    # z <-> zh
    Z_ZH=False
    # 纠错布局
    Correction=None
  '';

  # Half-width punctuation after letters/numbers + hotkey to toggle.
  xdg.configFile."fcitx5/conf/punctuation.conf".text = ''
    # 字母或者数字之后输入半角标点
    HalfWidthPuncAfterLetterOrNumber=True
    # 同时输入成对标点 (例如引号)
    TypePairedPunctuationsTogether=False
    # Enabled
    Enabled=True

    [Hotkey]
    0=Control+period
  '';

  # Simplified <-> Traditional conversion (OpenCC), Control+Shift+F toggle.
  xdg.configFile."fcitx5/conf/chttrans.conf".text = ''
    # 转换引擎
    Engine=OpenCC
    # 启用的输入法
    EnabledIM=
    # 简转繁的 OpenCC 配置
    OpenCCS2TProfile=default
    # 繁转简的 OpenCC 配置
    OpenCCT2SProfile=default

    [Hotkey]
    0=Control+Shift+F
  '';

  xdg.configFile."fcitx5/conf/notifications.conf".text = ''
    # 隐藏通知
    HiddenNotifications=
  '';

  # default.custom.yaml: user-level patches for the system default.yaml.
  # Placed in RIME_USER_DIR so fcitx5-rime reads it on deploy.
  # NOTE: schema_list only lists rime_ice, because locales/zh-cn.nix ships
  # rime-ice data only.  shorin's original also listed luna_pinyin_simp,
  # double_pinyin_flypy, wubi86, bopomofo — importing those rime-data packages
  # first, then appending the schemas here.
  # page_size was kept at 9 (shorin used 6).
  xdg.configFile."fcitx5/rime/default.custom.yaml".text = ''

    patch:
      menu/page_size: 9
      ascii_composer/switch_key:
        Shift_L: inline_ascii
        Shift_R: commit_text
      schema_list:
        - schema: rime_ice
  '';

  # rime_ice.custom.yaml: language-model grammar for sentence-level prediction.
  xdg.configFile."fcitx5/rime/rime_ice.custom.yaml".text = ''

    patch:

      "grammar/language": wanxiang-lts-zh-hans
  '';

  home.sessionVariables.RIME_USER_DIR = "$HOME/.config/fcitx5/rime";
}
