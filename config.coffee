#
# buld environment & misc settings
#-------------------------------------------
module.exports =
  release: "#{process.env.HOME}/Dropbox/Share/NKS Presets"
  chunkVer: 1
  json_indent: 2
  # gulp-exec options
  execOpts:
    continueOnError: false # default = false, true means don't emit error event
    pipeStdout: false      # default = false, true means stdout is written to file.contents
  execReportOpts:
    err: true              # default = true, false means don't write err
    stderr: true           # default = true, false means don't write stderr
    stdout: true           # default = true, false means don't write stdout

  fxpPresets: '~/Documents/Music/Presets/fxp'

  # Native Instruments
  #-------------------------------------------
  NI:
    # content: '/Users/Shared'
    content: '~/Music/Native Instruments'
    userContent: "#{process.env.HOME}/Documents/Native Instruments/Custom NKS"
    resources: '/Users/Shared/NI Resources'

  #
  # Ableton Live
  #-------------------------------------------
  Ableton:
    racks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Instruments/Instrument Rack"
    drumRacks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Instruments/Drum Rack"
    effectRacks: "#{process.env.HOME}/Music/Ableton/User Library/Presets/Audio Effects/Audio Effect Rack"
    vstPresets: "#{process.env.HOME}/Music/Ableton/User Library/VstPresets"
    defaults: "#{process.env.HOME}/Music/Ableton/User Library/Defaults/Plug-In Configurations/VSTs"
    vst3Defaults: "#{process.env.HOME}/Music/Ableton/User Library/Defaults/Plug-In Configurations/VST3s"

  #
  # AU Presets
  #-------------------------------------------
  AuPresets: "#{process.env.HOME}/Library/Audio/Presets"

  #
  # Bitwig Studio
  #-------------------------------------------
  Bitwig:
    presets: "#{process.env.HOME}/Documents/Bitwig Studio/Library/Presets"

