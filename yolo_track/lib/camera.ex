defmodule YoloTrack.Camera do
  use GenServer
  alias Phoenix.PubSub

  alias YoloTrack.Trackers.SimpleTracker

  def start_link(options \\ []) do
    GenServer.start_link(__MODULE__, 0, name: __MODULE__)
  end

  def init(device_id) do
    cap = Evision.VideoCapture.videoCapture(device_id)
    true = Evision.VideoCapture.isOpened(cap)
    model = YOLO.load(model_path: "yolo11m.onnx", classes_path: "coco_classes.json", eps: [:coreml] )
    fps = if is_number(cap.fps) and cap.fps > 0, do: cap.fps, else: 30.0
    interval_ms = max(1, trunc(1000 / fps))

    tracker = SimpleTracker.new()

    {:ok, %{cap: cap, frame: nil, interval_ms: interval_ms, model: model, tracker: tracker}, {:continue, :read_next}}
  end

  def handle_continue(:read_next, state) do
    new_state = read_and_update(state)
    Process.send_after(self(), :read_next, new_state.interval_ms)
    {:noreply, new_state}
  end

  def handle_info(:read_next, state) do
    new_state = read_and_update(state)
    Process.send_after(self(), :read_next, 1)
    {:noreply, new_state}
  end

  defp read_and_update(state) do
    case Evision.VideoCapture.read(state.cap) do
      %Evision.Mat{} = frame ->
        objs = get_objects(frame, state.model)
        {tracker, _events} = SimpleTracker.update(state.tracker, objs, now_ms())
        broadcast(frame, tracker.tracks)
        %{state | frame: frame, tracker: tracker}

      _ ->
        state
    end
  end

  defp get_objects(mat, model) do
    model
    |> YOLO.detect(mat, prob_threshold: 0.5)
    |> YOLO.to_detected_objects(model.classes)
    ##### FILTERING ONLY PEOPLE
    |> Enum.filter(& &1.class_idx == 0)
  end

  defp broadcast(frame, tracks) do
    PubSub.broadcast(YoloTrack.PubSub, "camera", {:camera_frame, frame, tracks})
  end

  defp now_ms do
    :millisecond
    |> DateTime.utc_now()
    |> DateTime.to_unix(:millisecond)
  end
end
