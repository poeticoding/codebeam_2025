# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
import Config

# connect the app's asset module to Scenic
config :scenic, :assets, module: YoloTrack.Assets

# Configure the main viewport for the Scenic application
config :yolo_track, :viewport,
  name: :main_viewport,
  size: {960, 540},
  theme: :dark,
  default_scene: YoloTrack.Scene.Home,
  drivers: [
    [
      module: Scenic.Driver.Local,
      name: :local,
      window: [resizeable: false, title: "yolo_track"],
      on_close: :stop_system
    ]
  ]

config :nx,
  default_backend: {EXLA.Backend, client: :host},
  default_defn_options: [compiler: EXLA]


config :ortex, Ortex.Native, features: [:coreml]

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "prod.exs"
