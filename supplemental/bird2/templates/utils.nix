{ lib, ... }:
with builtins;
with lib; rec {
  renderSwitch = conf: if conf then "on" else "off";

  optional = f: conf: key: if conf != null then f conf key else "";
  optionalStr = optional (conf: key: "${key} ${conf};");
  optionalQuotedStr = optional (conf: key: ''${key} "${conf}";'');
  optionalInt = optional (conf: key: "${key} ${toString conf};");
  optionalIntOrString = optionalInt;
  optionalSwitch = optional (conf: key: "${key} ${renderSwitch conf};");
  optionalBool = optional (conf: key: "${key};");
  optionalBoolOrInt = optional (conf: key:
    if conf == false then
      ""
    else
      (if conf == true then "${key};" else "${key} ${toString conf};"));
  optionalBoolAndInt = optional (conf: key:
    if conf == false then
      ""
    else
      (if conf == true then "${key};" else "${key} on ${toString conf};"));
  optionalBoolOrString = optional (conf: key:
    if conf == false then
      ""
    else
      (if conf == true then "${key};" else "${key} ${conf};"));
  optionalSwitchOrInt = optional (conf: key:
    if conf == false then
      "${key} off;"
    else
      (if conf == true then "${key} on;" else "${key} ${toString conf};"));
  optionalSwitchOrString = optional (conf: key:
    if conf == false then
      "${key} off;"
    else
      (if conf == true then "${key} on;" else "${key} ${conf};"));

  optionalV2 = f: f2: conf: key: conf2: key2:
    if conf != null then
      if conf2 != null then
        (f conf key) + " " + (f2 conf2 key2) + ";"
      else
        (f conf key) + ";"
    else
      "";

  optionalSwitchAndInt = optionalV2 (conf: key: "${key} ${renderSwitch conf}")
    (conf: key: "${key} ${toString conf}");

  optionalMultiline = sectionName: content: key:
    if sectionName != null || content != null then ''
      ${key} ${if sectionName != null then sectionName + " " else ""}{
         ${if content != null then content else ""}
      };
    '' else
      "";

  configToString = l: foldl (a: b: a + "\n" + b) "" l;
  interfaceToString = linkNames:
    let
      result =
        builtins.concatStringsSep "," (map (x: ''"'' + x + ''"'') linkNames);
    in if linkNames == [ ] then null else result;

}
