{
  description = "Flake for building the protoc-gen-es NPM package";

  inputs = {
    # Pulling the nixpkgs repository for the necessary Nix packages
    nixpkgs.url = "github:NixOS/nixpkgs/24.05";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
      };
    in {
      packages = {
        # Define the package for the current system
        ${system} = pkgs.buildNpmPackage rec {
          pname = "protoc-gen-es";
          version = "2.0.0";

          src = pkgs.fetchFromGitHub {
            owner = "bufbuild";
            repo = "protobuf-es";
            rev = "refs/tags/v${version}";
            hash = "sha256-foPt++AZjBfqKepzi2mKXB7zbpCqjmPftN9wyk5Yk8g=";

            postFetch = ''
              ${pkgs.lib.getExe pkgs.npm-lockfile-fix} $out/package-lock.json
            '';
          };

          npmDepsHash = "sha256-4m3xeiid+Ag9l1qNoBH08hu3wawWfNw1aqeniFK0Byc=";

          npmWorkspace = "packages/protoc-gen-es";

          preBuild = ''
            npm run --workspace=packages/protobuf build
            npm run --workspace=packages/protoplugin build
          '';

          passthru.updateScript = ./update.sh;

          postInstall = ''
            rm -rf $out/lib/node_modules/protobuf-es/node_modules/@bufbuild
            cp -rL node_modules/@bufbuild $out/lib/node_modules/protobuf-es/node_modules/
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
        };
      };

      # Optionally, you can define a defaultPackage if you intend to use this flake as a package.
      defaultPackage.${system} = self.packages.${system};
    };
}

