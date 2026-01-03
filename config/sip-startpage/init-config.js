(async function() {
  // Always overwrite categories and links with our custom configuration
  console.log('Sip-StartPage: Loading configuration from config.json...');

  try {
    const response = await fetch('/config.json');
    if (!response.ok) {
      throw new Error(`HTTP ${response.status}: ${response.statusText}`);
    }

    const config = await response.json();

    // Always load categories (overwrites defaults/previous)
    if (config.categories) {
      localStorage.setItem('categories', JSON.stringify(config.categories));
      console.log('Sip-StartPage: Categories loaded');
    }

    // Always load links (overwrites defaults/previous)
    if (config.links) {
      localStorage.setItem('links', JSON.stringify(config.links));
      console.log('Sip-StartPage: Links loaded');
    }

    // Load settings only if not already set (preserve user customization)
    if (config.settings) {
      Object.entries(config.settings).forEach(([key, value]) => {
        if (!localStorage.getItem(key)) {
          if (typeof value === 'object') {
            localStorage.setItem(key, JSON.stringify(value));
          } else {
            localStorage.setItem(key, String(value));
          }
        }
      });
      console.log('Sip-StartPage: Settings loaded');
    }

    console.log('Sip-StartPage: Configuration initialized successfully');
  } catch (error) {
    console.warn('Sip-StartPage: Failed to load config.json -', error.message);
  }
})();
