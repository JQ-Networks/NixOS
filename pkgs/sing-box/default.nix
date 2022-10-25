{ fetchFromGitHub, buildGoModule, lib }:
buildGoModule rec {
  pname = "sing-box";
  # version = "1.0.6";
  # rev = "v${version}";
  # this is dev-vnext branch
  version = "d0e883ece6d9a99084f8dabde06ffc464b6db7e0";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = "sing-box";
    # rev = "v${version}";
    rev = version;
    sha256 = "sha256-7NUQFBYcvVUSDd5MLErkFKHRk/3s5OpBDKrLkJyT98k=";
  };

  vendorSha256 = "sha256-PAbVS/v8o4bdN81tsLm06gVQnLNbC+G/DrWwx6eYCFQ=";
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
