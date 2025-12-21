import Config

config :sample_app,
  spi: [
    bus_config: [sclk: 7, miso: 8, mosi: 9]
  ],
  display_port: [
    width: 320,
    height: 240,
    compatible: "ilitek,ili9342c",
    rotation: 1,
    cs: 43,
    dc: 3,
    reset: 2
  ],
  color_order: :bgr,
  scene: SampleApp.HinomaruScene
