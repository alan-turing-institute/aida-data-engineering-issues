# aida-data-engineering-issues

This is a repository with the data wrangling challenges addressed in four case studies and summarized the paper [**Data Engineering for Data Analytics: A Classification of the Issues, and Case Studies**](https://arxiv.org/pdf/2004.12929.pdf). This work was carried out under the [Artificial Intelligence for Data Analytics (AIDA) project](https://www.turing.ac.uk/research/research-projects/artificial-intelligence-data-analytics-aida)
at the Alan Turing Institute (London, UK).

# Case studies

## Broadband dataset
The UK’s Office of Communications (Ofcom) conducts an annual survey of the
performance of residential fixed-line broadband services https://www.ofcom.org.uk/research-and-data/telecoms-research/broadband-research/broadband-speeds. These data are published as a table in annual instalments: a new spreadsheet each year containing that year's data.

The analysis is summarized in the [broadband_analysis](https://github.com/alan-turing-institute/aida-data-engineering-issues/blob/master/Broadband_analysis.ipynb) notebook.

## CleanEHR dataset

The CleanEHR anonymized and public dataset can be requested online. It contains records for 1978 patients (one record each) who died at a hospital (or in some cases arrived dead), with 263 fields, including 154 longitudinal fields (time-series). These fields cover patient demographics, physiology, laboratory, and medication information for each patient/record, recorded in intensive care units across several NHS trusts in England. The dataset comes as an R data object, which can be most profitably accessed with an accompanying R package (https://cran.r-project.org/src/contrib/Archive/cleanEHR/). The R package is available at https://github.com/ropensci/cleanEHR. There is also a [blog post](https://ropensci.github.io/cleanEHR/data_clean.html) on how to use it. A detailed explanation of each field is found in https://github.com/ropensci/cleanEHR/wiki under Data-set-1.0 and CCHIC-Data-Fields.

The analysis was adapted from work performed by Giovanni Colavizza and Camila Rangel Smith, and is further summarized in the [cleanEHR_analysis](https://github.com/alan-turing-institute/aida-data-engineering-issues/blob/master/cleanEHR_analysis.ipynb) notebook.

## HES dataset
The Household Electricity Survey 2010--2011 (Department of Energy and Climate Change 2016), a study commissioned by the UK government, collected detailed time-series measurements of the electrical energy consumption of individual appliances across around 200 households in England. The data from that study are available from the UK Data Archive (UKDA, but only on application); an overview is publicly available from the [government's website](https://www.gov.uk/government/collections/household-electricity-survey).

The analysis was adapted from work performed by Giovanni Colavizza and Angus Williams, and is further summarized in the [HES_analysis](https://github.com/alan-turing-institute/aida-data-engineering-issues/blob/master/HES_analysis.ipynb) notebook.

## Tundra dataset
This use-case comprises two separate datasets:
* The **Tundra Traits Team database**: It contains nearly 92,000 measurements of 18 plant traits. The most frequently measured traits include plant height, leaf area, specific leaf area, leaf fresh and dry mass, leaf dry matter content, leaf nitrogen content, leaf carbon content, leaf phosphorus content, seed mass, and stem specific density. The dataset also comes
   with a cleaning script prepared by its originators (https://github.com/ShrubHub/TraitHub). We were kindly granted early access to this dataset by Isla H. Myers-Smith and Anne Bjorkman of the [sTUNDRA group](https://teamshrub.wordpress.com/research/tundra-trait-team/)
* The **CRU Time Series** temperature data and rainfall data: These are global datasets, gridded to 0.5º. We use only the date range 1950 to 2016. http://catalogue.ceda.ac.uk/uuid/58a8802721c94c66ae45c3baa4d814d0

The analysis was performed by Giovanni Colavizza in R, and is available in the Tundra folder. In the scripts folder there are 4 different files:
1. Use the *TTT_data_cleaning_script.r* to clean the dataset. After using it, we end up in the clean version of the Tundra data provided in (https://github.com/ShrubHub/TraitHub), before integrating the CRU data.
2. *create_dataset.r* contains the data integration of the CRU data into the Tundra dataset. Further data processing operations were done previous to the model analysis.
3. *fit-model.r* fits the selected model for the analysis.
4. *plotting_figure.r* plots the figure included in the paper (saved in results)

# Contact information
Alfredo Nazabal: anazabal@turing.ac.uk
