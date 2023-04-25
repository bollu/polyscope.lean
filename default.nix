with import <nixpkgs> {};
stdenv.mkDerivation {
  name = "lean.sdl";
  # If you need libraries, list them here
  buildInputs = [ nodejs SDL2 SDL2.dev pkg-config xorg.libpthreadstubs];
}


