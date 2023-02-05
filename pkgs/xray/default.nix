{ fetchFromGitHub, buildGoModule, lib, source }:
buildGoModule rec {
  inherit (source) src pname version;
  vendorSha256 = "sha256-Eco8KEOvTVquJHmbPn+rgz5MGUV00dx8Da1plluqk7M=";
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
