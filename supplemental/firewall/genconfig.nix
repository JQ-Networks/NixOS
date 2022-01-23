{ lib }:
with builtins;
let
  # List of supported filters
  supportedFilters = [
    "module"
    "interface" "outerface" "proto" "sport" "dport" "saddr" "daddr" "mark"
  ];

  builtinChains = [
    "input" "output" "forward"
    "prerouting" "postrouting"
  ];

  canonicalizeChainName = name: if elem name builtinChains then lib.strings.toUpper name else name;

  # Discard null and unsupported filters
  nonNullFilters = rule: (filter (f: rule.${f} != null) supportedFilters);
  #nonNullFilters = rule: lib.attrsets.filterAttrs (n: v: (elem n supportedFilters) && !isNull v ) rule;

  # Convert an attrset to a list
  attrToList = a: (map (c: {
    name = c;
    value = a.${c};
  }) (attrNames a));

  # Indent a multi-line string
  indent = indentation: s: concatStringsSep "\n" (map
    (l: indentation + l) (lib.strings.splitString "\n" s)
  );
in rec {
  # Render a single argument or a list
  argument = arg: if isList arg then
    "(" + concatStringsSep " " (map argument arg) + ")"
  else toString arg;

  # Render a filter along with an argument
  renderFilter = name: arg: if isNull arg then "" else "${name} ${argument arg}";

  # Render a rule
  rule = r: let
    filterSeq = nonNullFilters r;
    filterExp = concatStringsSep " " (map (name: renderFilter name r.${name}) filterSeq);
    extraFilterExp = if r.extraFilters == "" then "" else " ${r.extraFilters}";
    actionExp = r.action + (if !isNull r.args then " " + r.args else "");
    description = if !isNull r.description then "# ${r.description}\n" else "";
  in "${description}${filterExp}${extraFilterExp} ${actionExp};";

  # Render a chain
  chain = name: options: let
    rules = concatStringsSep "\n" (map rule options.rules);
    rulesAppend = concatStringsSep "\n" (map rule options.rulesAppend);
    policy = if isNull options.policy then "" else ''
      policy ${options.policy};
    '';
    compPrepend = concatStringsSep "\n" options.prepends;
    compAppend = concatStringsSep "\n" options.appends;

    isBlank = let l = stringLength; in
      0 == (l policy + l compPrepend + l rules + l compAppend);
  in if isBlank then "" else ''
    chain ${canonicalizeChainName name} {
    ${indent "  " policy}${indent "  " compPrepend}
    ${indent "  " rules}
    ${indent "  " rulesAppend}
    ${indent "  " compAppend}
    }
  '';

  # Render a table
  # table -> chains
  table = name: options: let
    chains = concatStringsSep " " (lib.attrsets.mapAttrsToList (k: v: chain k v) options.chains);
  in if 0 == stringLength chains then "" else ''
    table ${name} {
    ${indent "  " (concatStringsSep "\n" options.prepends)}
    ${indent "  " chains}
    ${indent "  " (concatStringsSep "\n" options.appends)}
    }
  '';

  # Render a domain
  # dom -> tables -> chains
  domain = name: options: let
    tables = concatStringsSep "" (map
      ({ name, value }: table name value)
      (attrToList options)
    );
  in if 0 == stringLength tables then "" else ''
    domain ${name} {
    ${indent "  " tables}
    }
  '';
}
