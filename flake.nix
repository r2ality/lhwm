{
  description = "LHWM - Lightweight HolyWM, a compact HolyC X11 window manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    holyc-lang = {
      url = "github:Jamesbarford/holyc-lang";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, holyc-lang }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };

          hcc = pkgs.stdenv.mkDerivation {
            pname = "holyc-lang";
            version = "unstable";
            src = holyc-lang;
            nativeBuildInputs = with pkgs; [ cmake gnumake gcc pkg-config ];
            dontConfigure = true;
            buildPhase = ''
              runHook preBuild
              make INSTALL_PREFIX="$out" -j"$NIX_BUILD_CORES"
              runHook postBuild
            '';
            installPhase = ''
              runHook preInstall
              make INSTALL_PREFIX="$out" install

              # hcc does not install its core HolyC runtime automatically.
              # Build libtos into the same prefix that LHWM passes to
              # `hcc --install-dir`, and install its public include file.
              mkdir -p "$out/include" "$out/lib"
              install -m 644 src/holyc-lib/tos.HH "$out/include/tos.HH"
              (
                cd src/holyc-lib
                "$out/bin/hcc" -lib tos --install-dir="$out" ./all.HC
              )

              # Fail here with a useful message rather than letting the
              # dependent LHWM derivation fail later with `cannot find -ltos`.
              if ! find "$out/lib" -maxdepth 1 -name 'libtos.*' -print -quit | grep -q .; then
                echo "hcc did not produce libtos in $out/lib" >&2
                exit 1
              fi
              runHook postInstall
            '';
            doCheck = false;
            meta = {
              description = "HolyC compiler and runtime";
              homepage = "https://github.com/Jamesbarford/holyc-lang";
              license = pkgs.lib.licenses.bsd2;
              platforms = [ "x86_64-linux" "aarch64-linux" ];
            };
          };

          lhwm = pkgs.stdenv.mkDerivation {
            pname = "lhwm";
            version = "1.1.0";
            src = self;
            nativeBuildInputs = [ hcc pkgs.gcc pkgs.gnumake ];
            # hcc's libtos may be shared; keep the compiler/runtime package
            # in the final closure so the LHWM executable can load it.
            buildInputs = [ pkgs.libx11 hcc ];
            buildPhase = ''
              runHook preBuild
              mkdir -p build
              ${hcc}/bin/hcc --install-dir ${hcc} src/lhwm.HC -o build/lhwm
              runHook postBuild
            '';
            passthru.providedSessions = [ "lhwm" ];
            installPhase = ''
              runHook preInstall
              mkdir -p "$out/bin" "$out/share/lhwm" "$out/share/xsessions"
              install -m 755 build/lhwm "$out/bin/lhwm"
              install -m 644 config/lhwm.conf "$out/share/lhwm/lhwm.conf"
              sed -e 's|@BINDIR@|'"$out"'/bin|g' \
                  -e 's|@DEFAULT_CONFIG@|'"$out"'/share/lhwm/lhwm.conf|g' \
                  scripts/lhwm-session.in > "$out/bin/lhwm-session"
              chmod 755 "$out/bin/lhwm-session"
              sed 's|@BINDIR@|'"$out"'/bin|g' sessions/lhwm.desktop.in > "$out/share/xsessions/lhwm.desktop"
              runHook postInstall
            '';
            meta = with pkgs.lib; {
              description = "Lightweight HolyC X11 window manager";
              homepage = "https://github.com/vladbiber/holywm";
              license = licenses.mit;
              platforms = [ "x86_64-linux" "aarch64-linux" ];
              mainProgram = "lhwm";
            };
          };
        in
        {
          default = lhwm;
          lhwm = lhwm;
          holyc = hcc;
        }
      );

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          hcc = self.packages.${system}.holyc;
        in
        {
          default = pkgs.mkShell {
            packages = [ hcc pkgs.gcc pkgs.gnumake pkgs.libx11 ];
            shellHook = ''
              export HCC_PREFIX="${hcc}"
              echo "LHWM dev shell: run ./build.sh"
            '';
          };
        }
      );

      overlays.default = final: prev: {
        lhwm = self.packages.${final.system}.default;
      };

      nixosModules.default = import ./nix/nixos-module.nix;
    };
}
