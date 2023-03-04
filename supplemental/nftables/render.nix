{ lib }:
with builtins;
with lib;
let

  # Indent a multi-line string
  indent = indentation: s: concatStringsSep "\n" (map
    (l: indentation + l) (lib.strings.splitString "\n" s)
  );
in rec {
  # Render a single argument or a list
  argument = arg: if isList arg then
    "{" + concatStringsSep ", " (map argument arg) + "}"
  else toString arg;

  # Render a composite along with an argument
  renderComposite = name: arg: if isNull arg then "" else "${name} ${argument arg}";

  # Trim rules with empty args. Rules with empty args are considered invalid rules.
  isFalse = x: (isNull x || x == "" || x == [] || x == {} || x == false);
  filterRules = filter (r: !(any isFalse (attrValues r)));

  # Render a rule
  genRule = r: let
    rules = filterAttrs (key: value: key != "action" && key != "comment" && key != "counter") r;
    argumentExp = concatStringsSep " " (mapAttrsToList renderComposite rules);
    counter = if hasAttr "counter" r then " counter" else "";
    action = if hasAttr "action" r then " ${r.action}" else "";
    comment = if hasAttr "comment" r then " comment \"${r.comment}\"" else "";
  in "${argumentExp}${counter}${action}${comment}";

  genChain = key: options: let
    chainName = if ! isNull options.name then options.name else key;
    type = if !isNull options.type then "type ${options.type}" else "";
    hook = if !isNull options.hook then "hook ${options.hook}" else "";
    priority = if !isNull options.priority then renderComposite "priority"options.priority else "";
    prependExp = concatStringsSep " " (remove "" [type hook priority]);
    renderedPrependExp = if prependExp == "" then "" else "${prependExp};";
    policy = if !isNull options.policy then "policy ${options.policy};" else "";
    rules = map genRule (filterRules options.rules);
  in ''
  chain ${chainName} {
    ${renderedPrependExp}${policy}
    ${concatStringsSep "\n" rules}
  }
  '';

  genSet = key: options: let 
    setName = if ! isNull options.name then options.name else key;
    setType = if !isNull options.typeOf then "typeof ${options.typeOf}" else "type ${options.type}";
    setFlags = if !isNull options.flags then "flags ${options.flags}" else "";
    setElements = renderComposite "" options.elements;
    comment = if ! isNull options.comment then "comment \"${options.comment}\"" else "";
  in ''
  set ${setName} {
    ${setType}
    ${setFlags}
    elements = ${setElements}
    ${options.extraConfigs}
    ${comment}
  }
  '';

  genMap = key: options: let 
    mapName = if ! isNull options.name then options.name else key;
    mapType = if !isNull options.typeOf then "typeof ${options.typeOf}" else "type ${options.type}";
    mapElements = renderComposite "" options.elements;
    comment = if ! isNull options.comment then "comment \"${options.comment}\"" else "";
  in ''
    map ${mapName} {
      ${mapType}
      elements = ${mapElements}
      ${options.extraConfigs}
      ${comment}
    }
  '';

  genTable = key: options: let 
    family = options.family;
    tableName = if !isNull options.name then options.name else key;
    sets = mapAttrsToList genSet options.sets;
    maps = mapAttrsToList genMap options.maps;
    chains = mapAttrsToList genChain options.chains;
  in ''
  table ${family} ${tableName} {
    ${concatStringsSep "\n" sets}
    ${concatStringsSep "\n" maps}

    ${concatStringsSep "\n" chains}
  }
  '';


  genConf = cfg: let
    tables = mapAttrsToList genTable cfg;
  in ''
    ${concatStringsSep "\n" tables}
  '';
}
