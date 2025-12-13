{ systems', nixpkgs-stable, ... }:
[
        { name = "Purple-Sunrise";
          modules = [ ./purple.nix  ./purple-hw.nix ];
          system = systems'.x86_64-linux;
        }
        ## backup system:
        { name = "Purple-Sunrise2";
          modules = [ ./purple.nix ./purple2-hw.nix ];
          system = systems'.x86_64-linux;
        }
        { name = "Selene";
          modules = [ ./selene.nix ];
          system = systems'.x86_64-linux;
          nixpkgs = nixpkgs-stable;
        }
        { name = "Kawasaki-Lemon";
          modules = [ ./laptop2.nix ];
          system = systems'.x86_64-linux;
        }
        {
          name = "NixOS-installer";
          modules = [ ./iso.nix ];
          system = systems'.x86_64-linux;
          nixpkgs = nixpkgs-stable;
        }
]
