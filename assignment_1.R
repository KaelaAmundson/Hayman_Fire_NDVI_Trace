library(tidyverse)
library(tidyr)
library(ggthemes)
library(lubridate)

# Now that we have learned how to munge (manipulate) data
# and plot it, we will work on using these skills in new ways


####-----Reading in Data and Stacking it ----- ####
#Reading in files
files <- list.files('data',full.names=T)


#Read in individual data files
ndmi <- read_csv(files[1]) %>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndmi')


ndsi <- read_csv(files[2]) %>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndsi')

ndvi <- read_csv(files[3])%>% 
  rename(burned=2,unburned=3) %>%
  mutate(data='ndvi') %>%

# Stack as a tidy dataset
full_long <- rbind(ndvi,ndmi,ndsi) %>%
  gather(key='site',value='value',-DateTime,-data) %>%
  filter(!is.na(value))

##### Question 1 #####
#1 What is the correlation between NDVI and NDMI? - here I want you to
#convert the full_long dataset in to a wide dataset using the 
#function "spread" and then make a plot that shows the correlation as a
# function of if the site was burned or not

?spread
full_wide <- spread(full_long, key='data', value='value') %>%
  filter_if(is.numeric,all_vars(!is.na(.))) %>%
  mutate(month=month(DateTime),
         year=year(DateTime))
summary(full_wide)

?filter
summer_only <- filter(full_wide,month %in% c(6,7,8,9))

ggplot(summer_only,aes(x=ndmi,y=ndvi,color=site)) + 
  geom_point() +
  theme_few() +
  theme(legend.position=c(0.7,0.8))

## End Code for Question 1 -----------


#### Question 2 ####
#2) What is the correlation between average NDSI (normalized 
# snow index) for January - April and average NDVI for June-August?
#In other words, does the previous year's snow cover influence vegetation
# growth for the following summer? 

?summarize

winter_ndsi <- filter(full_wide, month %in% c(1,2,3,4)) %>%
  group_by(year, site) %>%
  summarize(mean_ndsi=mean(ndsi))

summer_ndvi <- filter(full_wide, month %in% c(6,7,8)) %>%
  group_by(year, site) %>%
  summarize(mean_ndvi=mean(ndvi))

?inner_join
?merge

NDSI_NDVI <- inner_join(winter_ndsi, summer_ndvi, by=c('year', 'site'))

ggplot(NDSI_NDVI,aes(x=mean_ndsi,y=mean_ndvi,color=site)) + 
  geom_point() +
  theme_few() +
  theme(legend.position=c(0.7,0.8))


## End code for question 2 -----------------


###### Question 3 ####
#How is the snow effect from question 2 different between pre- and post-burn
# and burned and unburned? 

?mutate

NDSI_NDVI <- mutate(NDSI_NDVI, condition = cut(year, c(0, 2004, 2019), 
                                               labels = c("pre-burn", "post-burn")))

ggplot(NDSI_NDVI,aes(x=mean_ndsi,y=mean_ndvi,color=site)) + 
  geom_point() +
  theme_few() +
  facet_wrap(~condition) +
  theme(legend.position=c(0.7,0.8)) 

## End code for question 3

###### Question 4 #####
#What month is the greenest month on average? Does this change in the burned
# plots after the fire? 

ndvi_month <- mutate(ndvi, month=month(DateTime),
                     year=year(DateTime)) %>%
  mutate(condition = cut(year, c(0, 2004, 2019), 
                                    labels = c("pre-burn", "post-burn"))) %>%
  group_by(month) %>%
  filter(!is.na(burned)) %>%
  gather(key=site, value=value, burned, unburned)
  
  
ggplot(ndvi_month, aes(x=month, y=value, color=site)) +
  geom_point() + 
  geom_smooth(se=FALSE) +
  theme_few() +
  facet_wrap(~condition) +
  scale_x_discrete(limits=c(1:12)) +
  ylab("ndvi value")


##### Question 5 ####
#What month is the snowiest on average?

snowiest <- mutate(ndsi, month=month(DateTime),
                   year=year(DateTime)) %>%
  gather(key=site, value=value, burned, unburned) %>%
  filter(!is.na(value))

ggplot(ndvi_month, aes(x=month, y=value, color=site)) +
  geom_point() + 
  geom_smooth(se=FALSE) +
  theme_few() +
  scale_x_discrete(limits=c(1:12)) +
  ylab("ndsi value")

