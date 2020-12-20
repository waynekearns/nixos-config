{ config, pkgs, ... }:

{
  services.dnscrypt-proxy2.settings = {
    ipv6_servers = true;
    require_dnssec = true;
    require_nolog = true;
    require_nofilter = true;
    lb_strategy = "p2";
    lb_estimator = true;
    dnscrypt_ephemeral_keys = true;
    tls_disable_session_tickets = true;
  };

  services.dnscrypt-proxy2.configFile = pkgs.runCommand "dnscrypt-proxy.toml" {
    json = builtins.toJSON config.services.dnscrypt-proxy2.settings;
    passAsFile = [ "json" ];
  } ''
    ${pkgs.remarshal}/bin/toml2json ${pkgs.dnscrypt-proxy2.src}/dnscrypt-proxy/example-dnscrypt-proxy.toml > example.json
    ${pkgs.jq}/bin/jq --slurp add example.json $jsonPath > config.json # merges the two
    ${pkgs.remarshal}/bin/json2toml < config.json > $out
  '';
}
