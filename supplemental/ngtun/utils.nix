{ pkgs, ... }:
with builtins;
{
  # Get the public key from a private key
  getPublicKey = privateKey: (readFile (
    pkgs.runCommandLocal "mesh-wg-pubkey" {} "echo ${privateKey} | ${pkgs.wireguard}/bin/wg pubkey | ${pkgs.coreutils}/bin/head -c -1 > $out"
  ));
}
