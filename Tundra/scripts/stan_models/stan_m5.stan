data {
	int<lower=0> n; // number of observations
	int<lower=0> s; // number of species
	int<lower=0> t; // number of traits
	vector[n] y; // observations
	vector[n] tmp; // temperature or precipitation
	int<lower=0> species[n]; // species
	int<lower=0> traits[n]; // traits
}
parameters {
	vector[t] mu_a;
	vector[t] mu_b;
	matrix[t,s] alpha_s;
	matrix[t,s] beta_s;
	real A;
	real B;
	real<lower=0> sigma_s;
	real<lower=0> sigma_a;
	real<lower=0> sigma_b;
	real<lower=0> sigma_2;
	real<lower=0> sigma_3;
}
transformed parameters {
	vector[n] alpha_sd;
	for (j in 1:n){
		alpha_sd[j] = alpha_s[traits[j],species[j]] + beta_s[traits[j],species[j]]*tmp[j];
	}
}
model {
	y ~ lognormal(alpha_sd, sigma_s);
	for (i in 1:t) {
		for (z in 1:s) {
        	alpha_s[i,z] ~ normal(mu_a[i],sigma_a);
        	beta_s[i,z] ~ normal(mu_b[i],sigma_b);
    	}
    }
	mu_a ~ normal(A, sigma_3);
	mu_b ~ normal(B, sigma_2);
	A ~ normal(0., 3.);
	B ~ normal(0., 3.);
	sigma_s ~ normal(0., 3.);
	sigma_a ~ normal(0., 3.);
	sigma_b ~ normal(0., 3.);
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
