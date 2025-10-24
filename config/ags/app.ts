import { App } from "astal/gtk4";
import style from "./style.scss";
import CpuCores from "./widget/CpuCores";
import CpuGraph from "./widget/CpuGraph";

App.start({
  css: style,
  main() {
    App.get_monitors().map(CpuCores);
    // App.get_monitors().map(CpuGraph);
  },
});
