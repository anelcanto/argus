const PinStorage = {
  mounted() {
    const key = `argus_pins:${this.el.dataset.email || "default"}`;

    // Restore pinned PRs on mount
    const saved = localStorage.getItem(key);
    if (saved) {
      try {
        const pins = JSON.parse(saved);
        this.pushEvent("restore_pins", { pins });
      } catch (_) {}
    }

    // Save pins when they change
    this.handleEvent("pins_changed", ({ pins }) => {
      localStorage.setItem(key, JSON.stringify(pins));
    });
  }
};

export default PinStorage;
