{ fetchFromGitHub, buildGoModule, lib, source }:
buildGoModule rec {
  inherit (source) src pname version;
  vendorHash = "sha256-55mNCD3p6Xy6S1w8WzJwxKttjEkEjJZcGTLQdWl1bQQ=";
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
