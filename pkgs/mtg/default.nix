{ fetchFromGitHub,  buildGoPackage, lib }:
buildGoPackage rec {
  pname = "mtg";
  version = "2.1.4";
  rev = "v${version}";

  goPackagePath = "github.com/9seconds/mtg";
  src = fetchFromGitHub {
    owner = "9seconds";
    repo = "mtg";
    rev = "v${version}";
    sha256 = "sha256-uuJqEq+WPoBmJIWjclodZAc0yZG22GbuYk0uuNhNWkI=";
  };
  goDeps = ./deps.nix;

  meta = with lib; {
    description = "Highly-opionated (ex-bullshit-free) MTPROTO proxy for Telegram.";
    homepage = "https://github.com/9seconds/mtg";
    license = licenses.mit;
    platforms = platforms.linux;
  };
  
}