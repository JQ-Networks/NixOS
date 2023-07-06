{ fetchFromGitHub, buildGoModule, lib, source }:
buildGoModule rec {
  inherit (source) src pname version;

  vendorSha256 = "sha256-lMeJ3z/iTHIbJI5kTzkQjNPMv5tGMJK/+PM36BUlpjE=";
  doCheck = false;

  buildPhase = ''
    buildFlagsArray=(-v -trimpath -tags "with_gvisor" -p $NIX_BUILD_CORES -ldflags='-X "github.com/Dreamacro/clash/constant.Version=${version}" -s -w -buildid=')
    runHook preBuild
    go build "''${buildFlagsArray[@]}" -o Clash.Meta
    runHook postBuild
  '';

  installPhase = ''
    install -Dm755 Clash.Meta -t $out/bin
  '';

  meta = with lib; {
    description = "Another Clash Kernel.";
    homepage = "https://github.com/MetaCubeX/Clash.Meta";
    license = licenses.gpl3;
    platforms = with platforms; linux ++ darwin;
  };

}
