import { withPluginApi } from "discourse/lib/plugin-api";
import EventTicker from "../components/event-ticker";

export default {
  name: "setup-event-ticker",
  initialize() {
    withPluginApi("1.8.0", (api) => {
      api.renderInOutlet("above-main-container", EventTicker);
    });
  },
};
