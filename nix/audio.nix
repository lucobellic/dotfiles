{ pkgs, ... }:

{
  # PipeWire audio configuration (Ubuntu default)
  # PipeWire provides PulseAudio compatibility layer
  
  # Install PipeWire-optimized audio packages
  home.packages = with pkgs; [
    # PipeWire tools (native)
    pipewire
    wireplumber
    
    # PulseAudio compatibility tools (work with PipeWire)
    pulseaudio # provides pactl, pulseaudio utils
    pavucontrol # GUI volume control
    pulsemixer  # TUI volume control
    
    # ALSA tools
    alsa-utils  # alsamixer, aplay, etc.
    
    # Additional useful audio tools
    helvum      # PipeWire patchbay GUI
    qpwgraph    # Qt PipeWire graph manager
  ];

  # Session variables optimized for PipeWire
  home.sessionVariables = {
    # Let PipeWire handle audio routing
    PULSE_SERVER = "unix:/run/user/1000/pulse/native";
    # Ensure proper PipeWire runtime directory
    PIPEWIRE_RUNTIME_DIR = "/run/user/1000";
  };
}