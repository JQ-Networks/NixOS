{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "mtg";
  version = "2.1.4";
  rev = "v${version}";

  src = fetchFromGitHub {
    owner = "9seconds";
    repo = "mtg";
    rev = "v${version}";
    sha256 = "sha256-uuJqEq+WPoBmJIWjclodZAc0yZG22GbuYk0uuNhNWkI=";
  };

  vendorSha256 = "sha256-996Ittio+XXdIvomNe1j3E0Gp3ZE5CNnGYLKuFa6/To=";
  doCheck = false;
  meta = with lib; {
    description = "Highly-opionated (ex-bullshit-free) MTPROTO proxy for Telegram.";
    homepage = "https://github.com/9seconds/mtg";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
