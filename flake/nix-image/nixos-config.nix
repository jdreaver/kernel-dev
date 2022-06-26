{ pkgs, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
  ];
  boot.loader.grub.enable = false;
  boot.initrd.enable = false;
  boot.isContainer = true;
  boot.loader.initScript.enable = true;

  # Auto-login as root with empty password
  services.getty.autologinUser = lib.mkDefault "root";
  users.extraUsers.root.initialHashedPassword = "";

  networking.firewall.enable = false;

  # Enable serial console. See https://github.com/NixOS/nixpkgs/issues/84105
  boot.kernelParams = [
    "console=tty1"
    "console=ttyS0,115200"
  ];
  systemd.services."serial-getty@ttyS0" = {
    enable = true;
    wantedBy = [ "getty.target" ]; # to start at boot
    serviceConfig.Restart = "always"; # restart when session is closed
  };

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
}
