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

  vendorSha256 = "sha256-ZqOdHH68srblAl+xMsrWVTPJst6flXAPH4OcBn2bbqg=";
  doCheck = false;
  meta = with lib; {
    description = "Highly-opionated (ex-bullshit-free) MTPROTO proxy for Telegram.";
    homepage = "https://github.com/9seconds/mtg";
    license = licenses.mit;
    platforms = platforms.linux;
  };

}
