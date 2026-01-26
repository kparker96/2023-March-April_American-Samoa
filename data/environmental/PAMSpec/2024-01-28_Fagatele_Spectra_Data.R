
# Load libraries
library(tidyverse)

# Import data
df <- read.csv("data/spec/2024-01-28_Fagatele_spec_data.csv")

# Convert data from wide to long format
df_long <- df %>%
  gather(key = "Wavelength", value = "nmol", -Time, -spec_num, -Depth, -PAR)

# Convert Wavelength column to numeric (remove the 'X' prefix)
df_long$Wavelength <- as.numeric(gsub("X", "", df_long$Wavelength))

# Convert spec_num and Depth columns to characters for ggplot
df_long$spec_num <- as.character(df_long$spec_num)
#df_long$Depth <- as.character(df_long$Depth)

# Plot all spec
ggplot(df_long, aes(x = Wavelength, y = nmol, color = spec_num)) +
  geom_line() +
  labs(title = "Spectra Data",
       x = "Wavelength (nm)",
       y = "nmol") +
  theme_bw() 

ggsave("plots/2024-01-28_Fagatele_all_spec.jpeg")

# Plot with depth facet 
ggplot(df_long, aes(x = Wavelength, y = nmol, color = spec_num)) +
  geom_line() +
  labs(title = "Spectra Data",
       x = "Wavelength (nm)",
       y = "nmol") +
  theme_bw() +
  theme(legend.position = "none") +
  facet_wrap(~Depth) 

ggsave("plots/2024-01-28_Fagatele_spec_by_depth.jpeg", width = 150, height = 150, units = "mm")

  
