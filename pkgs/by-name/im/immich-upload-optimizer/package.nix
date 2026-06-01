{
  lib,
  buildGoModule,
  fetchFromGitHub,
  nix-update-script,
}:

buildGoModule rec {
  pname = "immich-upload-optimizer";
  version = "0.5.5";

  src = fetchFromGitHub {
    owner = "miguelangel-nubla";
    repo = "immich-upload-optimizer";
    tag = "v${version}";
    hash = lib.fakeHash;
  };

  vendorHash = lib.fakeHash;

  meta = {
    description = "Automatically optimize files uploaded to Immich in order to save storage space";
    homepage = "https://github.com/miguelangel-nubla/immich-upload-optimizer";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ jullang ]; # TODO: Add yourself in maintainers/maintainer-list.nix
    mainProgram = "immich-upload-optimizer";
  };

  passthru.updateScript = nix-update-script { };
}
