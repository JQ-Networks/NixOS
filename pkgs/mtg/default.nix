{ fetchFromGitHub, buildGoModule, lib, source }:
buildGoModule rec {
  inherit (source) src pname version;

  vendorHash = "sha256-OCwJ0oBAHBoAyKTsacos4iZdOiX2iZ5XJBt6PopRxWo=";
  doCheck = false;
  meta = with lib; {
    description = "Highly-opionated (ex-bullshit-free) MTPROTO proxy for Telegram.";
    homepage = "https://github.com/9seconds/mtg";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
