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
    return route === "discovery.latest" || route === "discovery.categories" || route === "discovery.top";
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
            overflow: hidden;
            margin-bottom: 16px;
            height: 44px;
            font-size: 0.9rem;
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
            z-index: 10;
            flex-shrink: 0;
            box-shadow: 3px 0 8px rgba(0,0,0,0.15);
          }

          .event-ticker-wrapper {
            flex-grow: 1;
            min-width: 0;
            overflow: hidden;
            position: relative;
            display: flex;
            align-items: center;
          }

          .event-ticker-track {
            display: flex;
            align-items: center;
            gap: 32px;
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
          }

          .event-ticker-item:hover .event-ticker-title {
            color: #1976d2;
            text-decoration: underline;
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
            margin-left: 10px;
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
            }
            .event-ticker-label-text {
              display: none;
            }
            .event-ticker-track {
              gap: 20px;
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
                  <span class="event-ticker-date">{{this.formatDate event.startDate}}</span>
                  <span class="event-ticker-title">{{event.title}}</span>
                  <span class="event-ticker-separator">•</span>
                </a>
              {{/each}}
            </div>
          </div>
        </div>
      {{/if}}
    {{/if}}
  </template>
}
