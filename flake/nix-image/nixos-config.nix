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
  networking.interfaces.eth0 = {
    # This is kind of weird. We set usDHCP = true and we set a static IP. The IP
    # is what I get when I run DHCP in QEMU. By seeding with a static IP I seem
    # make DHCP much faster (without it I need to wait 10 seconds for DHCP to
    # run).
    useDHCP = true;
    ipv4.addresses = [
      {
        address = "10.0.2.15";
        prefixLength = 24;
      }
    ];
  };

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

  # Enable LVM so LVM commands work
  services.lvm.enable = true;

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
    lvm2
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
