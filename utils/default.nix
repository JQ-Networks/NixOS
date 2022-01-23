{ lib, ... }:
with lib;
{
  lib.jq-networks = {
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
  };
}
