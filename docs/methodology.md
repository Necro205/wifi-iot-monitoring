# Methodology

This document describes the measurement protocol, data processing choices, and analytical methods used in this project.

## 1. Measurement setup

### Hardware

- **Sensing device:** one smartphone (Android)
- **Scanning app:** publicly available WiFi scanner app (the project follows the "alternative approach" option of the assignment brief, which explicitly allows using an existing application rather than developing a custom one)

### Location selection

Five measurement points were chosen to span a deliberately wide range of physical contexts:

| # | Name | Characterization |
|---|---|---|
| 1 | Cafeteria | Crowded indoor area, close to an AP. Represents a best-case indoor scenario. |
| 2 | Behind Concrete Wall | Structural obstruction between the user and the nearest AP. Represents typical attenuation. |
| 3 | Main Hall | Transit area with regular movement of people. Typical indoor public space. |
| 4 | Garden | Outdoor / open area. Tests outdoor coverage of building-mounted APs. |
| 5 | Basement | Expected dead zone — worst-case indoor scenario. |

## 2. Data collection schedule

- **Observation window:** Tuesday through Friday of one working week (Monday was an Eastern Orthodox public holiday).
- **Sessions per day:** 3 (Morning, Noon, Afternoon).
- **Session ordering:** all five points visited in the same fixed order (1 → 2 → 3 → 4 → 5) within each session.

Notable schedule adjustments:

- On Friday, the "Morning" session started at 13:18 because of a delayed arrival. It is still the first session of the day and is kept under the Morning label for analytical consistency.
- Total sessions: 4 days × 3 time periods × 5 locations = **60 sessions**.

## 3. Variables recorded

Per individual AP detection:

| Variable | Type | Description |
|---|---|---|
| `Day` | factor | Day of the week (Tuesday - Friday) |
| `TimePeriod` | factor | Session slot (Morning / Noon / Afternoon) |
| `Time` | character | Exact clock time (HH:MM) |
| `LocationKey` | integer | 1 - 5 |
| `Location` | factor | Full location name |
| `LocationShort` | factor | Short label used in charts |
| `SSID` | factor | Network name |
| `BSSID` | character | MAC address of the access point |
| `RSSI` | integer | Signal strength in dBm |
| `Channel` | character | WiFi channel used |

## 4. Two linked datasets

A distinctive design choice of this study is to split the measurements into two complementary tables.

### `data/wifi_scans.csv` (n = 280)

Every university-network access point that was visible to the smartphone at each session. This is the classical "coverage scan" view and answers the question:

> What APs COULD the phone reach at this moment, and at what strength?

### `data/wifi_connected.csv` (n = 60)

The single AP the smartphone was **actually associated with** at the moment of the scan — one row per session. Note: the researcher only had the WiFi password for `cafe@swu`, so every row in this table is a `cafe@swu` access point. This answers the question:

> What signal strength does a student limited to cafe@swu credentials experience across the campus?

Matching the two tables on (Day, TimePeriod, LocationShort) lets us compute a **"credential gap"** for every session:

```
Gap  =  Best RSSI observed in scan  −  RSSI of the cafe@swu AP
```

A positive gap quantifies the extra signal a full-access (`WiFi(at)SWU`) user would have had over the single-network (`cafe@swu`-only) user. This is a common and relevant situation for newly arrived Erasmus students who have not yet been given the main-network credentials.

## 5. SSID filtering

The raw scans also picked up non-university networks (personal hotspots, printer direct-connect interfaces, residential routers nearby, etc.). These are not relevant to the campus-coverage question and were filtered out, keeping only the four university SSIDs:

- `WiFi(at)SWU` — main campus network
- `cafe@swu` — cafeteria / student areas network
- `Career` — career office network
- `Cultural_Tourism_Lab` — lab network

## 6. Signal-quality categories

RSSI is a continuous variable but it is helpful to interpret it on a coarse scale. Four categories were used, following widely accepted WiFi thresholds:

| Category | Range |
|---|---|
| Excellent | RSSI ≥ −50 dBm |
| Good | −60 ≤ RSSI < −50 |
| Fair | −70 ≤ RSSI < −60 |
| Poor | RSSI < −70 |

## 7. Statistical methods

- **Descriptive statistics:** mean, median, SD, min, max, per location / time / day / SSID.
- **Inferential tests:**
  - One-way ANOVA of RSSI against Location, Time of Day, and Day of Week.
  - Tukey HSD post-hoc for Location (since it was significant).
- **Paired comparison:** credential-gap distribution computed per session (best scanned AP − connected `cafe@swu` AP).

All analysis was carried out in **R 4.x** using `tidyverse`, `ggplot2`, `scales`, `viridis`, and `RColorBrewer`. The code is reproducible from the cleaned CSVs included in this repository.

## 8. Limitations

- **Observation window is only one working week.** Longer coverage (e.g., the same weekday across a month) would strengthen conclusions about day-to-day stability.
- **Only one smartphone was used.** A multi-device campaign would further validate the results.
- **The credential gap is inherently a single-student perspective.** Repeating the experiment with a second student who has `WiFi(at)SWU` credentials would allow a direct comparison of the two actual user experiences.
- **Fixed-point measurements.** A true spatial heatmap would require a dense grid of sample points and a floor-plan overlay.
- **RSSI is quantized and slightly calibration-dependent** on mobile OS APIs, but trends across repeated measurements on the same device are reliable.
