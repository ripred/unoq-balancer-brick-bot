from pathlib import Path

paths = [
    Path("/home/arduino/ArduinoApps/balancing_bot_app/python/arduino/app_bricks/balancing_robot/__init__.py"),
    Path("/home/arduino/ArduinoApps/balancing_robot/python/arduino/app_bricks/balancing_robot/__init__.py"),
]

for path in paths:
    text = path.read_text()
    if "axis_sign" in text:
        continue

    text = text.replace("self.axis_mode = \"pitch\"\n", "self.axis_mode = \"pitch\"\n        self.axis_sign = 1\n")

    text = text.replace(
        '"axis_mode": self.axis_mode,\n',
        '"axis_mode": self.axis_mode,\n                "axis_sign": self.axis_sign,\n'
    )

    text = text.replace(
        'ui.on_message("set_axis_mode", self._on_set_axis_mode)\n        ui.on_message("set_mode", self._on_set_mode)\n',
        'ui.on_message("set_axis_mode", self._on_set_axis_mode)\n        ui.on_message("set_axis_sign", self._on_set_axis_sign)\n        ui.on_message("set_mode", self._on_set_mode)\n'
    )

    text = text.replace(
        "def http_set_axis_mode(self, axis_mode=None) -> Dict[str, Any]:\n        self._on_set_axis_mode(None, {\"axis_mode\": axis_mode})\n        return self.get_state()[\"config\"]\n\n    def http_set_mode",
        "def http_set_axis_mode(self, axis_mode=None) -> Dict[str, Any]:\n        self._on_set_axis_mode(None, {\"axis_mode\": axis_mode})\n        return self.get_state()[\"config\"]\n\n    def http_set_axis_sign(self, axis_sign=None) -> Dict[str, Any]:\n        self._on_set_axis_sign(None, {\"axis_sign\": axis_sign})\n        return self.get_state()[\"config\"]\n\n    def http_set_mode"
    )

    text = text.replace(
        "def _on_set_axis_mode(self, _client, data) -> None:\n        axis = data.get(\"axis_mode\")\n        if axis:\n            self.axis_mode = str(axis)\n            if not self.simulated:\n                self._bridge_notify(\"set_axis_mode\", self.axis_mode)\n            self._send_config()\n\n    def _on_set_mode",
        "def _on_set_axis_mode(self, _client, data) -> None:\n        axis = data.get(\"axis_mode\")\n        if axis:\n            self.axis_mode = str(axis)\n            if not self.simulated:\n                self._bridge_notify(\"set_axis_mode\", self.axis_mode)\n            self._send_config()\n\n    def _on_set_axis_sign(self, _client, data) -> None:\n        sign = data.get(\"axis_sign\")\n        if sign is None:\n            return\n        try:\n            self.axis_sign = -1 if int(sign) < 0 else 1\n        except (ValueError, TypeError):\n            self.axis_sign = 1\n        if not self.simulated:\n            self._bridge_notify(\"set_axis_sign\", self.axis_sign)\n        self._send_config()\n\n    def _on_set_mode"
    )

    text = text.replace(
        "self._bridge_notify(\"set_axis_mode\", self.axis_mode)",
        "self._bridge_notify(\"set_axis_mode\", self.axis_mode)\n            self._bridge_notify(\"set_axis_sign\", self.axis_sign)"
    )

    path.write_text(text)
