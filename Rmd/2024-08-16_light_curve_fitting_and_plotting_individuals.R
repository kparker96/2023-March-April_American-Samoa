# written by Antti Takolander 09/2019
# KEP update 2024-08-15 
# Example script to fit rapid light curves using R package "phytotools" and the model by Platt et al. 1980, 
# to extract the coefficients/parameters alpha, beta, ETRmax, Ek and ps from the fitted curve, 
# and plotting the curves into individual tiff files. 
# The script below relies heavily on code examples provided by the authors of the 
# phytotools package. See the code examples of the package for equations for fitting/plotting other light curve models. 

# Install libraries for phytotools 
# IMPORTANT: need to have rtools installed
# https://cran.r-project.org/bin/windows/Rtools/rtools43/rtools.html

install.packages("sp")

install.packages("rdgal")
# install.packages("https://cran.r-project.org/src/contrib/Archive/rgdal/rgdal_1.6-6.tar.gz", repos=NULL, type="source")

install.packages("terra")
# install.packages("https://cran.r-project.org/src/contrib/Archive/terra/terra_1.7-37.tar.gz", repos=NULL, type="source")

install.packages("raster")
# install.packages("https://cran.r-project.org/src/contrib/Archive/raster/raster_3.6-14.tar.gz", repos=NULL, type="source")

install.packages("https://cran.r-project.org/src/contrib/Archive/insol/insol_1.2.tar.gz", repos=NULL, type="source")

install.packages("https://cran.r-project.org/src/contrib/Archive/deSolve/deSolve_1.34.tar.gz", repos=NULL, type="source")

install.packages("rootSolve")

install.packages("https://cran.r-project.org/src/contrib/Archive/coda/coda_0.19-3.tar.gz", repos=NULL, type="source")

install.packages("https://cran.r-project.org/src/contrib/Archive/FME/FME_1.3.tar.gz", repos=NULL, type="source")

install.packages("https://cran.r-project.org/src/contrib/Archive/phytotools/phytotools_1.0.tar.gz", repos=NULL, type="source", dependencies = FALSE)

rm(list=ls())# empty the workspace
# check that phytotools is installed
#### Libraries ####
library(sp)
#library(rdgal)
library(terra)
library(raster)
library(insol)
library(deSolve)
library(coda)
library(FME)
library(phytotools)
library(readxl)
library(tidyverse)

#### Load Data #### 
rlc.Deep <- read_xlsx("data/Ch2/raw_RLCs/2023-03-31_Deep_Mgris_RLCs.xlsx")
rlc.Midd <- read_xlsx("data/Ch2/raw_RLCs/2023-04-01_Midd_Mgris_RLCs.xlsx")
rlc.Shall <- read_xlsx("data/Ch2/raw_RLCs/2023-04-05_Shall_Mgris_RLCs.xlsx")

rlc.Deep.data <- data.frame(
  par = rlc.Deep$PAR,
  etr = rlc.Deep$ETR,
  id = c(rep("Deep", 7)),
  individual = paste(rlc.Deep$Depth, rlc.Deep$Geno, sep = "_"),
  stringsAsFactors=FALSE
)

rlc.Midd.data <- data.frame(
  par = rlc.Midd$PAR,
  etr = rlc.Midd$ETR,
  id = c(rep("Midd", 6)),
  individual = paste(rlc.Midd$Depth, rlc.Midd$Geno, sep = "_"),
  stringsAsFactors=FALSE
)

rlc.Shall.data <- data.frame(
  par = rlc.Shall$PAR,
  etr = rlc.Shall$ETR,
  id = c(rep("Shall", 6)),
  individual = paste(rlc.Shall$Depth, rlc.Shall$Geno, sep = "_"),
  stringsAsFactors=FALSE
)

rlc.data <- rbind(rlc.Deep.data, rlc.Midd.data, rlc.Shall.data)

ncurves <- length(unique(rlc.data$individual)) # number of unique ids in the data 
individuals <- unique(rlc.data$individual) # store the unique ids 

#### Initialize data frames for storing predictions and parameters ####
rlc.predictions <- rlc.data
rlc.predictions$fit <- NA

rlc.parameters <- data.frame(
  individual = individuals,
  alpha = 0, 
  beta = 0, 
  ETRmax = 0, 
  Ek = 0, 
  ps = 0
)

