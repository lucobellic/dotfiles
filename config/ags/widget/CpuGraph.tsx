import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { Variable, exec, GLib } from "astal";
import TemporalGraph from "./TemporalGraph";

interface CoreData {
  core: number;
  usage: number;
  temp: number;
}

function getCpuCores(): CoreData[] {
  try {
    const output = exec(
      `${GLib.get_user_config_dir()}/ags/scripts/cpu-cores.rs`,
    );
    const data = JSON.parse(output);
    return data;
  } catch (e) {
    console.error("getCpuCores error:", e);
    return [];
  }
}

const cpuCores = Variable<CoreData[]>([]).poll(1000, getCpuCores);

export default function CpuGraph(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM } = Astal.WindowAnchor;

  const graphRefs: any[] = [];
  const coreCount = 16;

  const window = (
    <window
      visible
      cssClasses={["CpuGraph"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={BOTTOM}
      marginBottom={14}
      layer={Astal.Layer.BOTTOM}
      namespace="ags-cpu-graph"
      keymode={Astal.Keymode.NONE}
      application={App}
    >
      <box cssClasses={["cpu-graph-container"]} spacing={10}>
        {Array.from({ length: coreCount }, (_, idx) => {
          const usageGraph = TemporalGraph({
            width: 30,
            height: 8,
            min: 0,
            max: 100,
            sampleIntervalMs: 1000,
            background: "rgba(0,0,0,0)",
            gradientColors: [
              "rgba(100,150,220,1)",
              "rgba(220,220,0,1)",
              "rgba(220,50,0,1)",
            ],
            lineWidth: 1,
          });
          const tempGraph = TemporalGraph({
            width: 30,
            height: 8,
            min: 40,
            max: 100,
            sampleIntervalMs: 1000,
            background: "rgba(0,0,0,0)",
            gradientColors: [
              "rgba(100,150,220,1)",
              "rgba(220,220,0,1)",
              "rgba(220,50,0,1)",
            ],
            lineWidth: 1,
          });
          graphRefs[idx * 2] = usageGraph;
          graphRefs[idx * 2 + 1] = tempGraph;

          return (
            <box cssClasses={["cpu-core-graph"]} vertical spacing={8}>
              <box
                cssClasses={["cpu-usage-graph"]}
                tooltipText={`Core ${idx} Usage`}
              >
                {usageGraph}
              </box>
              <box
                cssClasses={["cpu-temp-graph"]}
                tooltipText={`Core ${idx} Temp`}
              >
                {tempGraph}
              </box>
            </box>
          );
        })}
      </box>
    </window>
  );

  cpuCores.subscribe((cores) => {
    cores.forEach((core, idx) => {
      if (graphRefs[idx * 2]) {
        graphRefs[idx * 2].pushValue(core.usage);
      }
      if (graphRefs[idx * 2 + 1]) {
        graphRefs[idx * 2 + 1].pushValue(core.temp);
      }
    });
  });

  const currentCores = cpuCores.get();
  currentCores.forEach((core, idx) => {
    if (graphRefs[idx * 2]) {
      graphRefs[idx * 2].pushValue(core.usage);
    }
    if (graphRefs[idx * 2 + 1]) {
      graphRefs[idx * 2 + 1].pushValue(core.temp);
    }
  });

  return window;
}
