defmodule SampleApp do
  @spi_config Application.compile_env!(:sample_app, :spi)
  @display_port_options Application.compile_env!(:sample_app, :display_port)
  @scene Application.compile_env!(:sample_app, :scene)

  def start do
    spi_host = :spi.open(@spi_config)

    display_port =
      :erlang.open_port(
        {:spawn, "display"},
        @display_port_options ++ [spi_host: spi_host]
      )

    {:ok, _pid} = @scene.start_link([], display_server: {:port, display_port})

    Process.sleep(:infinity)
  end
end