#### Run phytotools loop for every sample ####

for (i in 1:ncurves) {
  
  temp.individual <- individuals[i]
  temp.rlc.data <- rlc.data[rlc.data$individual == temp.individual,]
  
  PAR <- temp.rlc.data$par 
  ETR <- temp.rlc.data$etr
  
  fit <- fitPGH(PAR, ETR, fitmethod = "Port")
  
  alpha.rlc <- fit$alpha[1]
  beta.rlc <- fit$beta[1]
  ps.rlc <- fit$ps[1]
  
  # Calculate ETRmax and Ek for the PGH model
  ETRmax <- ps.rlc * (alpha.rlc / (alpha.rlc + beta.rlc)) * (beta.rlc / (alpha.rlc + beta.rlc))^(beta.rlc / alpha.rlc)
  Ek <- ETRmax / alpha.rlc
  
  # Store the parameters in rlc.parameters
  rlc.parameters$individual[i] <- temp.individual
  rlc.parameters$alpha[i] <- alpha.rlc
  rlc.parameters$beta[i] <- beta.rlc
  rlc.parameters$ps[i] <- ps.rlc
  rlc.parameters$ETRmax[i] <- ETRmax
  rlc.parameters$Ek[i] <- Ek
  
  # Store the fitted values for each PAR
  rlc.predictions$fit[rlc.predictions$individual == temp.individual] <- with(fit, {
    P <- ps.rlc * (1 - exp(-1 * alpha.rlc * PAR / ps.rlc)) * exp(-1 * beta.rlc * PAR / ps.rlc)
    P
    
    
  })
}

#### Initialize vectors to store metrics ####
r_squared <- numeric(ncurves)
rmse <- numeric(ncurves)

for (i in 1:ncurves) {
  temp.individual <- individuals[i]
  temp.rlc.data <- rlc.data[rlc.data$individual == temp.individual, ]
  actual <- temp.rlc.data$etr
  predicted <- rlc.predictions$fit[rlc.predictions$individual == temp.individual]
  
  # R-squared
  ss_total <- sum((actual - mean(actual))^2)
  ss_residual <- sum((actual - predicted)^2)
  r_squared[i] <- 1 - (ss_residual / ss_total)
  
  # RMSE
  rmse[i] <- sqrt(mean((actual - predicted)^2))
}

#### Combine metrics into a data frame ####
metrics <- data.frame(individual = individuals, R_squared = r_squared, RMSE = rmse)
print(metrics)

#### Plot Individual Curves for each depth ####

ggplot(rlc.predictions, aes(x = par, y = etr, color = individual)) +
  geom_point(size = 1.5) + # Observed data
  geom_line(aes(y = fit, alpha = 0.1), size = 1.5, alpha = 0.6) +
  facet_wrap(~id) +
  theme_bw() +
  theme(legend.position = "none")


#### Average genofits for population fit ####
rlc.data.pop <- rlc.data %>%
  group_by(id, par) %>%
  summarize(pop_etr = mean(etr, na.rm = TRUE), .groups = 'drop')
  
#### Run phytotools loop for each population ####

ncurves <- length(unique(rlc.data.pop$id)) # number of unique ids in the data 
ids <- unique(rlc.data.pop$id) # store the unique ids 

# note that this example uses the Platt, Gallegos & Harrison 1980 model (PGH), which affects the number of parameters derived. 

# create a data frame to store the extracted curve parameters after model fitting
rlc.parameters.pop <- data.frame(
  id = ids, 
  alpha = 0, 
  beta = 0, 
  ETRmax = 0, 
  Ek = 0, 
  ps = 0
)

rlc.predictions.pop <- rlc.data.pop
rlc.predictions.pop$fit.pop <- NA

# the loop below loops runs times specified in ncurves, fits the PGH model to the data, 
# plots a fitted curve and data into a tiff file (into current working directory), and extracts the model parameters into rlc.parameters.pop data frame. 
# for explanation of the parameters and physiological interpretation see the original publication by Platt et al. 1980. 

# Potential problems with the loop are missing PAR or ETR values in the rlc data. 
# It is a good practice to check the plots of all fitted curves before relying on / further analyzing any of the fitted values.

