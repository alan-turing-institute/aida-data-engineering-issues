# Tundra Trait AIDA wrangling challenge

## Plot figure 3
## Giovanni Colavizza <gcolavizza@turing.ac.uk>

# December 2018

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

list_of_draws <- extract(fit_3)
# average samples for alpha_s and beta_s for every species
alpha_s_means <- list_of_draws$alpha_s
beta_s_means <- list_of_draws$beta_s
sigma_s <- list_of_draws$sigma_s

# predict
predicted_data <- list(n = nrow(test), 
                   s = nrow(species),
                   y = test$Value,
                   tmp = test$tmp.centered,
                   species = test$species_index)

# only for rstanarm
# predictions <- posterior_predict(fit_3, newdata = predicted_data)

### Attempt to reproduce figure 2b, for site 1, trait <- "Leaf nitrogen (N) content per leaf dry mass"
N_SAMPLES <- 1000 # how many samples for each data point
# gets a data point and produces a list of samples from the model, returning their mean
exp_model <- function(sp, t) {
  l <- vector("numeric", N_SAMPLES)
  for (i in 1:N_SAMPLES){
    alpha_s <- sample(alpha_s_means[,sp],1)
    beta_s <- sample(beta_s_means[,sp],1)
    si_s <- sample(sigma_s,1)
    l[[i]] <- exp(rnorm(1, mean = alpha_s + beta_s * t, sd = si_s))
  }
  return(mean(l))
}
test_line <- lapply(test$species_index, exp_model, t=test$tmp.centered)

plot(test$tmp, test_line, xlab = "Temperature", ylab = "Predicted trait value")
plot(test$tmp, test$Value, xlab = "Temperature", ylab = "Trait value")

pdf("../results/predictive_vs_fitted_model.pdf")
plot(test$Value, test_line, xlab = "Trait value", ylab = "Predicted trait value", cex.lab=1.5)
lines(1:50, 1:50, type="l", lty=2, lwd=3, col="red")
title("Predicted vs ground truth values for best model\nLeaf nitrogen (N) content per leaf dry mass (mg/g)")

dev.off()

predicted_df <- data.frame(col1=test$tmp, col2=array(as.numeric(unlist(test_line))))
colnames(predicted_df) <- c("tmp","Value")

# prepare DFs and concatenate them
predicted_df_merge <- predicted_df
predicted_df_merge$dataset <- "Predicted"
train_df_merge <- train[c("tmp","Value")]
train_df_merge$dataset <- "Train"
test_df_merge <- test[c("tmp","Value")]
test_df_merge$dataset <- "Test"

concat_df <- rbind(test_df_merge,train_df_merge)

# plot dataset figure in report
ggplot(concat_df, aes(tmp, Value)) +
  geom_point() +
  labs(x = "Temperature", y = "Trait value") + ggtitle("Trait example: Leaf nitrogen (N) content per leaf dry mass (mg/g)") +
  theme(axis.text=element_text(size=18), axis.title=element_text(size=18), plot.title = element_text(size=20, hjust = 0.5)) +
  scale_colour_manual(name="Legend", values=c("red", "black"), labels = c("Predicted from Test", "Test")) + guides(fill=TRUE) +
  theme(plot.title = element_text(size = 18),
        legend.title=element_text(size=18), 
        legend.text=element_text(size=18))

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

# Evaluate model
rmse(error)
mae(error)
r2(error,mean_error)
