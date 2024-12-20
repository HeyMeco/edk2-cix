{ pkgs, lib, config, inputs, ... }:

{
  # https://devenv.sh/basics/
  # env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [
    mdbook
    mdbook-admonish
    mdbook-cmdrun
    mdbook-i18n-helpers
    mdbook-linkcheck
    mdbook-toc
  ];

  # https://devenv.sh/languages/
  # languages.rust.enable = true;

  # https://devenv.sh/processes/
  # processes.cargo-watch.exec = "cargo-watch";

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/scripts/
  scripts = {
    edk2-console = {
      description = "Launch UART workspace";
      exec = ''
        ${lib.getExe pkgs.tmux} kill-session -t edk2-console
        sleep 1 # wait for picocom to be closed to release UART resources
        ${lib.getExe pkgs.tmux} new-session -d -s edk2-console "${lib.getExe pkgs.picocom} -b 115200 /dev/$EDK2_SE_UART | ${lib.getExe' pkgs.coreutils "tee"} logs/se.log"
        ${lib.getExe pkgs.tmux} set-option mouse on
        ${lib.getExe pkgs.tmux} split-window -h "${lib.getExe pkgs.picocom} -b 460800 --imap lfcrlf /dev/$EDK2_EC_UART | ${lib.getExe' pkgs.coreutils "tee"} logs/ec.log"
        ${lib.getExe pkgs.tmux} split-window -v "${lib.getExe pkgs.picocom} -b 115200 /dev/$EDK2_DEBUG_UART | ${lib.getExe' pkgs.coreutils "tee"} logs/debug.log"
        ${lib.getExe pkgs.tmux} split-window -v -t 0 "${lib.getExe pkgs.picocom} -b 115200 /dev/$EDK2_AP_UART | ${lib.getExe' pkgs.coreutils "tee"} logs/ap.log"
        ${lib.getExe pkgs.tmux} attach-session -t edk2-console
      '';
    };
    edk2-build = {
      description = "Build Debian package";
      exec = ''
        .github/common/build-deb | ${lib.getExe' pkgs.coreutils "tee"} logs/build.log
      '';
    };
    edk2-install = {
      description = "Copy build artifacts to a thumb disk, require udisk2";
      exec = ''
        set -euo pipefail

        if (($# == 0)); then
          ${lib.getExe' pkgs.coreutils "echo"} "Usage: $(${lib.getExe' pkgs.coreutils "basename"} "$0") </dev/PARTITION>" >&2
          exit 1
        elif [[ ! -b "$1" ]]; then
          ${lib.getExe' pkgs.coreutils "echo"} "Waiting for $1 to be available ..."
        fi

        while [[ ! -b "$1" ]]; do
          ${lib.getExe' pkgs.coreutils "sleep"} 1
        done

        if [[ ! -e debian/edk2-cix/usr/share/edk2/ ]]; then
          ${lib.getExe' pkgs.coreutils "echo"} "No EDK2 artifact available!" >&2
          ${lib.getExe' pkgs.coreutils "echo"} "Have you ran edk2-build?" >&2
          exit 2
        fi

        ${lib.getExe' pkgs.udisks "udisksctl"} mount -b "$1" || ${lib.getExe' pkgs.coreutils "true"}
        MOUNT_POINT="$(${lib.getExe' pkgs.udisks "udisksctl"} info -b "$1" | \
          ${lib.getExe pkgs.gnugrep} MountPoints | \
          ${lib.getExe pkgs.gnused} -E "s/\s*MountPoints:\s*(.*)/\1/")"

        file_count() {
          local f=("$1"/*)
          ${lib.getExe' pkgs.coreutils "echo"} ''${#f[@]}
        }

        if (( $(file_count debian/edk2-cix/usr/share/edk2/) != 1 )); then
          ${lib.getExe' pkgs.coreutils "echo"} "Copying" debian/edk2-cix/usr/share/edk2/ "..."
          ${lib.getExe' pkgs.coreutils "cp"} -a debian/edk2-cix/usr/share/edk2/. "$MOUNT_POINT"
        elif (( $(file_count debian/edk2-cix/usr/share/edk2/*) != 1 )); then
          ${lib.getExe' pkgs.coreutils "echo"} "Copying" debian/edk2-cix/usr/share/edk2/*/ "..."
          ${lib.getExe' pkgs.coreutils "cp"} -a debian/edk2-cix/usr/share/edk2/*/. "$MOUNT_POINT"
        else
          ${lib.getExe' pkgs.coreutils "echo"} "Copying" debian/edk2-cix/usr/share/edk2/*/*/ "..."
          ${lib.getExe' pkgs.coreutils "cp"} -a debian/edk2-cix/usr/share/edk2/*/*/. "$MOUNT_POINT"
        fi

        ${lib.getExe' pkgs.coreutils "sync"} -f "$MOUNT_POINT"

        ${lib.getExe' pkgs.udisks "udisksctl"} unmount -f -b "$1"

        ${lib.getExe' pkgs.coreutils "echo"} "EDK2 artifacts has been copied to $1."
        ${lib.getExe' pkgs.coreutils "echo"} "Please run setup.nsh from UEFI Shell, listed under Boot Manager menu, to install new EDK2 binary."
      '';
    };
  };

  # enterShell = ''
  #   hello
  #   git --version
  # '';

  # https://devenv.sh/tasks/
  # tasks = {
  #   "myproj:setup".exec = "mytool build";
  #   "devenv:enterShell".after = [ "myproj:setup" ];
  # };

  # https://devenv.sh/tests/
  # enterTest = ''
  #   echo "Running tests"
  #   git --version | grep --color=auto "${pkgs.git.version}"
  # '';

  # https://devenv.sh/pre-commit-hooks/
  pre-commit = {
    hooks = {
      commitizen.enable = true;
      shellcheck = {
        enable = true;
        entry = lib.mkForce "${pkgs.shellcheck}/bin/shellcheck -x";
      };
      shfmt.enable = true;
      statix.enable = true;
      typos = {
        enable = true;
        excludes = [
          "theme/highlight.js"
        ];
      };
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