for (i in 1:ncurves){
  
  temp.id = ids[i] # extract the id of the curve to be fitted
  
  print(paste("Now fitting curve ", as.character(temp.id))) # to keep track what's happening if the data has many curves
  
  temp.rlc.data.pop <- rlc.data.pop[rlc.data.pop$id==temp.id,] # extract the the data of a single curve into a temporary variable
  PAR.pop = temp.rlc.data.pop$par 
  ETR.pop = temp.rlc.data.pop$pop_etr
  
  fit.pop = fitPGH(PAR.pop, ETR.pop, fitmethod = "Port") # for more options and explanation see package phytotools manual
  
  # store the fitted RLC values into temporary variables
  alpha.rlc.pop = fit.pop$alpha[1]
  beta.rlc.pop = fit.pop$beta[1]
  ps.rlc.pop = fit.pop$ps[1]
  
  # calculate ETRmax and Ek for the PGH model (see e.g.Ralph & Gademann 2005 Aquatic Botany 82 (3): 222 - 237). 
  # Note that the equation depends on the model fitted, the code below applies only to the PGH model! 
  # Model equations are documented in the phytotools package code examples (and in the original papers): https://cran.r-project.org/web/packages/phytotools/phytotools.pdf
  
  ETRmax = ps.rlc.pop*(alpha.rlc.pop/(alpha.rlc.pop + beta.rlc.pop))*(beta.rlc.pop/(alpha.rlc.pop+beta.rlc.pop))^(beta.rlc.pop/alpha.rlc.pop)
  Ek = ETRmax/alpha.rlc.pop 
  
  # store the variables
  rlc.parameters.pop$id[i] <- temp.id
  rlc.parameters.pop$alpha[i] <- alpha.rlc.pop
  rlc.parameters.pop$beta[i] <- beta.rlc.pop
  rlc.parameters.pop$ps[i] <- ps.rlc.pop
  rlc.parameters.pop$ETRmax[i] <- ETRmax
  rlc.parameters.pop$Ek[i] <- Ek
  
  # Store the fitted values for each PAR
  rlc.predictions.pop$fit.pop[rlc.predictions.pop$id == temp.id] <- with(fit.pop, {
    P <- ps.rlc.pop * (1 - exp(-1 * alpha.rlc.pop * PAR.pop / ps.rlc.pop)) * exp(-1 * beta.rlc.pop * PAR.pop / ps.rlc.pop)
    P
    
  })
}

#### Initialize vectors to store metrics ####
r_squared.pop <- numeric(ncurves)
rmse.pop <- numeric(ncurves)

for (i in 1:ncurves) {
  temp.id <- rlc.parameters.pop$id[i]
  temp.rlc.data.pop <- rlc.data.pop[rlc.data.pop$id == temp.id, ]
  actual.pop <- temp.rlc.data.pop$pop_etr
  predicted.pop <- rlc.predictions.pop$fit.pop[rlc.predictions.pop$id == temp.id]
  
  # R-squared
  ss_total.pop <- sum((actual.pop - mean(actual.pop))^2)
  ss_residual.pop <- sum((actual.pop - predicted.pop)^2)
  r_squared.pop[i] <- 1 - (ss_residual.pop / ss_total.pop)
  
  # RMSE
  rmse.pop[i] <- sqrt(mean((actual.pop - predicted.pop)^2))
}

#### Combine metrics into a data frame ####
metrics.pop <- data.frame(id = ids, R_squared.pop = r_squared.pop, RMSE.pop = rmse.pop)
print(metrics.pop)
  
# now the data frame rlc.parameters.pop contains the fitted values for each curve. Tiff plots should be in current working directory. 
rlc.parameters.pop

#### Create a data frame for vertical and horizontal lines and labels ####
vertical_lines <- data.frame(
  id = rlc.parameters.pop$id,
  Ek = rlc.parameters.pop$Ek
  #color = c("red", "blue", "green")  # Customize colors or use a palette
)

horizontal_lines <- data.frame(
  id = rlc.parameters.pop$id,
  ETRmax = rlc.parameters.pop$ETRmax
  #color = c("red", "blue", "green")  # Customize colors or use a palette
)

