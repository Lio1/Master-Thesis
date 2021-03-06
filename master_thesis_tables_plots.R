## How can firms alleviate their vulnerabilities to black swans? 
## Master Thesis - Lionel Pau (HEC Paris)
## Study of the vulnerability of US construction firms to the 2008 real estate prices black swan

# Loading the required packages
library(dplyr)
library(tidyr)
library(ggplot2)

# Downloading the "Firm Age by Firm Size by Sector" BDS dataset from the US Census Bureau
url <- "http://www2.census.gov/ces/bds/firm/age_size_sector/bds_f_agesz_sic_release.csv" 
download.file(url,destfile="bds_f_agesz_sic_release.csv")
dateDownloaded <- date()
dateDownloaded

# Reading the data set and selecting our variables
estabs_raw <- read.csv("bds_f_agesz_sic_release.csv")
dim(estabs_raw)

estabs_all <- select(estabs_raw,year2,sic1,fsize,fage4,firms,estabs,emp,estabs_entry,estabs_exit,job_creation,job_destruction)
sapply(estabs_all,anyNA) #  firms, estabs, emp, job_creation and job_destruction have NAs 

# Cleaning names: sectors
sectors_names <- c("agricultural services, forestry, fishing", "mining","construction","manufacturing","transportation and public utilities","wholesale trade","retail trade","finance, insurance, real estate","services")
sectors_table <- data.frame(sic1 = c(7,10,15,20,40,50,52,60,70),sector=factor(sectors_names,levels=sectors_names))
estabs_all <- left_join(estabs_all,sectors_table,by="sic1")
estabs_all$sic1 <- NULL

# Cleaning names: firm age
ages_names <- c("0","1","2","3","4","5","6-10","11-15","16-20","21-25","26+","unknown")
ages_table <- data.frame(fage4 = c("a) 0", "b) 1", "c) 2", "d) 3", "e) 4", "f) 5", "g) 6 to 10", "h) 11 to 15", "i) 16 to 20", "j) 21 to 25", "k) 26+", "l) Left Censored"),firm_age=factor(ages_names,levels=ages_names))
estabs_all <- left_join(estabs_all,ages_table,by="fage4")
estabs_all$fage4 <- NULL

# Cleaning names: firm size (and year)
sizes_names <- c("1-4","5-9","10-19","20-49","50-99","100-249","250-499","500-999","1000-2499","2500-4999","5000-9999","10000+")
sizecats_names <- c("micro","micro","small","small","small","small","medium","medium","medium","medium","large","large")
firms_sizes <- data.frame(fsize = c("a) 1 to 4", "b) 5 to 9", "c) 10 to 19", "d) 20 to 49", "e) 50 to 99", "f) 100 to 249", "g) 250 to 499", "h) 500 to 999", "i) 1000 to 2499", "j) 2500 to 4999", "k) 5000 to 9999", "l) 10000+"), firm_size=factor(sizes_names,levels=sizes_names),firm_size_cat=factor(sizecats_names,levels=unique(sizecats_names)))
estabs_all <- left_join(estabs_all,firms_sizes,by="fsize")
estabs_all$fsize <- NULL

estabs_all <- rename(estabs_all,year = year2)

# Filtering for years 2003-2012
estabs <- filter(estabs_all, year > 2002)
estabs$year <- factor(estabs$year)


## Building tables and plots

# (Net) Mortality rate of establishments (per sector, 2004-2012)
tableA <- estabs %>% group_by(year,sector) %>% summarize(estabs = sum(estabs,na.rm = T), exits = sum(estabs_exit,na.rm = T), entries = sum(estabs_entry,na.rm = T)) %>% mutate(estabs_mortality_rate=exits/((estabs+lag(estabs))/2), estabs_birth_rate=entries/((estabs+lag(estabs))/2), estabs_net_mortality_rate=estabs_mortality_rate-estabs_birth_rate) %>% filter(year != 2003)

plot01 <- ggplot(tableA,aes(x=year,y=estabs_mortality_rate,group=sector)) + geom_line(aes(color=sector,size=sector)) + scale_size_manual(values = c(1,1,2,1,1,1,1,1,1)) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot01)
dev.copy(png, file="plot01.png",width=900,height=500)
dev.off()

plot02 <- ggplot(tableA,aes(x=year,y=estabs_net_mortality_rate,group=sector)) + geom_line(aes(color=sector,size=sector)) + scale_size_manual(values = c(1,1,2,1,1,1,1,1,1)) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot02)
dev.copy(png, file="plot02.png",width=900,height=500)
dev.off()

