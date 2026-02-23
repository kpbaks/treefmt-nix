{
  config,
  lib,
  mkFormatterModule,
  pkgs,
  ...
}:
let
  cfg = config.programs.promql;
in
{
  meta.maintainers = [ "kpbaks" ];

  imports = [
    (mkFormatterModule {
      name = "promql";
      package = "prometheus.cli";
      includes = [
        "*.promql"
      ];
    })
  ];

  config = lib.mkIf cfg.enable {
    settings.formatter.promql = {
      command = pkgs.writeShellApplication {
        name = "promtool-wrapper";
        text = ''
          temp=$(mktemp)
          trap 'rm "$temp"' EXIT
          for file in "$@"; do
            # NOTE: this require the text in the file to be passed over $argv[] and not a file name
            # or stdin (😭 absolute ass design).
            # Also not not work with comments in the file it seems
            ${lib.getExe' cfg.package "promtool"} promql format --experimental $(cat "$file") > "$temp"
            if ! cmp -s "$file" "$temp"; then
              cp "$temp" "$file"
            fi
          done
        '';
      };
    };
  };
}
