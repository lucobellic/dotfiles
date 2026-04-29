interface Category {
  id: string;
  name: string;
  icon: string;
}

interface LinkItem {
  name: string;
  url: string;
  icon: string;
}

type Settings = {
  userName: string;
  colorScheme: string;
  theme: string;
  colorMode: string;
  timeFormat: string;
  showSeconds: string;
  tempUnit: string;
  showQuotes: string | null;
  enabledEngines: string[];
  preferredEngine: string;
  weatherLocation: string;
  openWeatherApiKey: string | null;
  linkBehavior: string;
  showKeyboardHints: string;
  footerLeft: string;
  footerCenter: string;
  footerRight: string;
};

interface SipConfig {
  categories?: Category[];
  links?: Record<string, LinkItem[]>;
  settings?: Partial<Settings>;
}

(async function (): Promise<void> {
  // Always overwrite categories and links with our custom configuration
  console.log("Sip-StartPage: Loading configuration from config.json...");

  try {
    const response = await fetch("/config.json");
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const config: SipConfig = await response.json();

    // Always load categories (overwrites defaults/previous)
    if (config.categories) {
      localStorage.setItem("categories", JSON.stringify(config.categories));
      console.log("Sip-StartPage: Categories loaded");
    }

    // Always load links (overwrites defaults/previous)
    if (config.links) {
      localStorage.setItem("links", JSON.stringify(config.links));
      console.log("Sip-StartPage: Links loaded");
    }

    // Load settings only if not already set (preserve user customization)
    if (config.settings) {
      Object.entries(config.settings).forEach(
        ([key, value]: [string, Settings[keyof Settings]]) => {
          if (!localStorage.getItem(key)) {
            if (typeof value === "object" && value !== null) {
              localStorage.setItem(key, JSON.stringify(value));
            } else if (value !== null && value !== undefined) {
              localStorage.setItem(key, String(value));
            }
          }
        },
      );
      console.log("Sip-StartPage: Settings loaded");
    }

    console.log("Sip-StartPage: Configuration initialized successfully");
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    console.warn("Sip-StartPage: Failed to load config.json -", message);
  }
})();
