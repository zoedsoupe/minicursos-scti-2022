{
  inputs = {
    copper.url = "github:zoedsoupe/copper";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.05";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ inputs.copper.overlays."${system}".default ];
        config.allowUnfree = true;
      };

      pythonDrv = pkgs.python310.withPackages (p: with p; [
        psycopg2
      ]);
    in rec {
      devShells."${system}".default = pkgs.mkShell {
        name = "cockrochdb_project";
        buildInputs = with pkgs; [
          wget gcc pythonDrv cockroachdb copper
        ];
        shellHook = ''
        mkdir -p certs;

        if ! [ -n "$(ls -A ./certs 2>/dev/null)" ]; then
          ${pkgs.cockroachdb}/bin/cockroach cert create-ca \
            --certs-dir=certs \
            --ca-key=$PWD/ca.key \
            --allow-ca-key-reuse

          ${pkgs.cockroachdb}/bin/cockroach cert create-node \
            localhost \
            $(${pkgs.hostname}/bin/hostname) \
            --certs-dir=certs \
            --ca-key=$PWD/ca.key

          ${pkgs.cockroachdb}/bin/cockroach cert create-client \
            root \
            --certs-dir=certs \
            --ca-key=$PWD/ca.key
        fi
          
        chmod +x start_db.sh
        '';
      };
    };
}
