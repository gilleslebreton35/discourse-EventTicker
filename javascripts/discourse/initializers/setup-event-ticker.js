import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "setup-event-ticker",
  initialize() {
    withPluginApi("1.8.0", (api) => {
      // "above-main-container" affiche le bandeau juste en haut de la liste des sujets sur l'accueil
      api.renderInOutlet("above-main-container", "event-ticker");
    });
  },
};
