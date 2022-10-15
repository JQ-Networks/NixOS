{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "sing-box";
  # version = "1.0.5";
  # rev = "v${version}";
  # this is dev-vnext branch
  version = "9ea5bbd032fd76c6931266a2ae7d60d2378a0ae4";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = "sing-box";
    # rev = "v${version}";
    rev = version;
    sha256 = "sha256-QsBSgVHFLIhxT2ZG6VjA2eYpzn6zX2qdkIzF4LrLP/M=";
  };

  vendorSha256 = "sha256-mLB//fVP0bKkyvAyYBEUayZkdL/o1szs+5HunJUU8rY=";
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
