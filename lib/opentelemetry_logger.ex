defmodule OpentelemetryLogger do
  @moduledoc """
  Documentation for `OpentelemetryLogger`.
  """
  alias Opentelemetry.Proto.Common.V1.AnyValue
  alias Opentelemetry.Proto.Collector.Logs.V1.LogsService
  alias Opentelemetry.Proto.Common.V1.KeyValue
  alias Opentelemetry.Proto.Logs.V1.SeverityNumber
  alias Opentelemetry.Proto.Logs.V1.ResourceLogs
  alias Opentelemetry.Proto.Resource.V1.Resource
  alias Opentelemetry.Proto.Collector.Logs.V1.ExportLogsServiceRequest
  alias Opentelemetry.Proto.Logs.V1.ScopeLogs

  @behaviour :gen_event

  def init(_initArgs) do
    {:ok, channel} = GRPC.Stub.connect("localhost:4317")
    dbg(channel)
    {:ok, %{channel: channel}}
  end

  def handle_event({level, _group_leader, {Logger, message, timestamp, _metadata}}, state) do
    {{y, m, d}, {hh, mm, ss, us}} = timestamp
    timestamp =
      NaiveDateTime.from_erl!({{y, m, d}, {hh, mm, ss}}, us)
      |> DateTime.from_naive!("Etc/UTC")
      |> DateTime.to_unix(:nanosecond)

    dbg(message)

    channel = state.channel
    #request = ExportLogsServiceRequest.new()
    request = %ExportLogsServiceRequest{
      resource_logs: [%ResourceLogs{
        resource: %Resource{
          attributes: [],
          dropped_attributes_count: 0,
        },
        scope_logs: [%ScopeLogs{
          scope: Opentelemetry.Proto.Common.V1.InstrumentationScope.new(),
          log_records: [
            %Opentelemetry.Proto.Logs.V1.LogRecord{
              time_unix_nano: timestamp,
              observed_time_unix_nano: timestamp,
              severity_number: 0,
              severity_text: to_string(level),
              body: AnyValue.new(value: {:string_value, message}),
              attributes: [],
              dropped_attributes_count: 0,
              flags: 0,
              trace_id: <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16>>,
              span_id: <<1, 2, 3, 4, 5, 6, 7, 8>>,
            }
          ],
          schema_url: ""
        }],
        schema_url: ""
      }],
    }
    LogsService.Stub.export(channel, request)
    |> dbg()

    Process.sleep(1000)
    {:ok, state}
  end

  def terminate(_args, state) do
    {:ok, _} = GRPC.Stub.disconnect(state.channel)
    {:stop, :normal}
  end
end
