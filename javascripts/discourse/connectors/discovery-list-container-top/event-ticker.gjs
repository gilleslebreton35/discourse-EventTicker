import Component from "@glimmer/component";
import { tracked } from "@glimmer/tracking";
import { action } from "@ember/object";
import { service } from "@ember/service";
import { ajax } from "discourse/lib/ajax";

export default class EventTicker extends Component {
  @service router;
  @tracked events = [];
  @tracked isLoading = true;

  constructor() {
    super(...arguments);
    this.loadEvents();
  }

  get isHomepage() {
    if (!this.router || !this.router.currentRouteName) return false;
    const route = this.router.currentRouteName;
    return (
      route === "discovery.latest" ||
      route === "discovery.categories" ||
      route === "discovery.top"
    );
  }

  @action
  async loadEvents() {
    try {
      const rawData = await ajax("/tablejeu/map.json");
      const dataList = Array.isArray(rawData) ? rawData : (rawData.tablejeu || []);

      const today = new Date();
      today.setHours(0, 0, 0, 0);

      const upcoming = dataList
        .map((item) => ({
          id: item.topic_id,
          url: item.url,
          title: item.title,
          // Récupération automatique de l'image selon les clés les plus courantes
          imageUrl:
            item.image_url ||
            item.game_image ||
            item.image ||
            item.thumbnail_url ||
            item.cover_url ||
            null,
          startDate: new Date(item.start_at),
          timestamp: item.start_at ? new Date(item.start_at).getTime() : 0,
        }))
        .filter((e) => e.timestamp >= today.getTime())
        .sort((a, b) => a.timestamp - b.timestamp)
        .slice(0, 10);

      this.events = upcoming;
    } catch (e) {
      console.error("Erreur chargement bandeau défilant :", e);
    } finally {
      this.isLoading = false;
    }
  }

  formatDate(date) {
    if (!date) return "";
    return new Intl.DateTimeFormat("fr-FR", {
      day: "numeric",
      month: "short",
    }).format(date);
  }

  get tickerItems() {
    if (!this.events.length) return [];
    return [...this.events, ...this.events];
  }

  <template>
    {{#if this.isHomepage}}
      {{#if this.events.length}}
        <style>
          .event-ticker-container {
            display: flex;
            align-items: stretch;
            width: 100%;
            max-width: 100%;
            box-sizing: border-box;
            background: var(--tertiary-low, #eaf2ff);
            border: 1px solid var(--tertiary-medium, #b3d4ff);
            border-radius: 8px;
            /* Coupe ce qui dépasse à gauche/droite, mais laisse le zoom sortir en haut/bas */
            overflow-x: clip;
            overflow-y: visible;
            margin-bottom: 16px;
            height: 44px;
            font-size: 0.9rem;
            position: relative;
            z-index: 20;
          }

          .event-ticker-label {
            background: #1976d2;
            color: #ffffff;
            font-weight: 700;
            padding: 0 16px;
            display: flex;
            align-items: center;
            white-space: nowrap;
            position: relative;
            z-index: 35;
            flex-shrink: 0;
            border-radius: 7px 0 0 7px;
            box-shadow: 3px 0 8px rgba(0,0,0,0.15);
          }

          .event-ticker-wrapper {
            flex-grow: 1;
            min-width: 0;
            overflow-x: clip;
            overflow-y: visible;
            position: relative;
            display: flex;
            align-items: center;
          }

          .event-ticker-track {
            display: flex;
            align-items: center;
            gap: 20px;
            white-space: nowrap;
            padding-left: 20px;
            will-change: transform;
            animation: ticker-scroll 35s linear infinite;
          }

          .event-ticker-container:hover .event-ticker-track {
            animation-play-state: paused;
          }

          .event-ticker-item {
            display: inline-flex;
            align-items: center;
            gap: 8px;
            color: var(--primary);
            text-decoration: none !important;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 8px;
            position: relative;
            z-index: 1;
            transition:
              transform 0.2s cubic-bezier(0.25, 0.8, 0.25, 1),
              background-color 0.2s ease,
              box-shadow 0.2s ease;
          }

          /* Agrandissement du bloc complet (texte + date) au survol */
          .event-ticker-item:hover {
            transform: scale(1.18);
            background: var(--secondary, #ffffff);
            box-shadow: 0 4px 14px rgba(0, 0, 0, 0.18);
            z-index: 30;
          }

          .event-ticker-item:hover .event-ticker-title {
            color: #1976d2;
          }

          .event-ticker-img {
            width: 28px;
            height: 28px;
            object-fit: cover;
            border-radius: 4px;
            flex-shrink: 0;
            border: 1px solid var(--tertiary-medium, #b3d4ff);
            background: var(--secondary);
            /* S'agrandit vers la gauche pour ne pas recouvrir la date */
            transform-origin: right center;
            transition:
              transform 0.2s cubic-bezier(0.25, 0.8, 0.25, 1),
              box-shadow 0.2s ease;
          }

          /* Zoom supplémentaire sur l'image au survol */
          .event-ticker-item:hover .event-ticker-img {
            transform: scale(1.8);
            box-shadow: 0 4px 10px rgba(0, 0, 0, 0.3);
          }

          .event-ticker-date {
            background: var(--secondary);
            color: #1976d2;
            font-weight: 800;
            font-size: 0.75rem;
            padding: 3px 8px;
            border-radius: 12px;
            border: 1px solid var(--tertiary-medium);
            text-transform: capitalize;
          }

          .event-ticker-separator {
            color: var(--primary-low-mid);
            user-select: none;
          }

          @keyframes ticker-scroll {
            0% { transform: translateX(0); }
            100% { transform: translateX(-50%); }
          }

          @media (max-width: 767px) {
            .event-ticker-container {
              height: 38px;
              font-size: 0.85rem;
              margin-bottom: 12px;
              border-radius: 6px;
            }
            .event-ticker-label {
              padding: 0 12px;
              border-radius: 5px 0 0 5px;
            }
            .event-ticker-label-text {
              display: none;
            }
            .event-ticker-track {
              gap: 14px;
            }
            .event-ticker-img {
              width: 24px;
              height: 24px;
            }
          }
        </style>

        <div class="event-ticker-container">
          <div class="event-ticker-label">
            📢 <span class="event-ticker-label-text" style="margin-left: 6px;">Prochains événements</span>
          </div>

          <div class="event-ticker-wrapper">
            <div class="event-ticker-track">
              {{#each this.tickerItems as |event|}}
                <a href={{event.url}} class="event-ticker-item">
                  {{#if event.imageUrl}}
                    <img src={{event.imageUrl}} alt={{event.title}} class="event-ticker-img" loading="lazy" />
                  {{/if}}
                  <span class="event-ticker-date">{{this.formatDate event.startDate}}</span>
                  <span class="event-ticker-title">{{event.title}}</span>
                </a>
                <span class="event-ticker-separator">•</span>
              {{/each}}
            </div>
          </div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
