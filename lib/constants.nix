{
  ...
}:

let
  # for remote building, nix uses the root user, so the keys under /root/.ssh
  buildKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKCYtYcsQkILXoEtIUx0U/k5iSOxjmEWXZb4uQBiAZna root@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBOP5Kv1zW6Pebs29u7yzJS73VtnkkdVGr5yz7ydlAZ0 root@cricro-vm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMJyzkR8auawdWuIKq7Yrp0kFz/+nfvDKeli4lF+mgfQ root@cricro-laptop"
  ];
  # keys for the user "cricro" on various machines
  ownKeys = [
    # linux
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIByLTkWDeknXUXuY3Pn47znJ0OOCBDCBZuZH5Q0tFsFr cricro@cricro-pc"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFemLgqTdnfq/P4v+lkh0XpFhGAyLlD6hwKAUNLeWq4D cricro@cricro-vm"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIQvMNCGvxpPmwxCBPiOf9o/B5tZymCRBg8Y7wgwsL57 cricro@cricro-laptop"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIElGKqHU3uf9R8bBc8eyAV5/ScVmCw/MP8JgOOAXXSqB cricro@cricro-l2"

    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDAtGJ91WYM5E2hL9vGt6Bm8wSGI/uIpg646eyeiHwG+pZ0hZ5PpS28jeRAH9exUl1W0sTtQWACXSzG7l+0Oy95F1wDHOp8ejLxSx0Bu7bfuQiM1NMEv+zCUsk8gDjIhi9BYvayHIxMD9DBfrIhghvRCq1LNso/VJcsS71gOeVbF93633pi9fsb1Yn9HWEXYMKLrbNN/URhSisqG0xLDNygcEulH3WKAGCgog9uvmyqtfa1KmTU3090PJ/KyGCMEhuYqdHuC+wuUzwA0iyvxpc5LVtk264EFMZxwSYtIDj92htDSTUz6LbHT4PGOatI8qTWQV9B8h7pkN7BYSHe/tkIbNvZleehXOrgFfAXL64Xf7ouTS3B6BYT8O65ZcCCr54SSrGl4YcH30Yll5A3sLK/5zrWKIIfXAcW9LuDVm2R6nb4nENDoEKRFlH1fHV7TsxGKgZwc1p9tjJOA+ai0vpzKAtzCj3K3fs2+9QlFCydvI7RKgCda6+sPdWjFkCeQ3U= cricro@cricro-pc"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDMNMTUNueGJKlS9d2cKlEXTrYZkyzhJYEZCwv1yiNfyrdGD73bEflQGgo++Nc49N0Vbu1BXqMjhsS+mgmVmYfVwDJmp+zm7qOMJ5BfWLdPGZct0FoEKd5zxCMz8M+q+Y6Kd1O5tRZYGUDJWtORIskYhnP9tzbKhJ8lAHVU5063fgtcMED5MyqfBm/LrordsRxgDaiS3kygqvzYYIBXSSHzt8IbLZ19S0zV/fpTs2t38wjephPrdO0iSzy0TVAsaOk6Fz+0xqT6dB+B9lY0QO4ekQtSyRvEcDH8zGQGxBpti2XrAUPlQ8zY5vA2cEjGsb+GimgYOCGTBz/9UfV6EObofDclS5A8BWX86QRPsuncNOqc3UwnAFCuYXJc4Cb1+CXkPLCO1KAwEIxBuy+PZ/naOs9L6edeDc16F4/4wG441P/l/FUx/8Igen/jGqrm/Wieoc0qiqKkbCllKFl28WZbsGrYjl79FBbw69Mv5XNKonUmEGDC/arzMMNwBjYSao8= cricro@cricro-laptop"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDALNnnFzUr5IPzjgVUibIfgSCzu4KddueAdJ21+ckNPlKS4bLPXFmP4ksIFN6oGn/BnnNld93U+c2KnTRX383jDMjitfkgUQwfOaB0/x/zFO2uL6PHxYAgsD2SLFccbZGte7p2CIpxRaA6NWjOpb8IjPBCzxC8RsWCWPR0yr1xRYwrn+V+L2q6xvF+32UflE/Q4pnzTkrY0Y0ivnUAZHpPEEOd62KChFfFso904aSlhMxGAgyPEe5+tcR1kajwIykiJIKsd94CabpbJMw60ugerrWOwp6INGrcdVHrVRpVvSn0p9hVRq8G5u/uf7UHsalAJuWWxJI/9PVlTlkgrzrCUIHfmMXk1Xaaxv0HP36MOKR4VN1XGpLfOcyMRoIpd9bQpzhLk8jrzirl2/6ztXzk6yQJUMkmR4btCBj5voFHEuagNyc5e0HfgFlL2njPyyLhzwW7gUna/+P9pPyis8AP9huFIHrru/JF7uQ5WQo4TtYbW/VeSEdvsRuYvIDGom0= cricro@cricro-vm"
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCdDrg2+Utj8bDl4rxShpMY0KM7AHRG6Fbn+afiRiz1wO/2d8InbS1uPRbBNic3+wGDdZilYMLGoiJSMZsCV54e6PQSRryH8KzPsd1HVF+lvZ94m2vrHxHeA04uAByjJHMyc6AKnKCvbeDS5fLX1nEDMNQAw48vCwZA6nj52FBvDEOTznCADXXUxCJFhDlu/HIB/6HBUlvgVcDhYWnGIQtGSBiuzDqHZCYjSzjNfnOsyA8oSRlmWC936ce4MWRQkby3etaUTHKNbjO1rphFrDO2O45FrAnJxhupTrJzMl6J3OkHGVKCtg1iNMsQjHIBfcbXnJHVdQ5SqJu2GkRtCSfQZNLLjTrj+ELRbo9s6cmTf15/bQpul8SU6W1g/v5OhZaUZM47U+pt+f/5i++X8pu4tPjVhuPA2O3UsApP78WFXsAn9gHPo5Cu1lBjaMnsc7n/zfg5gKFmXinJx6P9bel/BXo5sWFaqYTuk2FMjQarjkuXLI6jMQglDJHf2fHWqzM= cricro@cricro-l2"

    # windows
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMhKGamcAqDuwcnGr/edN8cGfzgsWoO+SZnT6l3tVh1F cricro@cricro-pc"
    # android (ugh)
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIATB/aYqhhK/3O4G0NXvlySGDQudDWRUUO/QEbj6rUy5 u0_a361@localhost"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAwZZhjpbVwnQRKzTe9ai1sOa+Vi+91pK4VawPmBstxF u0_a253@localhost"
  ];
  # all the other keys yay yippee
  otherKeys = [
    # ryan
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLTHf+kUZZ2hGnox98CgxS4s261huPjL0RPm1yJKHa7 lenovo@USER"
  ];
in
{
  sshConfig = {
    buildKeys = buildKeys;
    ownKeys = buildKeys ++ ownKeys;
    allKeys = buildKeys ++ ownKeys ++ otherKeys;
  };
}
