# =============================================================================
# IoT System for Network Environment Monitoring
# WiFi Signal Strength (RSSI) Analysis
# -----------------------------------------------------------------------------
# Student   : Ramazan Karagoz (Erasmus exchange student, Statistics)
# University: South-West University "Neofit Rilski" (SWU), Blagoevgrad
# Tool used : R (tidyverse + ggplot2)
# GitHub    : https://github.com/Necro205
# =============================================================================
#
# STUDY DESIGN
# ------------
# A smartphone was used as the IoT sensing device, and measurements were
# collected with an existing WiFi scanner app (alternative-approach option
# in the brief).
#
#   Observation period: Tuesday - Friday (Monday was an Eastern Orthodox
#                       holiday, so no data collection that day).
#   Sessions per day  : 3 (Morning, Noon, Afternoon).
#                       Friday's first session started at 13:18 because of a
#                       delayed arrival; it is still the first session of the
#                       day and is labeled Morning for consistency.
#   Locations per session: 5
#     1. Cafeteria              (crowded area, close to an AP)
#     2. Behind Concrete Wall   (structural obstruction)
#     3. Main Hall              (transit area)
#     4. Garden                 (outdoor / open area)
#     5. Basement               (expected dead zone)
#
#   Total: 4 days x 3 periods x 5 locations = 60 sessions.
#
# TWO DATASETS
# ------------
#   * wifi_scans.csv (280 rows): every university-network AP visible at the
#     location and moment of the scan. Filtered to the 4 SWU SSIDs
#     WiFi(at)SWU, cafe@swu, Career, Cultural_Tourism_Lab.
#
#   * wifi_connected.csv (60 rows): the single AP the phone was associated
#     with during the session. IMPORTANT NOTE ON INTERPRETATION:
#     the researcher only had the WiFi password for cafe@swu, so this is
#     effectively a record of cafe@swu's perceived RSSI across the campus.
#     It is NOT evidence of "sticky WiFi" client behavior.
#
# This design lets us report:
#   (a) the theoretical coverage of the radio environment (all visible APs),
#   (b) the coverage a user limited to ONE campus network (cafe@swu) actually
#       experiences - a common situation for Erasmus or visiting students.
# =============================================================================


# -----------------------------------------------------------------------------
# STEP 1 - Packages
# -----------------------------------------------------------------------------
# First-time setup (uncomment to install):
# install.packages(c("tidyverse","scales","viridis","RColorBrewer"))

library(tidyverse)
library(scales)
library(viridis)
library(RColorBrewer)


# -----------------------------------------------------------------------------
# STEP 2 - Load the two cleaned datasets
# -----------------------------------------------------------------------------
# Put the CSVs in the working directory first.
# In RStudio: Session -> Set Working Directory -> To Source File Location.

scans <- read_csv("data/wifi_scans.csv",     show_col_types = FALSE)
conn  <- read_csv("data/wifi_connected.csv", show_col_types = FALSE)

cat("Scanned APs: ", nrow(scans), " rows\n")
cat("Connected sessions: ", nrow(conn), " rows\n")


# -----------------------------------------------------------------------------
# STEP 3 - Convert the categorical columns to ordered factors
# -----------------------------------------------------------------------------
ord <- function(df) {
  df %>% mutate(
    Day           = factor(Day,
                           levels = c("Tuesday","Wednesday","Thursday","Friday")),
    TimePeriod    = factor(TimePeriod,
                           levels = c("Morning","Noon","Afternoon")),
    LocationShort = factor(LocationShort,
                           levels = c("1-Cafeteria","2-Behind Wall",
                                      "3-Main Hall","4-Garden","5-Basement"))
  )
}
scans <- ord(scans)
conn  <- ord(conn)


# -----------------------------------------------------------------------------
# STEP 4 - Descriptive statistics
# -----------------------------------------------------------------------------
stats_by_location <- scans %>%
  group_by(LocationShort) %>%
  summarise(n = n(),
            mean   = round(mean(RSSI),2),
            median = median(RSSI),
            sd     = round(sd(RSSI),2),
            min    = min(RSSI),
            max    = max(RSSI),
            .groups = "drop")
print(stats_by_location)

stats_by_time <- scans %>%
  group_by(TimePeriod) %>%
  summarise(n = n(), mean = round(mean(RSSI),2),
            sd = round(sd(RSSI),2), .groups = "drop")
print(stats_by_time)

stats_by_day <- scans %>%
  group_by(Day) %>%
  summarise(n = n(), mean = round(mean(RSSI),2),
            sd = round(sd(RSSI),2), .groups = "drop")
