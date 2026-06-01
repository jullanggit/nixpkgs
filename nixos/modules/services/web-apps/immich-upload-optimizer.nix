{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.immich-upload-optimizer;
in
{
  options.services.immich-upload-optimizer = {
    enable = lib.mkEnableOption "Immich Upload Optimizer";

    package = lib.mkPackageOption pkgs "immich-upload-optimizer" { };

    upstream = lib.mkOption {
      type = lib.types.str;
      default = "http://localhost:2283";
      description = "The URL of the Immich server.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "0.0.0.0";
      description = "The address on which the proxy will listen.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 2283;
      description = "The port on which the proxy will listen.";
    };

    tasks = lib.mkOption {
      type = lib.types.listOf (
        lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Name of the task.";
            };
            command = lib.mkOption {
              type = lib.types.str;
              default = "";
              description = ''
                Command to run. Empty string means passthrough to immich.
                Placeholders:
                  - {{.folder}}: Temporary working directory.
                  - {{.name}}: Filename without extension.
                  - {{.extension}}: File extension.
              '';
              example = ''"''${pkgs.libjxl}/bin/cjxl --lossless_jpeg=1 {{.folder}}/{{.name}}.{{.extension}} {{.folder}}/{{.name}}-new.jxl && rm {{.folder}}/{{.name}}.{{.extension}}"'';
            };
            extensions = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "File extensions this task applies to.";
              example = [
                "jpeg"
                "jpg"
                "png"
              ];
            };
          };
        }
      );
      default = [
        {
          name = "jpeg-xl";
          command = "${pkgs.libjxl}/bin/cjxl --lossless_jpeg=1 {{.folder}}/{{.name}}.{{.extension}} {{.folder}}/{{.name}}-new.jxl && rm {{.folder}}/{{.name}}.{{.extension}}";
          extensions = [
            "jpeg"
            "jpg"
          ];
        }
        {
          name = "passthrough-images";
          command = "";
          extensions = [
            "avif"
            "bmp"
            "gif"
            "heic"
            "heif"
            "webp"
            "insp"
            "jxl"
            "webp"
            "psd"
            "raw"
            "rw2"
            "svg"
            "tif"
            "tiff"
            "webp"
          ];
        }
        {
          name = "passthrough-videos";
          command = "";
          extensions = [
            "3gp"
            "3gpp"
            "avi"
            "flv"
            "m4v"
            "mkv"
            "mts"
            "m2ts"
            "m2t"
            "mp4"
            "insv"
            "mpg"
            "mpe"
            "mpeg"
            "mov"
            "webm"
            "wmv"
          ];
        }
      ];
      description = ''
        List of tasks executed sequentially based on the file extension of the uploaded file.
        See https://github.com/miguelangel-nubla/immich-upload-optimizer/blob/main/TASKS.md for more information.
      '';
    };
  };

  config =
    let
      tasksFile = (pkgs.formats.yaml { }).generate "tasks.yaml" { tasks = cfg.tasks; };
    in
    lib.mkIf cfg.enable {
      systemd.services.immich-upload-optimizer = {
        description = "Immich Upload Optimizer";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];

        path = [
          pkgs.bash
          pkgs.coreutils
        ];

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe cfg.package} -upstream ${cfg.upstream} -listen ${cfg.host}:${toString cfg.port} -tasks_file ${tasksFile}";
          Restart = "on-failure";
          RestartSec = "5";

          # Hardening
          DynamicUser = true;
          NoNewPrivileges = true;
          ProtectSystem = "strict";
          ProtectHome = true;
          PrivateTmp = true;
          PrivateDevices = true;
          ProtectClock = true;
          ProtectKernelTunables = true;
          ProtectKernelModules = true;
          ProtectControlGroups = true;
          RestrictAddressFamilies = [
            "AF_INET"
            "AF_INET6"
            "AF_UNIX"
          ];
          RestrictNamespaces = true;
          LockPersonality = true;
          MemoryDenyWriteExecute = true;
          RestrictRealtime = true;
          RestrictSUIDSGID = true;
          RemoveIPC = true;
        };
      };
    };
}
