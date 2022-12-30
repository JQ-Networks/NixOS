# JQ-Networks Flake Repo

Services that are used by JQ-Networks that are not "included by"/"the default one from" nixpkgs.

Some services might be useful to everyone, such as pppoe service. 

## services and supplemental

`supplemental` folder contains generic nix modules that are standalone and does some very fundamental abstractions.
Each folder under supplemental can be copied to other flake and use without too much modifications.

`services` folder contains customized nix modules that fit my infra. Some of the modules are abstractions based on `supplemental`.
They have cross references and should not be used alone.

## Update package

```bash
nix run github:berberman/nvfetcher
```

Then fix all vendorSha256 in each package manually.