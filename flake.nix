{
  description = "Equibop with a pinned Equicord payload for NixOS/Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      equicord = pkgs.equicord;
      equibop = pkgs.callPackage ./nix/equibop.nix {
        src = ./.;
        version = "3.3.1";
        inherit equicord;
      };
    in
    {
      packages.${system} = {
        default = equibop;
        equibop = equibop;
        equicord = equicord;
      };

      apps.${system}.default = {
        type = "app";
        program = "${equibop}/bin/equibop";
        meta = {
          description = "Run Equibop with the pinned Equicord payload";
        };
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = with pkgs; [
          bun
          nodejs
          pnpm_10
        ];
      };
    };
}
