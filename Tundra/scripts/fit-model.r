# Tundra Trait AIDA wrangling challenge

## Fit STAN model
## Giovanni Colavizza <gcolavizza@turing.ac.uk>

# June 2018

## tidy data analysis
## We need plyr, dplyr, readr, and ggplot2
library(tidyverse)
# stan
library(rstan)
#library(rstanarm)
library(loo)
library(bayesplot)

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

load("../datasets/data_clean/filtered_dataset.RData")

### ORIGINAL: models_stan.r

## Fit a specific trait of your choice (Cf. Figure 2b in the draft paper)
## trait <- "Leaf area"
## trait <- "Plant height, vegetative"
## trait <- "Plant height, reproductive"
## trait <- "Leaf nitrogen (N) content per leaf dry mass"
## trait <- "Leaf area per leaf dry mass (specific leaf area, SLA)"
## trait <- "Leaf dry mass per leaf fresh mass (Leaf dry matter content, LDMC)" # This is a ratio between 0 and 1, therefore you should change the error distribution to a Beta

trait <- "Leaf nitrogen (N) content per leaf dry mass"

df <- filtered_dataset %>% filter(Trait == trait)

species <- data.frame(unique(df$AccSpeciesName))

colnames(species) <- c("AccSpeciesName")
rownames(species) <- NULL

species["species_index"] <- c(1:nrow(species))

df <- merge(df, species, by = c("AccSpeciesName"))

# Train/Test split
smp_siz = floor(0.80*nrow(df))
set.seed(42)
train_ind = sample(seq_len(nrow(df)), size = smp_siz)
train = df[train_ind,]
test = df[-train_ind,]

# model
model_data <- list(n = nrow(train), 
                s = nrow(species),
                y = train$Value,
                tmp = train$tmp.centered,
                species = train$species_index)

# model 3 removes the normal distribution generating alpha_sd parameters, best model according to diagnostics
fit_3 <- stan(file = '../scripts/stan_models/stan_m3.stan', data = model_data, 
              iter = 1000, chains = 4)

### ORIGINAL diagnostics.r

sub_summary <- summary(fit_3, pars = c("A", "B", "alpha_s[1]", "beta_s[1]", "sigma_2", "sigma_3", "y_rep[1]"))
print(sub_summary$summary)

plot(fit_3, pars = c("A", "B", "alpha_s[1]", "beta_s[1]", "sigma_2", "sigma_3", "y_rep[1]"))
pairs(fit_3, pars = c("A", "B", "alpha_s[1]", "beta_s[1]", "sigma_2", "sigma_3", "y_rep[1]", "lp__"))
pairs(fit_3, pars = c("alpha_s[1]", "beta_s[1]", "y_rep[1]", "sigma_s"))
traceplot(fit_3, pars = c("A", "B"), inc_warmup = TRUE)
traceplot(fit_3, pars = c("alpha_s[1]", "alpha_s[2]", "alpha_s[3]", "alpha_s[4]", "beta_s[1]", "beta_s[2]", "beta_s[3]", "beta_s[4]"), inc_warmup = TRUE)

a <- extract(fit_3, permuted = FALSE) # return a list of arrays
np <- nuts_params(fit_3)

# bivariate scatterplot of A vs B
color_scheme_set("teal")
(p <- mcmc_scatter(a, pars = c("A", "B"), np=np))
p +
  labs(
    title = "A vs B"
  )
# add ellipse
p + stat_ellipse(level = 0.9, color = "gray20", size = 1)

(p2 <- mcmc_parcoord(a, pars = c("A", "B"), np=np))
p2 +
  labs(
    title = "A vs B"
  )

y_rep <- extract(fit_3, pars = c("y_rep"))
y_rep <- y_rep$y_rep

