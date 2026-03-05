const ConfigStorage = {
  mounted() {
    const key = `argus_config:${this.el.dataset.email || "default"}`;

    // Restore saved filters on mount
    const saved = localStorage.getItem(key);
    if (saved) {
      try {
        const config = JSON.parse(saved);
        this.pushEvent("restore_config", config);
      } catch (_) {}
    }

    // Save config when it changes
    this.handleEvent("config_changed", (config) => {
      localStorage.setItem(key, JSON.stringify(config));
    });
  }
};

export default ConfigStorage;
