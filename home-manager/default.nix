{ systems', ... }:
[
  { name = "daniel@Purple-Sunrise";
    modules = [ ./purple.nix ];
    system = systems'.x86_64-linux;
  }
  { name = "daniel@Kawasaki-Lemon";
    modules = [ ./laptop.nix ];
    system = systems'.x86_64-linux;
  }
]
