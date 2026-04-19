# Findings

A deeper narrative view of the results. For the raw numbers and charts, see the full [`report/WiFi_IoT_Report.docx`](../report/WiFi_IoT_Report.docx).

## 1. Location dominates everything

The only factor that significantly affects RSSI in this dataset is **location** (ANOVA F(4, 275) = 9.41, p < 0.001). Neither time of day (p = 0.80) nor day of the week (p = 0.79) has a measurable effect.

Physically, this is expected: RSSI is dominated by distance to the nearest AP and by the attenuation of walls and floors. Temporal load variations affect throughput and latency much more than they affect signal strength.

Tukey HSD indicates that the **Cafeteria differs significantly** from the Main Hall, Behind-Wall, and Basement points, while the remaining pairwise differences are not significant.

| Location | Mean RSSI | Std Dev | Quality |
|---|---|---|---|
| 1 - Cafeteria | −52.7 dBm | 14.7 | Best |
| 4 - Garden | −58.9 dBm | 11.1 | Good |
| 2 - Behind Wall | −61.3 dBm | 10.4 | Fair |
| 5 - Basement | −61.5 dBm | 7.0 | Fair |
| 3 - Main Hall | −63.3 dBm | 5.8 | Worst |

## 2. The WiFi infrastructure is temporally stable

The flat-line pattern in the time-of-day chart and the near-identical day-of-week means reassure us that the campus WiFi is not overloaded during peak hours. Useful institutional knowledge on its own.

## 3. The credential gap — a practical Erasmus-student finding

The more interesting story emerges when we compare the theoretical coverage (best scanned AP in each session) with what a student with only `cafe@swu` credentials actually experiences.

### Context

During this study, the researcher — an Erasmus student — only had the WiFi password for `cafe@swu`. This is a common situation for newly arrived exchange students who have not yet received the main-network credentials. The connected-AP data therefore faithfully represents the coverage a single-network user experiences across campus.

### At a glance

- Mean gap: **18.2 dB**
- Median gap: **18.5 dB**
- Sessions with gap ≥ 10 dB: **39 / 60 (65%)**
- Sessions with gap ≥ 20 dB: **28 / 60 (47%)**
- Worst single session: **48 dB** (Thursday, 16:03, Behind Wall)

### What this means in practice

An 18 dB signal reduction corresponds to a factor of ~60 in received power. A 20 dB reduction is a factor of 100 and typically translates into:

- a drop in PHY data rate from the top of the modulation table down to the bottom
- increased retransmissions and packet loss
- noticeable latency spikes under any load
- in the worst cases, inability to establish a stable connection at all

### Why does this happen?

`cafe@swu` is plainly a network designed for the cafeteria area. Its two access points (`00:03:7f:12:f2:97` on 2.4 GHz and `00:03:7f:12:0e:c3` on 5 GHz) are co-located in or near the cafeteria itself. When a student walks elsewhere on campus while still associated with `cafe@swu`, the signal decays exactly as one would expect from distance and wall attenuation.

Meanwhile the main campus network `WiFi(at)SWU` has a richer, building-wide deployment of access points — multiple distinct BSSIDs were detected at every single measurement point. A student with `WiFi(at)SWU` credentials would have been able to associate with a nearby AP at each location, typically at Excellent or Good signal levels.

The per-location breakdown makes the difference concrete:

| Location | Best scanned (any university AP) | Connected (cafe@swu only) | Gap |
|---|---|---|---|
| Cafeteria | −35.0 dBm | −39.9 dBm | **4.9 dB** |
| Behind Wall | −47.5 dBm | −77.1 dBm | **29.6 dB** ⚠ |
| Main Hall | −56.1 dBm | −63.8 dBm | 7.7 dB |
| Garden | −41.3 dBm | −68.2 dBm | **26.9 dB** ⚠ |
| Basement | −54.3 dBm | −76.3 dBm | **22.0 dB** ⚠ |

The Cafeteria is the only location where a `cafe@swu`-only user and a full-access user have comparable experiences — unsurprising, since that is where the `cafe@swu` APs are installed. Everywhere else, a much better AP exists in range but is inaccessible without the appropriate password.

### The user experience gap

The net effect is visible in the quality distribution:

| Quality | All university APs | cafe@swu only |
|---|---|---|
| Excellent | 16.4% | 20.0% |
| Good | 29.6% | 6.7% |
| Fair | 40.4% | 30.0% |
| **Poor** | **13.6%** | **43.3%** |

**A student with cafe@swu-only credentials experiences "Poor" coverage about three times more often than the full coverage map would suggest.**

## 4. Network comparison (SSIDs)

Four university SSIDs were detected:

| SSID | n | Mean RSSI | Notes |
|---|---|---|---|
| cafe@swu | 63 | −54.9 dBm | Concentrated near the cafeteria AP |
| WiFi(at)SWU | 183 | −59.9 dBm | Main campus-wide network — multiple APs across buildings |
| Career | 26 | −63.9 dBm | Career office network |
| Cultural_Tourism_Lab | 8 | −73.1 dBm | Lab-specific, at edge of range |

`cafe@swu` shows the highest mean RSSI because it is geographically concentrated near its AP in the cafeteria. `WiFi(at)SWU` has a lower mean but a higher *useful range*, because APs are distributed across the campus rather than concentrated in one spot.

## 5. Recommendations

Based on the findings, three concrete recommendations:

### 5.1 Administrative (the biggest, cheapest win)
**Streamline the distribution of `WiFi(at)SWU` credentials to newly arrived Erasmus and exchange students** — for example, as part of the arrival package or the first-day orientation. This single organisational change would eliminate the credential gap for the affected student population.

### 5.2 Physical layer
Add or rebalance access points near the **Main Hall** and **Basement**. Both locations currently sit in the Fair band even when the best available campus AP is considered, with almost no headroom for fading or interference.

### 5.3 Network design / communication
Either **extend `cafe@swu` beyond the cafeteria** to better match user expectations, or **communicate clearly** to students that `cafe@swu` is a cafeteria-only network and not a substitute for the main campus WiFi.

## 6. What this project demonstrates

- A smartphone CAN serve as a capable IoT sensing device for network monitoring.
- Simple statistical tools (ANOVA, paired comparison) reveal practically relevant findings when applied to the right data.
- Coverage maps alone do not tell the full story: the user experience depends on *which networks the user can authenticate against*, not only on what APs are physically in range.
- A genuine, first-person experience as an Erasmus student turned a limitation (only having one password) into an interesting analytical framing.
