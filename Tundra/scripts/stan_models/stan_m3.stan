data {
	int<lower=0> n; // number of observations
	int<lower=0> s; // number of species
	vector[n] y; // observations
	vector[n] tmp; // temperature or precipitation
	int<lower=0> species[n]; // species
}
parameters {
	vector[s] alpha_s;
	vector[s] beta_s;
	real A;
	real B;
	real<lower=0> sigma_s;
	real<lower=0> sigma_2;
	real<lower=0> sigma_3;
}
transformed parameters {
	vector[n] alpha_sd;
	for (j in 1:n) alpha_sd[j] = alpha_s[species[j]] + beta_s[species[j]]*tmp[j];
}
model {
	y ~ lognormal(alpha_sd, sigma_s);
	alpha_s ~ normal(A, sigma_3);
	beta_s ~ normal(B, sigma_2);
	A ~ normal(0., 3.);
	B ~ normal(0., 3.);
	sigma_s ~ normal(0., 3.);
	sigma_2 ~ normal(0., 3.);
	sigma_3 ~ normal(0., 3.);
}
generated quantities {
	vector[n] y_rep;
	vector[n] log_lik;
	for (j in 1:n) {
		y_rep[j] = lognormal_rng(alpha_sd[j], sigma_s);
		log_lik[j] = lognormal_lpdf(y[j] | alpha_sd[j], sigma_s);
	}
}
