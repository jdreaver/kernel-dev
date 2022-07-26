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
      devShells.x86_64-linux.default = pkgs.mkShell {
        # Disable default hardening flags. These are very confusing when doing
        # development and they break builds of packages/systems that don't
        # expect these flags to be on. Automatically enables stuff like
        # FORTIFY_SOURCE, -Werror=format-security, -fPIE, etc. See:
        # - https://nixos.org/manual/nixpkgs/stable/#sec-hardening-in-nixpkgs
        # - https://nixos.wiki/wiki/C#Hardening_flags
        hardeningDisable = ["all"];

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

          # Clang kernel builds
          clang

          # Non-standard build stuff
          gmp # for a gcc plugin used by some staging module
          libmpc # for a gcc plugin used by some staging module
          mpfr # for a gcc plugin used by some staging module

          # QEMU and dev scripts
          debootstrap

          # Cross-compilation to ARM
          pkgsCross.aarch64-multiplatform.buildPackages.gcc
          pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc

          # Kernel tools
          coccinelle
          sparse
          qt5.full # for make xconfig
          lz4

          # buildroot
          unzip

          # For kernel docs
          sphinx
          texlive.combined.scheme-small
          graphviz
        ];
      };

      qemu-image = import ./nix-image/make-image.nix { inherit pkgs; };

    };
}
