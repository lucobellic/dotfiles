import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { Variable, exec, GLib } from "astal";

interface CoreData {
  core: number;
  usage: number;
  temp: number;
}

function getCpuCores(): CoreData[] {
  try {
    const output = exec(
      `${GLib.get_user_config_dir()}/ags/scripts/cpu-cores.rs`
    );
    const data = JSON.parse(output);
    return data;
  } catch (e) {
    console.error("getCpuCores error:", e);
    return [];
  }
}

const cpuCores = Variable<CoreData[]>([]).poll(1000, getCpuCores);

function CpuCore({ core }: { core: CoreData }) {
  const usageLevel = core.usage / 100;
  const tempLevel = Math.max(0, Math.min(1, (core.temp - 40) / 60));

  return (
    <box cssClasses={["cpu-core"]} vertical spacing={8}>
      <box
        cssClasses={["cpu-usage-bar"]}
        tooltipText={`Core ${core.core}: ${core.usage.toFixed(1)}%`}
      >
        <levelbar
          cssClasses={[`usage-${Math.floor(core.usage / 20)}`]}
          value={usageLevel}
          widthRequest={30}
          heightRequest={5}
          overflow={Gtk.Overflow.HIDDEN}
        />
      </box>
      <box
        cssClasses={["cpu-temp-bar"]}
        tooltipText={`${core.temp.toFixed(1)}°C`}
      >
        <levelbar
          cssClasses={[`temp-${Math.floor((core.temp - 40) / 10)}`]}
          value={tempLevel}
          widthRequest={30}
          heightRequest={5}
          overflow={Gtk.Overflow.HIDDEN}
        />
      </box>
    </box>
  );
}

export default function CpuCores(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM } = Astal.WindowAnchor;

  return (
    <window
      visible
      cssClasses={["CpuCores"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={BOTTOM}
      marginBottom={14}
      layer={Astal.Layer.BOTTOM}
      namespace="ags-background"
      keymode={Astal.Keymode.NONE}
      application={App}
    >
      <box cssClasses={["cpu-cores-container"]} spacing={10}>
        {cpuCores((cores) => cores.map((core) => <CpuCore core={core} />))}
      </box>
    </window>
  );
}