# kernel density estimate of the observed data (bold) with density estimate of several simulated datasets
ppc_dens_overlay(model_data$y, y_rep, size = 0.25, alpha = 0.7, trim = FALSE,
                 bw = "nrd0", adjust = 1, kernel = "gaussian", n_dens = 1024)

                                        # skew of y_rep vs observed data
ppc_stat(model_data$y, y_rep)

# posterior medians by species
ppc_stat_grouped(model_data$y, y_rep, model_data$species, stat = "median")

# LLO TESTS
# Extract pointwise log-likelihood and compute LOO: leave one out checks

# MODEL 3

log_lik_2 <- extract_log_lik(fit_3, merge_chains = FALSE)
r_eff <- relative_eff(exp(log_lik_2))
loo_2 <- loo(log_lik_2, r_eff = r_eff, cores = 10, save_psis = TRUE)
print(loo_2)
plot(loo_2)
y_rep_2 <- extract(fit_3, pars = c("y_rep"))
y_rep_2 <- y_rep_2$y_rep

ppc_loo_pit_overlay(
  y = model_data$y,
  yrep = y_rep_2,
  lw = weights(loo_2$psis_object)
)

### Attempt to reproduce figure 2b, for site 1, trait <- "Leaf nitrogen (N) content per leaf dry mass"
# TODO: the best way would be to sample values of alpha and beta from the model, given species and location. This is a quick and dirty hack!
tmp_ranges <- seq(0, 15, length.out = 100)
exp_model <- function(t) {
  return(exp(2.98 + 0.03 * t))
}
general_line <- lapply(tmp_ranges, exp_model)
test_line <- lapply(test$tmp.centered, exp_model)

plot(tmp_ranges, general_line, xlab = "Temperature", ylab = "Predicted trait value")
plot(test$tmp, test_line, xlab = "Temperature", ylab = "Predicted trait value")

predicted_df <- data.frame(col1=test$tmp, col2=array(as.numeric(unlist(test_line))))
colnames(predicted_df) <- c("tmp","Value")

# Function that returns Root Mean Squared Error
rmse <- function(error)
{
  sqrt(mean(error^2))
}

# Function that returns Mean Absolute Error
mae <- function(error)
{
  mean(abs(error))
}

# Function that returns R^2 (coefficient of determination)
r2 <- function(error,mean_error)
{
  1 - (sum(error^2)/sum(mean_error^2))
}

# Calculate error
error <- test$Value - predicted_df$Value
mean_error <- test$Value - mean(test$Value)

# Example of invocation of functions
rmse(error)
mae(error)
r2(error,mean_error)

# These should be the grey lines in Figure 2b: data from species for a given trait, with interpolation

figure2 <- ggplot(df) +
    geom_point(aes(tmp, Value), size = 0.2, shape = 1, alpha = 0.7) +
    geom_smooth(aes(tmp, Value), method = lm, se = FALSE) +
    facet_wrap(~AccSpeciesName, scales = "free_y") +
    labs(x = "Temperature (ºC)", y = trait)

ggsave("../results/figure2-repro.pdf",
       plot = figure2 + theme_minimal(base_size = 7)
)

# This is the main line (linear regression over data from all species, for a given trait)
figure3 <- ggplot(df, aes(x = tmp, y = Value)) +
  geom_point() +
  geom_smooth(data = train, method = lm, aes(color = "green")) + geom_smooth(data = test, method = lm, aes(color = "blue")) + geom_smooth(data = predicted_df, method = lm, aes(color = "red")) +
  labs(x = "Temperature", y = "Trait value") + ggtitle("Trait example: Leaf nitrogen (N) content per leaf dry mass (mg/g)") +
  theme(axis.text=element_text(size=18), axis.title=element_text(size=21), plot.title = element_text(size=24, hjust = 0.5)) +
  scale_colour_manual(name="Legend", values=c("green", "blue", "red"), labels = c("Train", "Test", "Predicted from Test")) + guides(fill=TRUE)

ggsave("../results/figure3-example.pdf",
       plot = figure3
)
