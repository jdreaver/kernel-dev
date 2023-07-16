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

      # Use a consistent LLVM version throughout this flake. The default for
      # nixpkgs is 11, while the latest is 16!
      flake_llvmPackages = pkgs.llvmPackages_15;

      # We need a specific version. See https://www.kernel.org/doc/html/next/rust/quick-start.html
      rust-bindgen-0_56 = with pkgs; pkgs.rustPlatform.buildRustPackage rec {
        pname = "bindgen";
        version = "0.56.0";

        src = fetchCrate {
          inherit pname version;
          sha256 = "sha256-ps5tkrq0PvTiGs6vVXhVlbUeGB0h4r9cCFyqETTLxUw=";
        };

        cargoHash = "sha256-dvKaiVLYJgvE3WISoWFeKUhaC0lAMmnuYvTCjIM/yYA=";

        libclang = flake_llvmPackages.libclang.lib;
        inherit bash;
        buildInputs = [ libclang ];

        configurePhase = ''
          export LIBCLANG_PATH="${libclang}/lib"
        '';
        postInstall = ''
          mv $out/bin/{bindgen,.bindgen-wrapped};
          substituteAll ${./bindgen_0_56_wrapper.sh} $out/bin/bindgen
          chmod +x $out/bin/bindgen
            '';
        doCheck = false;
      };
    in {
      # devShells.x86_64-linux.default = pkgs.mkShell {
      #   # Use a slightly older GCC version so older kernels compile. When I
      #   # tried to compile linux-staging in July 2023, nixpkgs used gcc 12 by
      #   # default, and I needed to use gcc 11.
      #   stdenv = pkgs.gcc11Stdenv;
      # } {
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
          flake_llvmPackages.clang

          # Rust. See https://www.kernel.org/doc/html/next/rust/quick-start.html
          (rust-bin.stable."1.62.0".default.override { # Get version with `./scripts/min-tool-version.sh rustc` in kernel source
            extensions = [
              "rust-src"
            ];
            # targets = [
            #   "x86_64-unknown-none"
            # ];
          })
          rust-bindgen-0_56
          flake_llvmPackages.bintools

          # Non-standard build stuff
          gmp # for a gcc plugin used by some staging module
          libmpc # for a gcc plugin used by some staging module
          mpfr # for a gcc plugin used by some staging module

          # QEMU and dev scripts
          qemu
          debootstrap

          # Use GNU screen to connect to serial port (e.g. sudo screen /dev/ttyUSB0 115200)
          screen

          # Cross-compilation to ARM
          pkgsCross.aarch64-multiplatform.buildPackages.gcc
          pkgsCross.armv7l-hf-multiplatform.buildPackages.gcc
          pkgsCross.armv7l-hf-multiplatform.glibc.static # For libm and libresolv for busybox

          # Kernel tools
          coccinelle
          sparse
          # qt5.full # for make xconfig
          lz4

          # buildroot
          unzip

          # stm32
          stlink

          # u-boot
          swig
          armTrustedFirmwareTools # for fiptool
          dtc
          ubootTools # mkimage
          xxd

          # For kernel docs
          sphinx
          texlive.combined.scheme-small
          graphviz
        ];
      };

      qemu-image = import ./nix-image/make-image.nix { inherit pkgs; };
    };
}
