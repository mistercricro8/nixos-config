{
  ...
}:

let
  # for remote building, nix uses the root user, so the keys under /root/.ssh
  build-authorized-keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCYtYcsQkILXoEtIUx0U/k5iSOxjmEWXZb4uQBiAZna root@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSs855IH6SOzWM4gFROWf7DNza0zsF56JsrcNxNDPbn root@instance-01"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJyzkR8auawdWuIKq7Yrp0kFz/+nfvDKeli4lF+mgfQ root@cricro-laptop"
  ];
  # keys for the user "cricro" on various machines
  owned-keys = [
    # linux
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLTkWDeknXUXuY3Pn47znJ0OOCBDCBZuZH5Q0tFsFr cricro@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKPFlwEmkVmbWX2MTZtgQHQXFHqbIxc5dO4leGX1qFfI cricro@instance-01"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQvMNCGvxpPmwxCBPiOf9o/B5tZymCRBg8Y7wgwsL57 cricro@cricro-laptop"
    # windows
    ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhKGamcAqDuwcnGr/edN8cGfzgsWoO+SZnT6l3tVh1F cricro@cricro-pc
    # android (ugh)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATB/aYqhhK/3O4G0NXvlySGDQudDWRUUO/QEbj6rUy5 u0_a361@localhost"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwZZhjpbVwnQRKzTe9ai1sOa+Vi+91pK4VawPmBstxF u0_a253@localhost"
  ];
  # all the other keys yay yippee
  other-keys = [
    # ryan
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLTHf+kUZZ2hGnox98CgxS4s261huPjL0RPm1yJKHa7 lenovo@USER"
  ];
in
{
  build-authorized-keys = build-authorized-keys;
  owned-keys = build-authorized-keys ++ owned-keys;
  all-keys = build-authorized-keys ++ owned-keys ++ other-keys; # TODO is rec bad for performance?
}