# (Net) Mortality rate of establishments within construction firms (per firm size, 2004-2012)
tableB <- estabs %>% group_by(sector,firm_size_cat,year) %>% summarize(firms = sum(firms,na.rm = T), estabs = sum(estabs,na.rm = T), exits = sum(estabs_exit,na.rm = T), entries = sum(estabs_entry,na.rm = T)) %>% mutate(estabs_mortality_rate=exits/((estabs+lag(estabs))/2), estabs_birth_rate=entries/((estabs+lag(estabs))/2), estabs_net_mortality_rate=estabs_mortality_rate-estabs_birth_rate) %>% filter(sector=="construction", year != 2003)
tableC <- tableB %>% filter(year == 2008) %>% select(year, sector,firm_size_cat,firms,estabs) %>% mutate(estabs_per_firm=estabs/firms)
print(tableC)
sum(tableC$firms)

plot03 <- ggplot(tableB,aes(x=year,y=estabs_mortality_rate,group=firm_size_cat)) + geom_line(aes(color=firm_size_cat),size=2) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot03)
dev.copy(png, file="plot03.png",width=900,height=500)
dev.off()

tableD_1 <- tableB %>% filter(year %in% c(2008,2009)) %>% select(year, sector,firm_size_cat,estabs_mortality_rate) %>% spread("year","estabs_mortality_rate")
names(tableD_1)[3:4] <- c("mortality_rate_2008","mortality_rate_2009")
tableD_1 <- tableD_1 %>% mutate(var=mortality_rate_2009-mortality_rate_2008)
print(tableD_1)

plot04 <- ggplot(tableB,aes(x=year,y=estabs_net_mortality_rate,group=firm_size_cat)) + geom_line(aes(color=firm_size_cat),size=2) + scale_size_manual(values = c(1,1,1,1)) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot04)
dev.copy(png, file="plot04.png",width=900,height=500)
dev.off()

tableD_2 <- tableB %>% filter(year %in% c(2008,2009)) %>% select(year, sector,firm_size_cat,estabs_net_mortality_rate) %>% spread("year","estabs_net_mortality_rate")
names(tableD_2)[3:4] <- c("net_mortality_rate_2008","net_mortality_rate_2009")
tableD_2 <- tableD_2 %>% mutate(var=net_mortality_rate_2009-net_mortality_rate_2008)
print(tableD_2)

# (Net) Destruction rate of jobs within construction firms (per firm size, 2004-2012)
tableE <- estabs %>% group_by(sector,firm_size_cat,year) %>% summarize(firms = sum(firms,na.rm = T), estabs = sum(estabs,na.rm = T), jobs = sum(emp,na.rm = T), creations = sum(job_creation,na.rm = T),destructions = sum(job_destruction,na.rm = T)) %>% mutate(jobs_creation_rate=creations/((jobs+lag(jobs))/2), jobs_destruction_rate=destructions/((jobs+lag(jobs))/2), jobs_net_destruction_rate=jobs_destruction_rate-jobs_creation_rate) %>% filter(sector == "construction", year != 2003)
tableF <- tableE %>% filter(year == 2008) %>% select(year, sector,firm_size_cat,firms,jobs) %>% mutate(jobs_per_firm=jobs/firms)
print(tableF)
sum(tableF$jobs)

plot05 <- ggplot(tableE,aes(x=year,y=jobs_destruction_rate,group=firm_size_cat)) + geom_line(aes(color=firm_size_cat),size=2) + scale_size_manual(values = c(1,1,1,1)) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot05)
dev.copy(png, file="plot05.png",width=900,height=500)
dev.off()

tableG_1 <- tableE %>% filter(year %in% c(2008,2009)) %>% select(year,sector,firm_size_cat,jobs_destruction_rate) %>% spread("year","jobs_destruction_rate")
names(tableG_1)[3:4] <- c("job_dest_rate_2008","job_dest_rate_2009")
tableG_1 <- tableG_1 %>% mutate(var=job_dest_rate_2009-job_dest_rate_2008)
tableG_2 <- tableE %>% filter(year %in% c(2008,2009)) %>% select(year,sector,firm_size_cat,jobs_creation_rate) %>% spread("year","jobs_creation_rate")
names(tableG_2)[3:4] <- c("job_crea_rate_2008","job_crea_rate_2009")
tableG_2 <- tableG_2 %>% mutate(var=job_crea_rate_2009-job_crea_rate_2008)
tableG_3 <- tableE %>% filter(year %in% c(2008,2009)) %>% select(year,sector,firm_size_cat,jobs_net_destruction_rate) %>% spread("year","jobs_net_destruction_rate")
names(tableG_3)[3:4] <- c("job_net_rate_2008","job_net_rate_2009")
tableG_3 <- tableG_3 %>% mutate(var=job_net_rate_2009-job_net_rate_2008)

plot06 <- ggplot(tableE,aes(x=year,y=jobs_net_destruction_rate,group=firm_size_cat)) + geom_line(aes(color=firm_size_cat),size=2) + scale_size_manual(values = c(1,1,1,1)) + theme_classic(base_size=16) + geom_vline(xintercept=c(5,6),linetype="dotted")
print(plot06)
dev.copy(png, file="plot06.png",width=900,height=500)
dev.off()