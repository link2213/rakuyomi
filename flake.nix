{
  description = "Rust example flake for Zero to Nix";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.2305.491812.tar.gz";
    naersk = {
      url = "github:nmattia/naersk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url  = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, naersk, fenix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # FIXME probably `armv7-unknown-linux-gnueabihf` is more accurate
        desktopTarget = "x86_64-unknown-linux-musl";
        kindleTarget = "arm-unknown-linux-musleabi";

        pkgs = import nixpkgs {
          inherit system;
        };

        mkServerPackage = target:
          let
            pkgsCross = import nixpkgs {
              inherit system;
              config.allowUnsupportedSystem = true;
              crossSystem.config = target;
            };
            toolchain = with fenix.packages.${system};
              combine [
                minimal.rustc
                minimal.cargo
                targets.${target}.latest.rust-std
              ];
            naersk' = pkgs.callPackage naersk {
              cargo = toolchain;
              rustc = toolchain;
            };
          in
            naersk'.buildPackage rec {
              src = ./backend;
              cargoBuildOptions = defaultOptions: defaultOptions ++ ["-p" "server"];

              CARGO_BUILD_TARGET = target;
              TARGET_CC = with pkgsCross.stdenv; "${cc}/bin/${cc.targetPrefix}cc";
              CARGO_BUILD_RUSTFLAGS = [
                "-C" "target-feature=+crt-static"
                # https://github.com/rust-lang/cargo/issues/4133
                "-C" "linker=${TARGET_CC}"
              ];
            };

          mkPluginFolder = target:
            let
              server = mkServerPackage target;
            in
              with pkgs; stdenv.mkDerivation {
                name = "rakuyomi-plugin";
                src = ./frontend;
                phases = [ "unpackPhase" "installPhase" ];
                installPhase = ''
                  mkdir $out
                  cp -r $src/rakuyomi.koplugin/* $out/
                  cp ${server}/bin/server $out/server
                '';
              };
      in
      {
        packages.rakuyomi.desktop = mkPluginFolder desktopTarget;
        packages.rakuyomi.kindle = mkPluginFolder kindleTarget;
      }
    );
}