text_labels <- data.frame(
  id = rlc.parameters.pop$id,
  Ek = rlc.parameters.pop$Ek,
  ETRmax = rlc.parameters.pop$ETRmax,
  label_ek = paste("Ek =", round(rlc.parameters.pop$Ek, 2)), # Create a label text
  label_ETRmax = paste("ETRmax =", round(rlc.parameters.pop$ETRmax, 2)),
  stringsAsFactors = FALSE
)

Deep_labels <- text_labels %>%
  filter(id == "Deep")

Midd_labels <- text_labels %>%
  filter(id == "Midd")

Shall_labels <- text_labels %>%
  filter(id == "Shall")

depths <- as_labeller(c(Midd = "Middle", Shall = "Shallow", Deep = "Deep"))

#### Plot observed data and fitted model ####
ggplot(rlc.predictions, aes(x = par, y = etr, color = id)) +
  geom_point(size = 1, alpha = 0.4, show.legend = FALSE) + # Observed data
  geom_line(data = rlc.predictions.pop, aes(y = fit.pop), size = 1.5) + # Fitted model
  geom_vline(data = vertical_lines, aes(xintercept = Ek, color = id), size = 0.75, linetype = "dashed", show.legend = FALSE) +
  geom_hline(data = horizontal_lines, aes(yintercept = ETRmax, color = id), size = 0.75, linetype = "dashed", show.legend = FALSE) +
  
  # Deep Labels
  geom_text(data = Deep_labels, aes(label = label_ek), x = 380, y = 7, show.legend = FALSE) +
  geom_text(data = Deep_labels, aes(label = label_ETRmax), x = 1330, y = 48, show.legend = FALSE) +
  
  # Midd Labels
  geom_text(data = Midd_labels, aes(label = label_ek), x = 510, y = 7, show.legend = FALSE) +
  geom_text(data = Midd_labels, aes(label = label_ETRmax), x = 1330, y = 72, show.legend = FALSE) +
  
  
  # Shall Labels
  geom_text(data = Shall_labels, aes(label = label_ek), x = 495, y = 7, show.legend = FALSE) +
  geom_text(data = Shall_labels, aes(label = label_ETRmax), x = 1330, y = 62, show.legend = FALSE) +
  
  facet_wrap(~id, labeller = depths, ncol = 1) +
  theme_bw() +
  scale_y_continuous(expand = c(0,0)) +
  scale_color_manual(values=c('darkblue', 'dodgerblue3', '#78bae3')) +
  labs(title = "Fagatele M.gris Rapid Light Curves",
       x = "PAR (µmol m-2s-1)",
       y = "ETR (µmol electrons m-2s-1)") +
  theme(legend.position = "none") 

ggsave("Plots/vertical_Fagatele_2023_RLCs_facet.png", height = 175, width = 200, units = "mm")


# Non-facet plot
ggplot(rlc.predictions, aes(x = par, y = etr, color = id)) +
  geom_point(size = 1) + # Observed data
  geom_line(aes(y = fit), size = 1.5, alpha = 0.6) + # Fitted model
  geom_vline(data = vertical_lines, aes(xintercept = Ek, color = id), size = 0.75, linetype = "longdash") +
  #geom_hline(data = horizontal_lines, aes(yintercept = ETRmax, color = id), size = 0.75, linetype = "twodash") +
  
  # Deep Labels
  #geom_text(data = Deep_labels, aes(label = label_ek), x = 460, y = 1.2, show.legend = FALSE) +
  #geom_text(data = Deep_labels, aes(label = label_ETRmax), x = 950, y = 65, show.legend = FALSE) +
  
  # Midd Labels
 # geom_text(data = Midd_labels, aes(label = label_ek), x = 460, y = 1.2, show.legend = FALSE) +
  #geom_text(data = Midd_labels, aes(label = label_ETRmax), x = 950, y = 85, show.legend = FALSE) +
  
  
  # Shall Labels
  #geom_text(data = Shall_labels, aes(label = label_ek), x = 460, y = 1.2, show.legend = FALSE) +
  #geom_text(data = Shall_labels, aes(label = label_ETRmax), x = 950, y = 85, show.legend = FALSE) +
  
  #facet_wrap(~ id) + # Create separate plots for each id
  theme_bw() +
  scale_color_manual(values=c('darkblue', 'dodgerblue3', 'lightskyblue')) +
  labs(title = "RLC Data with Fitted PGH Model",
       x = "PAR",
       y = "ETR") +
  theme(legend.position = "bottom") 

