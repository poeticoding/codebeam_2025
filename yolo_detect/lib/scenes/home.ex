defmodule YoloTrack.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Phoenix.PubSub
  alias Scenic.Graph
  alias Scenic.Assets.Stream, as: ScenicStream

  import Scenic.Primitives
  # import Scenic.Components

  @note """
    This is a very simple starter application.

    If you want a more full-on example, please start from:

    mix scenic.new.example
  """

  @text_size 24

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _param, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size
    PubSub.subscribe(YoloTrack.PubSub, "camera")

    # show the version of scenic and the glfw driver
    scenic_ver = Application.spec(:scenic, :vsn) |> to_string()
    driver_ver = Application.spec(:scenic_driver_local, :vsn) |> to_string()

    info = "scenic: v#{scenic_ver}\nscenic_driver_local: v#{driver_ver}"

    graph =
      Graph.build()
      |> rect({width, height}, fill: {:stream, "camera"})
      |> group(fn g -> g end, id: :bbox)
      # |> add_specs_to_graph([
      #   rect_spec({width, height})
      # ])

    scene =
      scene
      |> assign(graph: graph, size: {width, height})
      |> push_graph(graph)

    {:ok, scene}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

  def handle_info({:camera_frame, orig_mat, tracks, time_ms}, scene) do
    # rgb = Evision.cvtColor(mat, Evision.Constant.cv_COLOR_BGR2RGB())
    {width, height} = scene.viewport.size
    mat = Evision.resize(orig_mat, {width, height})
    bin = Evision.imencode(".png", mat)
    {:ok, stream_image} = ScenicStream.Image.from_binary(bin)
    :ok = ScenicStream.put("camera", stream_image)

    # --- rebuild only the bbox overlay group ---

    graph =
      scene.assigns.graph
      |> Graph.delete(:bbox)
      |> group(fn g ->
        ## BBOXES
        Enum.reduce(tracks, g, fn %{class: class_name, bbox: bbox, prob: prob}=_detected_object, g ->
          {x, y, w, h} = rescale_bbox(bbox, scene.viewport.size, Evision.Mat.shape(orig_mat))
          prob = round(prob * 100)
          g
          |> rect({w, h}, stroke: {2, :lime}, translate: {x, y})
          |> text("#{class_name} - #{prob}", font_size: 15, translate: {x + 4, y - 6})
        end)
        ### FPS
        |> rect({150, 50}, fill: :black, translate: {width - 150, height - 50})
        |> text(
          "#{time_ms} ms - #{round(1_000/time_ms)}fps",
          font_size: 22,

          fill: :white,
          translate: {width - 12, height - 12},
          text_align: :right
        )
      end, id: :bbox)


    scene = assign(scene, graph: graph)
    push_graph(scene, graph)
    {:noreply, scene}

  end

  # returns {x, y, w, h}
  defp rescale_bbox(bbox, {width, height}=_viewport_size, {orig_h, orig_w, _}=_mat_shape) do
    w_scale = width/orig_w
    h_scale = height/orig_h
    cx = bbox.cx * w_scale
    cy = bbox.cy * h_scale
    w = bbox.w * w_scale
    h = bbox.h * h_scale

    x = round(cx - w / 2)
    y = round(cy - h / 2)
    w = round(w)
    h = round(h)

    {x, y, w, h}
  end

end
