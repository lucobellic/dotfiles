import { App, Astal, Gtk, Gdk } from "astal/gtk4";

export default function TestWindow(gdkmonitor: Gdk.Monitor) {
  const { BOTTOM } = Astal.WindowAnchor;

  return (
    <window
      visible
      cssClasses={["TestWindow"]}
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.NORMAL}
      anchor={BOTTOM}
      marginBottom={100}
      layer={Astal.Layer.TOP}
      application={App}
    >
      <box>
        <label label="TEST WINDOW" />
      </box>
    </window>
  );
}
