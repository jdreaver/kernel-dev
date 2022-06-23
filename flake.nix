{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs-unstable }:
    let
      pkgs = import nixpkgs-unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };
    in {
      devShell.x86_64-linux = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Kernel builds
          autoconf
          bc
          binutils
          bison
          elfutils
          fakeroot
          flex
          gcc
          getopt
          gnumake
          libelf
          ncurses
          openssl
          pahole
          pkg-config
          python3
          xz
          zlib

          # QEMU and dev scripts
          debootstrap
        ];
      };
    };
}
