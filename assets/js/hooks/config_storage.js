const ConfigStorage = {
  mounted() {
    const key = `argus_config:${this.el.dataset.email || "default"}`;

    // Always fire restore_config so the server knows config is ready.
    // If nothing is saved, send empty object so defaults are used.
    const saved = localStorage.getItem(key);
    let config = {};
    if (saved) {
      try { config = JSON.parse(saved); } catch (_) {}
    }
    this.pushEvent("restore_config", config);

    // Save config when it changes
    this.handleEvent("config_changed", (config) => {
      localStorage.setItem(key, JSON.stringify(config));
    });
  }
};

export default ConfigStorage;
