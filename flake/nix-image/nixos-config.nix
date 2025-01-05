{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.loader.grub.enable = false;
  boot.initrd.enable = false;
  boot.isContainer = true;
  boot.loader.initScript.enable = true;

  networking.firewall.enable = false;

  # Enable serial console. See https://github.com/NixOS/nixpkgs/issues/84105
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200"
  ];
  systemd.services."serial-getty@ttyS0" = {
    enable = lib.mkForce true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };

  # Auto-login as root with empty password
  services.getty.autologinUser = lib.mkDefault "root";
  users.extraUsers.root.initialHashedPassword = "";
  services.getty.helpLine = ''
    Log in as "root" with an empty password.
    If you are connect via serial console:
    Type Ctrl-a c to switch to the qemu console
    and `quit` to stop the VM.
  '';

  documentation.doc.enable = false;
  documentation.man.enable = false;
  documentation.nixos.enable = false;
  documentation.info.enable = false;
  programs.bash.enableCompletion = false;
  programs.command-not-found.enable = false;

  # Enable SSH with root login. SSH is generally a nicer experience than the
  # QEMU serial console.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PermitEmptyPasswords = "yes";
    };
  };
  security.pam.services.sshd = {
    allowNullPassword = true;
  };

  environment.systemPackages = with pkgs; [
    arp-scan
    binutils
    cpuid
    dhcpcd
    dmidecode
    dnsutils # dig et al
    efibootmgr
    elfutils
    ethtool
    file
    fzf
    htop
    inetutils # telnet
    iperf3
    kmod # modprobe
    lsof
    nmap
    pciutils # for lspci
    screenfetch # nice little util showing system summary
    sysstat # Perf monitoring: mpstat, iostat, sar, etc
    tcpdump
    tldr # Simpler man pages https://tldr.sh
    tree
    usbutils # lsusb
    wget

    # Performance utilities
    linuxPackages.perf
    trace-cmd

    # eBPF (bcc is enabled with programs.bcc.enable = true;)
    bpftrace
    linuxPackages.ply
  ];

  system.stateVersion = "22.05";
}
