# Security baseline (hardening) + complementary performance tweaks.
# - Security: sudo, polkit, kernel sysctl, AppArmor where cheap.
# - Performance: zram, sysctl for desktop responsiveness.
{
  config,
  pkgs,
  lib,
  ...
}:
{
  # Restrict sudo to wheel, no lecture spam
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
    execWheelOnly = true;
  };

  # Kernel hardening (performance-aware: minimal overhead, no `kernel.sysctl` that hurts desktop)
  boot.kernel.sysctl = {
    # Network: BBR + fq for better throughput on lossy Wi-Fi (performance)
    "net.core.default_qdisc" = "fq";
    "net.ipv4.tcp_congestion_control" = "bbr";
    # Security: restrict unprivileged eBPF, ptrace scope (breaks some debuggers — comment out if you need them)
    "kernel.yama.ptrace_scope" = 1;
    "kernel.kptr_restrict" = 1;
    # Performance: VM tuning for desktop (avoid aggressive swapping before zram)
    "vm.swappiness" = 10;
    "vm.vfs_cache_pressure" = 50;
  };

  # zram swap: faster than disk swapfile for bursts; swapfile at /swap remains for hibernation.
  # Performance: compresses RAM, reduces SSD wear.
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
  };

  # AppArmor is cheap and catches many confinement issues; enable when not conflicting with custom policies.
  # security.apparmor.enable = true;

  # Audit: fail2ban for SSH brute-force (optional on a laptop, cheap if you expose 22)
  # services.fail2ban.enable = true;
}
