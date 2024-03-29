# This file was generated by nvfetcher, please do not modify it manually.
{ fetchgit, fetchurl, fetchFromGitHub }:
{
  clash-meta = {
    pname = "clash-meta";
    version = "v1.16.0";
    src = fetchFromGitHub ({
      owner = "MetaCubeX";
      repo = "Clash.Meta";
      rev = "v1.16.0";
      fetchSubmodules = true;
      sha256 = "sha256-ORyjCYf2OPrSt/juiBk0Gf2Az4XoZipKBWWFXf8nIqE=";
    });
  };
  clash-premium = {
    pname = "clash-premium";
    version = "2023-09-05-gdcc8d87";
    src = fetchurl {
      url = "https://github.com/zhongfly/Clash-premium-backup/releases/download/2023-09-05-gdcc8d87/clash-linux-amd64-n2023-09-05-gdcc8d87.gz";
      sha256 = "sha256-8qD1Wq5ILmW6suxpzmKxtM9zhr25xB0Xhfcp4NFoNJE=";
    };
  };
  mtg = {
    pname = "mtg";
    version = "v2.1.7";
    src = fetchFromGitHub ({
      owner = "9seconds";
      repo = "mtg";
      rev = "v2.1.7";
      fetchSubmodules = true;
      sha256 = "sha256-7AJeiTyss/PlIMkTcCIwFrEmRIQYjleUXDUqjYfj/PM=";
    });
  };
  sing-box = {
    pname = "sing-box";
    version = "v1.7.0";
    src = fetchFromGitHub ({
      owner = "SagerNet";
      repo = "sing-box";
      rev = "v1.7.0";
      fetchSubmodules = true;
      sha256 = "sha256-XD4xWOQumqbXMBbzHgCIgFIegUqJnFZsAvk1VZXX5rc=";
    });
  };
  xray = {
    pname = "xray";
    version = "v1.8.4";
    src = fetchFromGitHub ({
      owner = "XTLS";
      repo = "Xray-core";
      rev = "v1.8.4";
      fetchSubmodules = true;
      sha256 = "sha256-Hu0BP4BzoELRjJ8WdF3JS/ffxd3bpH+kauWqaMh/o1I=";
    });
  };
}
