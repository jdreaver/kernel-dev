{
  inputs = {
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };

  outputs = { self, nixpkgs-unstable, rust-overlay }:
    let
      pkgs = import nixpkgs-unstable {
        system = "x86_64-linux";
        overlays = [ rust-overlay.overlays.default ];
        config = { allowUnfree = true; };
      };

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

        # Needed for Rust builds
        RUST_LIB_SRC = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

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
          llvmPackages.clang

          # Rust. See https://www.kernel.org/doc/html/next/rust/quick-start.html
          rustc
          rust-bindgen
          rustfmt
          clippy
          llvmPackages.bintools

          # Non-standard build stuff
          gmp # for a gcc plugin used by some staging module
          libmpc # for a gcc plugin used by some staging module
          mpfr # for a gcc plugin used by some staging module

          # QEMU and dev scripts
          qemu
          debootstrap
          parted

          # Use GNU screen to connect to serial port (e.g. sudo screen /dev/ttyUSB0 115200)
          screen

          # Cross-compilation to ARM. TODO: Move these to a different shell so
          # we don't stuff up the main shell. These add all kinds of warnings to
          # x86 kernel builds.
          #
          # pkgsCross.aarch64-multiplatform.buildPackages.gcc
          # pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
          # pkgsCross.armv7l-hf-multiplatform.glibc.static # For libm and libresolv for busybox
          # gcc-arm-embedded

          # busybox x86
          # glibc.static # For libm and libresolv for busybox

          # Kernel tools
          coccinelle
          cppcheck
          sparse
          #smatch
          # qt5.full # for make xconfig
          lz4

          # buildroot
          unzip

          # b4 https://b4.docs.kernel.org/en/latest/
          b4

          # crosstool-ng
          automake
          help2man
          ncurses
          unzip
          libtool

          # stm32
          stlink

          # u-boot
          swig
          armTrustedFirmwareTools # for fiptool
          ubootTools # mkimage
          xxd

          # DeviceTree tools
          dtc
          dt-schema

          # For kernel docs
          sphinx
          python3Packages.pyyaml
          texlive.combined.scheme-small
          graphviz
        ];
      };

      qemu-image = import ./nix-image/make-image.nix { inherit pkgs; };
    };
}
