require("RPostgreSQL")
drv <- dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
con <- dbConnect(drv, dbname = "lncddb",
                 host = "arnold.wpic.upmc.edu", port = 5432,
                 user = "postgres")
sqlquery <- "
select
 id,
 vid,
 pid,
 sex,
 age,
 study,
 vtimestamp,
 measures->'HawaiianPacIsl' as HawaiianPacIsl,
 measures->'Black' as Black,
 measures->'Hispanic' as Hispanic,
 measures->'Asian' as Asian,
 measures->'White' as White,
 measures->'AmerIndianAlaskan' as AmerIndianAlaskan
 from visit_study
 natural join visit
 natural join person
 natural join visit_task
 natural join enroll
 where
   study like 'RewardR%' and
   task like 'Demographics' and
   etype like 'LunaID' and
   id in ('11168','11176','11178','11179','11185','11187','11191','11197','11198','11211','11212','11215','11218','11219','11220','11221','11224','11226','11227','11228','11230','11232','11233','11235','11234','11237','11238','11239','11241','11242','11244','11245','11249','11251','11254','11257','11259','11261','11264','11265','11266','11267','11268','11269','11270','11271','11272','11273','11275','11278','11282','11283','11276','11284','11285','11286','11165','11289','11290','11291','11292','11293','11294','11295','11296','11297','11299','11300','11301','11307');
"


r<-dbSendQuery(con,sqlquery)
d<-fetch(r)

d.perid <- 
  d %>% 
  gather(eth,val,hawaiianpacisl,black,hispanic,asian,white,amerindianalaskan) %>% 
  filter(val==-1) %>% 
  group_by(id,vid,pid,sex,age,study,vtimestamp) %>% 
  summarise(eths=paste(collapse=",",unique(sort(eth)))) %>% 
  group_by(id,sex) %>% 
  summarise(eths=paste(collapse=":",unique(sort(eths))),mage=mean(age),n=n())

d.perid %>% select(id,sex,eths)
write.csv(file="eth_rewardleftover.csv",d.perid,row.names=F,quote=F)


want <- c('11168','11176','11178','11179','11185','11187','11191','11197','11198','11211','11212','11215','11218','11219','11220','11221','11224','11226','11227','11228','11230','11232','11233','11235','11234','11237','11238','11239','11241','11242','11244','11245','11249','11251','11254','11257','11259','11261','11264','11265','11266','11267','11268','11269','11270','11271','11272','11273','11275','11278','11282','11283','11276','11284','11285','11286','11165','11289','11290','11291','11292','11293','11294','11295','11296','11297','11299','11300','11301','11307');
