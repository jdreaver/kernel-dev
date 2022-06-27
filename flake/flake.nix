{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs-unstable }:
    let
      pkgs = import nixpkgs-unstable { system = "x86_64-linux"; config = { allowUnfree = true; }; };

      python-packages = python-packages: with python-packages; [
        # Needed for checkpatch.pl, which uses spdxcheck.py
        GitPython
        ply
      ];
      python-and-packages = pkgs.python3.withPackages python-packages;

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
          python-and-packages
          xz
          zlib

          # QEMU and dev scripts
          debootstrap

          # Kernel tools
          coccinelle
          sparse
          qt5.full # for make xconfig
          lz4

          # For kernel docs
          sphinx
          texlive.combined.scheme-small
          graphviz
        ];
      };

      qemu-image = import ./nix-image/make-image.nix { inherit pkgs; };

    };
}
