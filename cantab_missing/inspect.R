library(ggplot2)
library(lubridate)

d<-read.table('subj_date.tsv')
names(d) <- c('subj','date')
d$date<-ymd(d$date)
p <- 
  ggplot(d)+
  aes(x=date,y=jitter(rep(1,nrow(d)),2),label=subj)+
  geom_label() +
  ylab('') + scale_y_continuous(breaks=c()) + 
  theme_bw() + ggtitle('cog cantab: missing subjects')

print(p)
ggsave(p,file="missing.pdf")
