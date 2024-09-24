{
  description = "Flake for building the protoc-gen-es NPM package";

  inputs = {
    # Pulling the nixpkgs repository for the necessary Nix packages
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  };

  outputs = { self, nixpkgs, ... }:
    let
      systems = ["x86_64-linux" "aarch64-linux" "x86_64-darwin"]; # List of systems you want to support
      forAllSystems = f: builtins.listToAttrs (map (system: { name = system; value = f system; }) systems);
    in {
      packages = forAllSystems (system: let
        pkgs = import nixpkgs {
          inherit system;
        };
      in pkgs.buildNpmPackage rec {
        pname = "protoc-gen-es";
        version = "1.10.0";

        src = pkgs.fetchFromGitHub {
          owner = "bufbuild";
          repo = "protobuf-es";
          rev = "refs/tags/v${version}";
          hash = "sha256-bHl8gqNrTm1+Cnj43RWmrLDUz+G11C4gprEiNOpyOdQ=";

          postFetch = ''
            ${pkgs.lib.getExe pkgs.npm-lockfile-fix} $out/package-lock.json
          '';
        };

        npmDepsHash = "sha256-ozkkakfSBycu83gTs8Orhm5Tg8kRSrF/vMJxVnPjhIw=";

        npmWorkspace = "packages/protoc-gen-es";

        preBuild = ''
          npm run --workspace=packages/protobuf build
          npm run --workspace=packages/protoplugin build
        '';

        passthru.updateScript = ./update.sh;

        postInstall = ''
          rm -rf $out/lib/node_modules/protobuf-es/node_modules/@bufbuild
          cp -rL node_modules/@bufbuild $out/lib/node_modules/
        '';

        meta = with pkgs.lib; {
          description = "Protobuf plugin for generating ECMAScript code";
          homepage = "https://github.com/bufbuild/protobuf-es";
          changelog = "https://github.com/bufbuild/protobuf-es/releases/tag/v${version}";
          license = licenses.asl20;
          maintainers = with maintainers; [
            felschr
            jtszalay
          ];
        };
      });

      # The default package for 'nix build'.
      defaultPackage = forAllSystems (system: self.packages.${system});
    };
}

