{ fetchFromGitHub, buildGoModule, lib, source }:
buildGoModule rec {
  inherit (source) src pname version;

  vendorSha256 = "sha256-IZGMyoCqcpX1Ocag0sZY7b70lAOq58SxD3q+qPJyp9g=";
  doCheck = false;

  buildPhase = ''
    buildFlagsArray=(-v -trimpath -tags "with_quic,with_wireguard,with_clash_api,with_v2ray_api,with_gvisor" -p $NIX_BUILD_CORES -ldflags="-s -w")
    runHook preBuild
    go build "''${buildFlagsArray[@]}" -o sing-box ./cmd/sing-box
    runHook postBuild
  '';

  installPhase = ''
    install -Dm755 sing-box -t $out/bin
  '';

  meta = with lib; {
    description = "The universal proxy platform.";
    homepage = "https://github.com/SagerNet/sing-box";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };

}
