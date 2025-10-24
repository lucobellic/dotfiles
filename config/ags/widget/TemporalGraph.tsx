import { App, Astal, Gtk, Gdk } from "astal/gtk4";
import { GLib } from "astal";
import chroma from "chroma-js";

interface TemporalGraphProps {
  width?: number;
  height?: number;
  min?: number;
  max?: number;
  sampleIntervalMs?: number;
  background?: string;
  lineColor?: string;
  gradientColors?: string[];
  lineWidth?: number;
  getLatestValue?: () => number | null;
}

export default function TemporalGraph(props: TemporalGraphProps = {}) {
  const {
    width = 160,
    height = 40,
    min = 0,
    max = 100,
    sampleIntervalMs = 1000,
    background = "rgba(0,0,0,0)",
    lineColor = "rgba(0,220,120,1)",
    gradientColors,
    lineWidth = 2,
    getLatestValue,
  } = props;

  const maxSamples = width;
  const samples: number[] = new Array(maxSamples).fill(min);

  function pushSample(v: number) {
    samples.shift();
    samples.push(v);
  }

  const area = new Gtk.DrawingArea({
    widthRequest: width,
    heightRequest: height,
    cssClasses: ["temporal-graph"],
  });

  (area as any).set_draw_func(
    (drawingArea: any, cr: any, w: number, h: number) => {
      cr.setSourceRGBA(...parseCssColor(background, 0));
      cr.rectangle(0, 0, w, h);
      cr.fill();

      cr.setLineWidth(lineWidth);
      cr.setLineJoin(1);
      cr.setLineCap(1);

      const padding = lineWidth;
      const effectiveH = h - 2 * padding;
      const effectiveSamples = Math.min(samples.length, w);
      const xStep = w / (effectiveSamples - 1 || 1);

      if (gradientColors && gradientColors.length > 0) {
        for (let i = 0; i < effectiveSamples - 1; i++) {
          const sampleIdx = samples.length - 1 - i;
          const v = samples[sampleIdx];
          const nextV = samples[sampleIdx - 1];
          const x = w - Math.round(i * xStep);
          const nextX = w - Math.round((i + 1) * xStep);

          if (isFinite(v) && isFinite(nextV)) {
            const t = (v - min) / (max - min);
            const clamped = Math.max(0, Math.min(1, t));
            const y = padding + Math.round(effectiveH - clamped * effectiveH);

            const nextT = (nextV - min) / (max - min);
            const nextClamped = Math.max(0, Math.min(1, nextT));
            const nextY = padding + Math.round(effectiveH - nextClamped * effectiveH);

            const [r, g, b, a] = interpolateGradient(clamped, gradientColors);
            cr.setSourceRGBA(r, g, b, a);

            cr.moveTo(x + 0.5, y + 0.5);
            cr.lineTo(nextX + 0.5, nextY + 0.5);
            cr.stroke();
          }
        }
      } else {
        const [r, g, b, a] = parseCssColor(lineColor, 1);
        cr.setSourceRGBA(r, g, b, a);

        let firstPoint = true;
        for (let i = 0; i < effectiveSamples; i++) {
          const sampleIdx = samples.length - 1 - i;
          const v = samples[sampleIdx];
          const x = w - Math.round(i * xStep);
          if (isFinite(v)) {
            const t = (v - min) / (max - min);
            const clamped = Math.max(0, Math.min(1, t));
            const y = padding + Math.round(effectiveH - clamped * effectiveH);

            if (firstPoint) {
              cr.moveTo(x + 0.5, y + 0.5);
              firstPoint = false;
            } else {
              cr.lineTo(x + 0.5, y + 0.5);
            }
          } else {
            firstPoint = true;
          }
        }

        cr.stroke();
      }
    },
  );

  area.connect("map", () => {
    const tickId = (area as any).add_tick_callback(
      (_widget: any, frameClock: any) => {
        (area as any).queue_draw();
        return true;
      },
    );

    let timeoutId: number | null = null;
    if (getLatestValue) {
      timeoutId = GLib.timeout_add(
        GLib.PRIORITY_DEFAULT,
        sampleIntervalMs,
        () => {
          const v = getLatestValue();
          if (v !== null && v !== undefined && isFinite(v)) {
            pushSample(v);
          } else {
            pushSample(NaN);
          }
          return true;
        },
      );
    }

    (area as any)._temporal_tick_id = tickId;
    (area as any)._temporal_timeout_id = timeoutId;
  });

  area.connect("unmap", () => {
    const tickId = (area as any)._temporal_tick_id;
    if (tickId) {
      (area as any).remove_tick_callback(tickId);
      (area as any)._temporal_tick_id = null;
    }
    const tid = (area as any)._temporal_timeout_id;
    if (tid) {
      GLib.Source.remove(tid);
      (area as any)._temporal_timeout_id = null;
    }
  });

  (area as any).pushValue = (v: number) => pushSample(v);

  return area;
}

function parseCssColor(
  css: string,
  fallbackAlpha = 1,
): [number, number, number, number] {
  try {
    if (!css) return [0, 0, 0, fallbackAlpha];
    const s = css.trim();
    if (s.startsWith("rgba")) {
      const inside = s.slice(s.indexOf("(") + 1, s.lastIndexOf(")"));
      const parts = inside.split(",").map((p) => p.trim());
      return [
        Number(parts[0]) / 255,
        Number(parts[1]) / 255,
        Number(parts[2]) / 255,
        Number(parts[3]),
      ];
    } else if (s.startsWith("rgb")) {
      const inside = s.slice(s.indexOf("(") + 1, s.lastIndexOf(")"));
      const parts = inside.split(",").map((p) => p.trim());
      return [
        Number(parts[0]) / 255,
        Number(parts[1]) / 255,
        Number(parts[2]) / 255,
        fallbackAlpha,
      ];
    } else if (s.startsWith("#")) {
      const hex = s.slice(1);
      const r = parseInt(hex.slice(0, 2), 16) / 255;
      const g = parseInt(hex.slice(2, 4), 16) / 255;
      const b = parseInt(hex.slice(4, 6), 16) / 255;
      return [r, g, b, fallbackAlpha];
    } else {
      return [1, 1, 1, fallbackAlpha];
    }
  } catch {
    return [1, 1, 1, fallbackAlpha];
  }
}

function interpolateGradient(
  t: number,
  colors: string[],
): [number, number, number, number] {
  if (colors.length === 0) return [1, 1, 1, 1];
  if (colors.length === 1) return parseCssColor(colors[0], 1);

  const scale = chroma.scale(colors).mode('lab');
  const color = scale(t);
  const [r, g, b] = color.rgb();
  
  return [r / 255, g / 255, b / 255, 1];
}
