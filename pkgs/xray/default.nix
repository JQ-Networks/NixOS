{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "xray";
  version = "1.6.1";
  rev = "v${version}";

  src = fetchFromGitHub {
    owner = "XTLS";
    repo = "Xray-core";
    rev = "v${version}";
    sha256 = "sha256-K5S8xgV1U7NmsGPvLb2kxLW4RvQYjvUyuBFSIYqvSzw=";
  };
  vendorSha256 = "sha256-QAF/05/5toP31a/l7mTIetFhXuAKsT69OI1K/gMXei0=";
  doCheck = false;

  buildPhase = ''
    buildFlagsArray=(-v -p $NIX_BUILD_CORES -ldflags="-s -w")
    runHook preBuild
    go build "''${buildFlagsArray[@]}" -o v2ray ./main
    runHook postBuild
  '';

  installPhase = ''
    install -Dm755 v2ray -t $out/bin
  '';

  meta = with lib; {
    description = "Project X originates from XTLS protocol, provides a set of network tools such as Xray-core and Xray-flutter.";
    homepage = "https://github.com/XTLS/Xray-core";
    license = licenses.mpl20;
    platforms = platforms.linux;
  };

}
