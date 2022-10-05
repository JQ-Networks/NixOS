{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "sing-box";
  version = "1.0.5";
  rev = "v${version}";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = "sing-box";
    rev = "v${version}";
    sha256 = "sha256-S1a78qXnAE+CoKN8yKjPJdHXmojGXce7oGrexIH8Y8c=";
  };

  vendorSha256 = "sha256-nHtYTCd59rMIcstFjw62dxVH6CJl91yx9EBz2FrwSoo=";
  doCheck = false;

  buildPhase = ''
    buildFlagsArray=(-v -trimpath -tags "with_quic,with_wireguard,with_clash_api,with_gvisor" -p $NIX_BUILD_CORES -ldflags="-s -w")
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