ggsave("Plots/Fagatele_2023_RLCs.png", height = 150, width = 175, units = "mm")

#### Stats ####
library(car)

rlc.stats <- rlc.parameters %>%
  mutate(id = case_when(grepl("Deep", individual) ~ "Deep",
                        grepl("Midd", individual) ~ "Midd",
                        grepl("Shall", individual) ~ "Shall",))

# Homogeneity of Variances 
leveneTest(ETRmax ~ id, data = rlc.stats)
leveneTest(Ek ~ id, data = rlc.stats)

ETRmax_anova <- aov(ETRmax ~ id, data = rlc.stats)
Ek_anova <- aov(Ek ~ id, data = rlc.stats)

summary(ETRmax_anova)
summary(Ek_anova)

TukeyHSD(ETRmax_anova)
TukeyHSD(Ek_anova)


## Plot Shallow and Deep for Reef Futures 2024 Poster ##
#### Plot observed data and fitted model ####

rlc.predictions.RF <- rlc.predictions %>%
  filter(id == "Deep" | id == "Shall")

rlc.predictions.pop.RF <- rlc.predictions.pop %>%
  filter(id == "Deep" | id == "Shall")

vertical_lines.RF <- vertical_lines %>%
  filter(id == "Deep" | id == "Shall")

horizontal_lines.RF <- horizontal_lines %>%
  filter(id == "Deep" | id == "Shall")

rlcs_all <- ggplot(rlc.predictions.RF, aes(x = par, y = etr, color = id)) +
  geom_point(size = 3, alpha = 0.75, show.legend = FALSE) + # Observed data
  geom_line(data = rlc.predictions.pop.RF, aes(y = fit.pop), size = 1.75) + # Fitted model
  geom_vline(data = vertical_lines.RF, aes(xintercept = Ek, color = id), size = 1.5, linetype = "dashed", show.legend = FALSE) +
  geom_hline(data = horizontal_lines.RF, aes(yintercept = ETRmax, color = id), size = 1.5, linetype = "dashed", show.legend = FALSE) +
  
  # Deep Labels
  geom_text(data = Deep_labels, aes(label = label_ek), size = 14, fontface = "bold", x = 390, y = 1, show.legend = FALSE) +
  geom_text(data = Deep_labels, aes(label = label_ETRmax), size = 14, fontface = "bold", x = 1330, y = 63, show.legend = FALSE) +

  # Midd Labels
  geom_text(data = Midd_labels, aes(label = label_ek), size = 14, fontface = "bold", x = 510, y = 11, show.legend = FALSE) +
  geom_text(data = Midd_labels, aes(label = label_ETRmax), size = 14, fontface = "bold", x = 1330, y = 87, show.legend = FALSE) +
  
  # Shall Labels
  geom_text(data = Shall_labels, aes(label = label_ek), size = 14, fontface = "bold", x = 510, y = 18, show.legend = FALSE) +
  geom_text(data = Shall_labels, aes(label = label_ETRmax), size = 14, fontface = "bold", x = 1330, y = 78, show.legend = FALSE) +
  
  #facet_wrap(~id, labeller = depths, ncol = 1) +
  #scale_y_continuous(expand = c(0,0)) +
  ylim(0,100) +
  scale_color_manual(values = c("#00004C", "#11569B", "#56A9DC")) +
  theme_bw() +
  theme(legend.position = "none",
    axis.title = element_text(size = 40),
    axis.text = element_text(size = 38),
    plot.title = element_text(size = 50, face = "bold", hjust = 0.5)) +
  labs(title = expression("Lower Saturation Irradiance (E"["K"]*") in Deep "*italic("M. grisea")),
       x = "PAR (µmol photons m⁻² s⁻¹)",
       y = "ETR (µmol electrons m⁻² s⁻¹)")

ggsave(
  filename = "RLCs_all.png", 
  plot = rlcs_all, 
  height = 9.86, 
  width = 22.65, 
  units = "in", 
  dpi = 300
)




  
