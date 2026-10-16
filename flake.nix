{
  description = "Equibop with a pinned Equicord payload for NixOS/Linux";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  # Reuse Caelestia's canonical plugin source instead of duplicating it here.
  inputs.caelestia-shell = {
    url = "github:Rodrigo-Matuz/shell";
    flake = false;
  };

  outputs = { nixpkgs, caelestia-shell, ... }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      equicord = pkgs.equicord.overrideAttrs (old: {
        pname = "equicord-caelestia";
        postPatch = (old.postPatch or "") + ''
          # Equibop loads this Equicord payload, so inject the same plugin
          # source used by the Caelestia/Vesktop integration.
          mkdir -p src/userplugins/caelestiaVoice
          cp -r ${caelestia-shell}/integrations/vencord/caelestiaVoice/. src/userplugins/caelestiaVoice/
        '';
      });
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
