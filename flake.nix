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
      equicordVersion = "2026-10-08";
      equicord = pkgs.equicord.overrideAttrs (old: rec {
        pname = "equicord-caelestia";
        version = equicordVersion;
        src = pkgs.fetchFromGitHub {
          owner = "Equicord";
          repo = "Equicord";
          tag = version;
          hash = "sha256-38mMUaDgS0nYwrW2WceQmuHDJk1vFU1PEi7HWvNxiZk=";
        };
        pnpmDeps = pkgs.fetchPnpmDeps {
          pname = "equicord";
          inherit version src;
          pnpm = pkgs.pnpm_10;
          fetcherVersion = 3;
          hash = "sha256-rx8z6PAlAPaZbkmg+3Vvq8OXR/yy5ZP0PmAk97ZDOSQ=";
        };
        env = (old.env or {}) // {
          EQUICORD_HASH = version;
          EQUICORD_REMOTE = "Equicord/Equicord";
        };
        postPatch = (old.postPatch or "") + ''
          # Equibop loads this Equicord payload, so inject the same plugin
          # source used by the shared Caelestia Discord-client integration.
          mkdir -p src/userplugins/caelestiaVoice
          cp -r ${caelestia-shell}/integrations/vencord/caelestiaVoice/. src/userplugins/caelestiaVoice/

          # Quickshell can close its probe socket before the initial snapshot
          # is written. Handle that normal disconnect instead of crashing the
          # Electron main process with an uncaught EPIPE.
          substituteInPlace src/userplugins/caelestiaVoice/bridge.ts \
            --replace-fail \
              '        socket.write(`''${JSON.stringify(message)}\n`);' \
              '        socket.on("error", () => socket.destroy());
        if (!socket.destroyed) socket.write(`''${JSON.stringify(message)}\n`);'
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
