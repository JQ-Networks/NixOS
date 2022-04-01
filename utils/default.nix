{ lib, pkgs, ... }:
with lib;
rec {
  recursiveMerge = attrList:
    let
      f = attrPath:
        zipAttrsWith (
          n: values:
            if tail values == []
            then head values
            else if all isList values
            then unique (concatLists values)
            else if all isAttrs values
            then f (attrPath ++ [ n ]) values
            else last values
        );
    in
      f [] attrList;

  fromYAML = yaml: builtins.fromJSON (
    builtins.readFile (
      pkgs.runCommand "from-yaml"
        {
          inherit yaml;
          allowSubstitutes = false;
          preferLocalBuild = true;
        }
        ''
          ${pkgs.remarshal}/bin/remarshal  \
            -if yaml \
            -i <(echo "$yaml") \
            -of json \
            -o $out
        ''
    )
  );

  readYAML = path: fromYAML (builtins.readFile path);
}
