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

      # Packages used across different shells. These are host-only and
      # not used for cross-compiling.
      commonPackages = with pkgs; [
        # Kernel builds
        autoconf
        bc
        binutils
        bison
        elfutils
        fakeroot
        flex
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
        qemu
        debootstrap
        parted

        # Use GNU screen to connect to serial port (e.g. sudo screen /dev/ttyUSB0 115200)
        screen

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

      # Function to create a cross-compilation shell
      mkCrossShell = crossSystem: extraPackages: pkgs.mkShell {
        # Disable default hardening flags. These are very confusing when doing
        # development and they break builds of packages/systems that don't
        # expect these flags to be on. Automatically enables stuff like
        # FORTIFY_SOURCE, -Werror=format-security, -fPIE, etc. See:
        # - https://nixos.org/manual/nixpkgs/stable/#sec-hardening-in-nixpkgs
        # - https://nixos.wiki/wiki/C#Hardening_flags
        hardeningDisable = ["all"];

        buildInputs = commonPackages ++ extraPackages;

        # Set up environment variables for cross compilation. We can't
        # set CROSS_COMPILE because making the config is done without
        # CROSS_COMPILE. Just do make
        # CROSS_COMPILE=$LINUX_CROSS_COMPILE.
        shellHook = ''
          export ARCH=${crossSystem.arch}
          export LINUX_CROSS_COMPILE=${crossSystem.triple}-
        '';
      };
    in {
      devShells.x86_64-linux = {
        default = pkgs.mkShell {
          # Needed for Rust builds
          RUST_LIB_SRC = "${pkgs.rust.packages.stable.rustPlatform.rustLibSrc}";

          buildInputs = commonPackages ++ (with pkgs; [
            # Clang kernel builds. Clang can cross-compile, so we can
            # run it in our x86 shell.
            llvmPackages.clang

            # Rust. See https://www.kernel.org/doc/html/next/rust/quick-start.html
            rustc
            rust-bindgen
            rustfmt
            clippy
            llvmPackages.bintools

            # Non-standard build stuff for some random staging modules
            gmp
            libmpc
            mpfr

            # gcc-arm-embedded works just fine
            gcc-arm-embedded
          ]);
        };

        arm64 = mkCrossShell {
          arch = "arm64";
          triple = "aarch64-unknown-linux-gnu";
        } (with pkgs; [
          pkgsCross.aarch64-multiplatform.buildPackages.gcc
        ]);

        powerpc64 = mkCrossShell {
          arch = "powerpc";
          triple = "powerpc64-unknown-linux-gnu";
        } (with pkgs; [
          pkgsCross.ppc64.buildPackages.gcc
        ]);

        mips = mkCrossShell {
          arch = "mips";
          triple = "mips-unknown-linux-gnu";
        } (with pkgs; [
          pkgsCross.mips-linux-gnu.buildPackages.gcc
        ]);

        s390x = mkCrossShell {
          arch = "s390";
          triple = "s390x-unknown-linux-gnu";
        } (with pkgs; [
          pkgsCross.s390x.buildPackages.gcc
        ]);
      };

      qemu-image = import ./nix-image/make-image.nix { inherit pkgs; };
    };
}
