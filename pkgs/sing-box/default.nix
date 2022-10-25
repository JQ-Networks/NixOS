{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "sing-box";
  version = "1.0.6";
  rev = "v${version}";
  # this is dev-vnext branch
  # version = "9ea5bbd032fd76c6931266a2ae7d60d2378a0ae4";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = "sing-box";
    rev = "v${version}";
    # rev = version;
    sha256 = "sha256-rt/hk3tYiBbLeUklpblD9w+4KSGHZTDAhaXSV5R3wFE=";
  };

  vendorSha256 = "sha256-nHtYTCd59rMIcstFjw62dxVH6CJl91yx9EBz2FrwSoo=";
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
    homepage = "https://sing-box.sagernet.org/";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };

}
