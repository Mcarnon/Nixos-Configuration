# Laptop host configuration.
{ config, lib, pkgs, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    role = "laptop";
    hostName = "laptop";
    timeZone = "Asia/Shanghai";
  };

  # Boot loader (UEFI).
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  # Laptop-specific hardware/features.
  hardware.bluetooth.enable = true;

  # Firmware for the Intel SOF audio DSP on Tiger Lake (not in enableAllFirmware).
  hardware.firmware = [ pkgs.sof-firmware ];

  # Compressed RAM swap (matches the 4 GiB zram currently in use).
  zramSwap.enable = true;

  # Intel Iris Xe graphics (i915): OpenGL + VA-API hardware video decode.
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # VA-API driver for the i5-1155G7's Gen12 iGPU
    ];
  };

  # Audio: PipeWire with PulseAudio / ALSA (and JACK) compatibility.
  services.pipewire = {
    enable = true;
    audio.enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # jack.enable = true; # optional: JACK compatibility
  };

  # Desktop environment: niri (scrollable-tiling Wayland compositor).
  # Registers the session, sets up xdg-desktop-portal and gnome-keyring.
  programs.niri.enable = true;

  # Noctalia: the Wayland desktop shell (bar, launcher, notifications, ...).
  # Its power-profile widget needs power-profiles-daemon, which replaces TLP
  # (the two conflict), so TLP is disabled on this host.
  programs.noctalia = {
    enable = true;
    # NetworkManager + bluetooth + UPower + power-profiles-daemon.
    recommendedServices.enable = true;
  };

  # Polkit for GUI privilege prompts (mounting disks, admin GUI actions).
  security.polkit.enable = true;

  # Greetd login manager; after login it starts niri directly.
  services.greetd = {
    enable = true;
    useTextGreeter = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --cmd ${pkgs.niri}/bin/niri-session";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    # ...
  ];
}