print(stats_by_day)

stats_by_ssid <- scans %>%
  group_by(SSID) %>%
  summarise(n = n(), mean = round(mean(RSSI),2),
            sd = round(sd(RSSI),2), .groups = "drop") %>%
  arrange(desc(mean))
print(stats_by_ssid)


# -----------------------------------------------------------------------------
# STEP 5 - Signal-quality categories
# -----------------------------------------------------------------------------
quality <- function(x) {
  case_when(x >= -50 ~ "Excellent",
            x >= -60 ~ "Good",
            x >= -70 ~ "Fair",
            TRUE     ~ "Poor")
}
scans <- scans %>%
  mutate(Quality = factor(quality(RSSI),
                          levels = c("Excellent","Good","Fair","Poor")))
conn <- conn %>%
  mutate(Quality = factor(quality(RSSI),
                          levels = c("Excellent","Good","Fair","Poor")))

q_scans <- scans %>% count(Quality) %>%
  mutate(percent = round(100*n/sum(n),1))
q_conn  <- conn %>% count(Quality) %>%
  mutate(percent = round(100*n/sum(n),1))
print(q_scans); print(q_conn)


# -----------------------------------------------------------------------------
# STEP 6 - ANOVA tests
# -----------------------------------------------------------------------------
cat("\n--- ANOVA: RSSI vs Location (scanned) ---\n")
print(summary(aov(RSSI ~ LocationShort, data = scans)))

cat("\n--- ANOVA: RSSI vs TimePeriod (scanned) ---\n")
print(summary(aov(RSSI ~ TimePeriod, data = scans)))

cat("\n--- ANOVA: RSSI vs Day (scanned) ---\n")
print(summary(aov(RSSI ~ Day, data = scans)))

cat("\n--- Tukey HSD post-hoc for Location ---\n")
print(TukeyHSD(aov(RSSI ~ LocationShort, data = scans)))


# -----------------------------------------------------------------------------
# STEP 7 - The "credential gap": best scanned AP vs. connected AP
# -----------------------------------------------------------------------------
# For each session we compare:
#   (a) the strongest university-AP visible at the time,
#   (b) the AP the phone was actually associated with (always a cafe@swu AP,
#       because that was the only campus network the researcher had
#       credentials for).
#
# The gap = (a) - (b) quantifies how much SIGNAL a student loses when they
# are limited to a single campus network (cafe@swu) instead of having
# access to the full university infrastructure (WiFi(at)SWU etc.).
# This is a common situation for Erasmus / visiting students who do not
# immediately receive the main-network credentials.

best_per_session <- scans %>%
  group_by(Day, TimePeriod, LocationShort) %>%
  summarise(BestScanned = max(RSSI), .groups = "drop")

credential_gap <- conn %>%
  select(Day, TimePeriod, LocationShort, ConnectedRSSI = RSSI) %>%
  left_join(best_per_session, by = c("Day","TimePeriod","LocationShort")) %>%
  mutate(Gap = BestScanned - ConnectedRSSI)

cat("\n--- Credential-gap summary (dB) ---\n")
cat(sprintf("  Mean   : %.2f\n",   mean(credential_gap$Gap)))
cat(sprintf("  Median : %.2f\n",   median(credential_gap$Gap)))
cat(sprintf("  SD     : %.2f\n",   sd(credential_gap$Gap)))
cat(sprintf("  Sessions with gap >= 10 dB : %d / %d\n",
            sum(credential_gap$Gap >= 10), nrow(credential_gap)))
cat(sprintf("  Sessions with gap >= 20 dB : %d / %d\n",
            sum(credential_gap$Gap >= 20), nrow(credential_gap)))


# -----------------------------------------------------------------------------
# STEP 8 - A shared ggplot2 theme
# -----------------------------------------------------------------------------
my_theme <- theme_minimal(base_size = 13) +
  theme(plot.title    = element_text(face="bold", size=15, hjust=0.5),
        plot.subtitle = element_text(size=11, hjust=0.5, color="gray30"),
        axis.title    = element_text(face="bold"),
        axis.text.x   = element_text(angle=15, hjust=1),
        legend.position = "right")


