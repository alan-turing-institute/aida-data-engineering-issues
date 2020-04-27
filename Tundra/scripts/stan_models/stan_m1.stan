data {
int<lower=0> n; // number of observations
vector[n] y; // observations
vector[n] tmp; // temperature or precipitation
real<lower=0> sigma_s;
real<lower=0> sigma_1;
real<lower=0> sigma_2;
real<lower=0> sigma_3;
}
parameters {
real alpha_sd;
real alpha_s;
real beta_s;
real A;
real B;
}
transformed parameters {
vector[n] alpha_obs; // temperature effects for every observation
for (j in 1:n)
alpha_obs[j] = alpha_s + beta_s * tmp[j];
}
model {
target += normal_lpdf(alpha_s | A, sqrt(sigma_3));
target += normal_lpdf(beta_s | B, sqrt(sigma_2));
target += normal_lpdf(alpha_sd | alpha_obs, sqrt(sigma_1));
target += lognormal_lpdf(y | alpha_sd, sqrt(sigma_s));
}