# -----------------------------------------------------------------------------
# FIGURE 1 - Bar chart: mean RSSI per location (scanned APs)
# -----------------------------------------------------------------------------
p1 <- ggplot(stats_by_location,
             aes(x=LocationShort, y=mean, fill=LocationShort)) +
  geom_col(color="black", width=0.7) +
  geom_errorbar(aes(ymin=mean-sd, ymax=mean+sd), width=0.2, linewidth=0.7) +
  geom_text(aes(label=round(mean,1)), vjust=-0.3, fontface="bold") +
  geom_hline(yintercept=-50, linetype="dashed", color="darkgreen",  alpha=0.7) +
  geom_hline(yintercept=-70, linetype="dashed", color="darkorange", alpha=0.7) +
  scale_fill_brewer(palette="RdYlGn", direction=-1, guide="none") +
  labs(title="Average WiFi Signal Strength by Location (scanned APs)",
       subtitle="Error bars = \u00B1 1 standard deviation",
       x="Measurement Location", y="Mean RSSI (dBm)") +
  my_theme
ggsave("figures/01_mean_rssi_by_location.png", p1, width=9, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 2 - Boxplot per location (scanned)
# -----------------------------------------------------------------------------
p2 <- ggplot(scans, aes(x=LocationShort, y=RSSI, fill=LocationShort)) +
  geom_boxplot(alpha=0.8, outlier.shape=NA) +
  geom_jitter(width=0.2, alpha=0.35, size=1.2) +
  scale_fill_brewer(palette="RdYlGn", direction=-1, guide="none") +
  labs(title="RSSI Distribution by Location (scanned APs)",
       x="Measurement Location", y="RSSI (dBm)") +
  my_theme
ggsave("figures/02_boxplot_by_location.png", p2, width=9, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 3 - Line chart: mean RSSI across time of day
# -----------------------------------------------------------------------------
time_agg <- scans %>%
  group_by(TimePeriod, LocationShort) %>%
  summarise(mean = mean(RSSI), .groups = "drop")

p3 <- ggplot(time_agg, aes(x=TimePeriod, y=mean,
                           color=LocationShort, group=LocationShort)) +
  geom_line(linewidth=1.2) + geom_point(size=3.5) +
  scale_color_brewer(palette="Set1") +
  labs(title="Mean RSSI Across Time of Day - by Location",
       x="Time Period", y="Mean RSSI (dBm)", color="Location") +
  my_theme
ggsave("figures/03_time_of_day.png", p3, width=10, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 4 - Heatmap Location x TimePeriod (scanned)
# -----------------------------------------------------------------------------
heat_lt <- scans %>%
  group_by(LocationShort, TimePeriod) %>%
  summarise(mean_rssi = mean(RSSI), .groups = "drop")

p4 <- ggplot(heat_lt, aes(x=TimePeriod, y=LocationShort, fill=mean_rssi)) +
  geom_tile(color="white", linewidth=0.8) +
  geom_text(aes(label=round(mean_rssi,1)),
            color="black", fontface="bold", size=4) +
  scale_fill_gradient2(low="firebrick", mid="khaki1",
                       high="darkgreen", midpoint=-60,
                       name="Mean RSSI\n(dBm)") +
  labs(title="WiFi Coverage Heatmap: Location \u00D7 Time of Day",
       x="Time Period", y="Location") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/04_heatmap_loc_time.png", p4, width=9, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 5 - Heatmap Location x Day (scanned)
# -----------------------------------------------------------------------------
heat_ld <- scans %>%
  group_by(LocationShort, Day) %>%
  summarise(mean_rssi = mean(RSSI), .groups = "drop")

p5 <- ggplot(heat_ld, aes(x=Day, y=LocationShort, fill=mean_rssi)) +
  geom_tile(color="white", linewidth=0.8) +
  geom_text(aes(label=round(mean_rssi,1)),
            color="black", fontface="bold", size=4) +
  scale_fill_gradient2(low="firebrick", mid="khaki1",
                       high="darkgreen", midpoint=-60,
                       name="Mean RSSI\n(dBm)") +
  labs(title="WiFi Coverage Heatmap: Location \u00D7 Day",
       x="Day", y="Location") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/05_heatmap_loc_day.png", p5, width=10, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 6 - Faceted per-day heatmaps (scanned)
# -----------------------------------------------------------------------------
heat_daily <- scans %>%
  group_by(Day, LocationShort, TimePeriod) %>%
  summarise(mean_rssi = mean(RSSI), .groups = "drop")

p6 <- ggplot(heat_daily,
             aes(x=TimePeriod, y=LocationShort, fill=mean_rssi)) +
  geom_tile(color="white", linewidth=0.6) +
  geom_text(aes(label=round(mean_rssi,1)),
            color="black", size=3.2, fontface="bold") +
  scale_fill_gradient2(low="firebrick", mid="khaki1",
                       high="darkgreen", midpoint=-60,
                       name="RSSI (dBm)", limits=c(-80,-30)) +
  facet_wrap(~ Day, nrow=1) +
  labs(title="Daily WiFi Coverage Heatmaps - scanned APs",
       x="Time Period", y="Location") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/06_daily_heatmaps.png", p6, width=15, height=5.5, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 7 - Mean RSSI per SSID
# -----------------------------------------------------------------------------
p7 <- ggplot(stats_by_ssid,
             aes(x=reorder(SSID, mean), y=mean, fill=SSID)) +
  geom_col(color="black", width=0.7) +
  geom_text(aes(label=paste0(round(mean,1), " dBm  (n=", n, ")")),
            hjust=1.05, color="white", fontface="bold", size=3.8) +
  coord_flip() +
  scale_fill_viridis_d(guide="none") +
  labs(title="Average Signal Strength by Network (SSID)",
       x="SSID", y="Mean RSSI (dBm)") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/07_ssid_comparison.png", p7, width=9, height=5, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 8 - Distribution histogram (scanned)
# -----------------------------------------------------------------------------
p8 <- ggplot(scans, aes(x=RSSI)) +
  geom_histogram(binwidth=2, fill="steelblue", color="black", alpha=0.85) +
  geom_vline(xintercept=-50, linetype="dashed", color="darkgreen",  linewidth=1) +
  geom_vline(xintercept=-70, linetype="dashed", color="darkorange", linewidth=1) +
  geom_vline(xintercept=mean(scans$RSSI), linetype="solid",
             color="red", linewidth=1) +
  labs(title=sprintf("Distribution of Scanned-AP RSSI Measurements (n = %d)",
                     nrow(scans)),
       x="RSSI (dBm)", y="Number of Measurements") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/08_rssi_distribution.png", p8, width=10, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 9 - BEST SCANNED vs CONNECTED (cafe@swu-only) AP, per location
# -----------------------------------------------------------------------------
comp <- credential_gap %>%
  group_by(LocationShort) %>%
  summarise(BestScanned = mean(BestScanned),
            Connected   = mean(ConnectedRSSI),
            .groups = "drop") %>%
  pivot_longer(cols = c(BestScanned, Connected),
               names_to = "Which", values_to = "RSSI") %>%
  mutate(Which = recode(Which,
                        BestScanned = "Best scanned AP (any university network)",
                        Connected   = "Connected AP (cafe@swu only)"))

p9 <- ggplot(comp, aes(x=LocationShort, y=RSSI, fill=Which)) +
  geom_col(position=position_dodge(0.8), width=0.7, color="black") +
  geom_text(aes(label=round(RSSI,1)),
            position=position_dodge(0.8), vjust=-0.3,
            fontface="bold", size=3.5) +
  geom_hline(yintercept=-50, linetype="dashed", color="darkgreen",  alpha=0.4) +
  geom_hline(yintercept=-70, linetype="dashed", color="darkorange", alpha=0.4) +
  scale_fill_manual(values = c("Best scanned AP (any university network)" = "#2ca02c",
                               "Connected AP (cafe@swu only)" = "#d62728")) +
  labs(title="Best Available Campus AP vs. Accessible AP (cafe@swu)",
       subtitle="Gap = signal a single-network user misses compared to full university access",
       x="Measurement Location", y="Mean RSSI (dBm)", fill=NULL) +
  my_theme + theme(legend.position="bottom")
ggsave("figures/09_scanned_vs_connected.png", p9, width=11, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 10 - Gap distribution histogram
# -----------------------------------------------------------------------------
p10 <- ggplot(credential_gap, aes(x=Gap)) +
  geom_histogram(binwidth=3, fill="indianred", color="black", alpha=0.85) +
  geom_vline(xintercept=mean(credential_gap$Gap), linetype="solid",
             color="darkred", linewidth=1) +
  geom_vline(xintercept=10, linetype="dashed", color="orange", linewidth=1) +
  geom_vline(xintercept=20, linetype="dashed", color="red", linewidth=1) +
  labs(title="Distribution of the Credential Gap Across 60 Sessions",
       subtitle=sprintf("Mean gap = %.1f dB. Extra signal a full-access user would have gained.",
                        mean(credential_gap$Gap)),
       x="Gap = Best scanned RSSI \u2212 cafe@swu RSSI (dB)",
       y="Number of Sessions") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/10_gap_distribution.png", p10, width=10, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 11 - Quality distribution: scanned vs connected
# -----------------------------------------------------------------------------
q_compare <- bind_rows(
  scans %>% count(Quality) %>% mutate(Type=sprintf("All university APs scanned (n=%d)", nrow(scans)),
                                      percent = 100*n/sum(n)),
  conn  %>% count(Quality) %>% mutate(Type=sprintf("Connected AP - cafe@swu only (n=%d)", nrow(conn)),
                                      percent = 100*n/sum(n))
)

p11 <- ggplot(q_compare, aes(x=Quality, y=percent, fill=Type)) +
  geom_col(position=position_dodge(0.8), width=0.7, color="black") +
  geom_text(aes(label=sprintf("%.1f%%", percent)),
            position=position_dodge(0.8), vjust=-0.3,
            fontface="bold", size=3.5) +
  scale_fill_manual(values=c("#2ca02c","#d62728")) +
  labs(title="Quality Distribution: Full Access vs. Single-Network Access",
       subtitle="What a student with cafe@swu-only credentials experiences, vs. the full campus network",
       x="Signal Quality", y="Percentage of measurements (%)",
       fill=NULL) +
  my_theme + theme(legend.position="bottom",
                   axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/11_quality_comparison.png", p11, width=10, height=6, dpi=150)


# -----------------------------------------------------------------------------
# FIGURE 12 - Connected-AP heatmaps, one per day
# -----------------------------------------------------------------------------
conn_daily <- conn %>%
  group_by(Day, LocationShort, TimePeriod) %>%
  summarise(mean_rssi = mean(RSSI), .groups = "drop")

p12 <- ggplot(conn_daily,
              aes(x=TimePeriod, y=LocationShort, fill=mean_rssi)) +
  geom_tile(color="white", linewidth=0.6) +
  geom_text(aes(label=round(mean_rssi,0)),
            color="black", size=3.2, fontface="bold") +
  scale_fill_gradient2(low="firebrick", mid="khaki1",
                       high="darkgreen", midpoint=-65,
                       name="RSSI (dBm)", limits=c(-85,-30)) +
  facet_wrap(~ Day, nrow=1) +
  labs(title="Daily Heatmaps - cafe@swu-Only User Experience",
       subtitle="What a student limited to cafe@swu credentials actually sees across campus",
       x="Time Period", y="Location") +
  my_theme + theme(axis.text.x = element_text(angle=0, hjust=0.5))
ggsave("figures/12_connected_daily_heatmaps.png",
       p12, width=15, height=5.5, dpi=150)


# -----------------------------------------------------------------------------
# STEP 9 - Export summary tables
# -----------------------------------------------------------------------------
dir.create("output", showWarnings = FALSE)
write_csv(stats_by_location, "output/stats_by_location.csv")
write_csv(stats_by_time,     "output/stats_by_time.csv")
write_csv(stats_by_day,      "output/stats_by_day.csv")
write_csv(stats_by_ssid,     "output/stats_by_ssid.csv")
write_csv(q_scans,           "output/quality_scans.csv")
write_csv(q_conn,            "output/quality_connected.csv")
write_csv(credential_gap,    "output/credential_gap.csv")

cat("\nAnalysis complete. See figures/ and output/.\n")

# -----------------------------------------------------------------------------
# KEY TAKE-AWAYS (copy into the Discussion section of the report)
# -----------------------------------------------------------------------------
# 1. Location is a HIGHLY significant predictor of scanned RSSI (ANOVA
#    p < 0.001). Cafeteria has the strongest coverage; the Main Hall and
#    Basement are the weakest, as expected from the physical setting.
#
# 2. Time of day and Day of the week are NOT significant predictors
#    (ANOVA p > 0.7 for both), so the campus WiFi infrastructure is
#    stable across the working day and across the working week.
#
# 3. cafe@swu is NOT a general-purpose campus network: its APs are clearly
#    concentrated near the cafeteria, and its signal decays rapidly as
#    soon as the user walks away from that area.
#
# 4. A user with only cafe@swu credentials experiences "Poor" (<= -70 dBm)
#    coverage in 43% of the 60 sessions, versus 14% when all university
#    APs are considered. The mean "credential gap" - the extra signal a
#    full-access user would have gained by being able to associate with
#    the strongest visible campus AP - is ~18 dB.
#
# 5. Recommendations:
#    (a) Streamline WiFi(at)SWU credential distribution for Erasmus,
#        exchange and visiting students so they are not effectively
#        limited to cafe@swu;
#    (b) Add or re-balance APs near the Main Hall and Basement, where
#        even the best available campus network only reaches the Fair band.
# =============================================================================
