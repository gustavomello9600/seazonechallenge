library(tidyverse, lubridate)

# Loads datasets as tibbles
cwd <- getwd()
listings <- as_tibble(read.csv(paste0(cwd, "/../data/listings-challenge.csv")))
daily.revenue <- as_tibble(read.csv(paste0(cwd, "/../data/daily_revenue-challenge.csv")))

# Auxiliary cleaning functions
parse_double_with_comma <- function(x){
  parse_number(x, locale=locale(decimal_mark=","))
}
parse_integer_with_comma <- function(x){
  as.integer(parse_double_with_comma(x))
}

# Prepares datasets to perform relevant analysis
tidy.listings <- listings %>%
  mutate(across(-c("Tipo", "Status", "Hotel", "Categoria", "Localização"),
                as.character)) %>%
  mutate(across(c("Comissão", "Banheiros", "Taxa.de.Limpeza"),
                parse_double_with_comma)) %>%
  mutate(Taxa.de.Limpeza=na_if(Taxa.de.Limpeza, 0)) %>%
  mutate(across(c(contains("Cama"), "Travesseiros", "Capacidade"),
                parse_integer_with_comma)) %>%
  mutate(Data.Inicial.do.contrato=parse_date(Data.Inicial.do.contrato,
                                             "%d/%m/%Y")) %>%
  extract(Categoria, c("Categoria", "Quartos"), "[HOU]*([A-Z]+)([0-9])*Q*",
          convert=TRUE) %>%
  mutate(Categoria=as.factor(Categoria)) %>%
  select(-c("Endereço")) %>%
  mutate(Categoria=fct_collapse(Categoria, TOP=c("TOP", "TOPM")))

tidy.daily.revenue <- daily.revenue %>%
  select(-c("occupancy", "blocked", "revenue")) %>%
  mutate(across(-c("listing"), as.character)) %>%
  mutate(last_offered_price=parse_double_with_comma(last_offered_price)) %>%
  mutate(across(contains("date"), function(x){as_date(parse_datetime(x))})) %>%
  mutate(reservation_advance=date - creation_date)

listings.daily.revenue <- tidy.daily.revenue %>%
  left_join(tidy.listings, by=c("listing" = "Código")) %>%
  mutate(revenue=last_offered_price*Comissão) %>%
  mutate(across(Travesseiros, ~ifelse(is.na(.),
                                      2*(Cama.Casal + Cama.Queen + Cama.King)
                                      + 1*(Cama.Solteiro + Sofá.Cama.Solteiro),
                                      .)))

# Plots total revenue across time
listings.daily.revenue %>%
  select(date, revenue) %>%
  group_by(date) %>%
  summarise(revenue=sum(revenue)) %>%
  ggplot(aes(x=date, y=revenue)) +
  geom_point() +
  geom_smooth()

# Investigates the interval in which prices are accessible
tidy.daily.revenue %>%
  ggplot(aes(x=date, y=last_offered_price)) +
  geom_point()

# Answers first challenge question
listings.daily.revenue %>%
  filter(date >= ymd("2022-03-04"), date <= ymd("2022-03-31"),
         Categoria == "MASTER",
         Localização == "JUR") %>%
  summarise(mean_price=mean(last_offered_price), mean_revenue=mean(revenue))
# mean_price: 535; mean_revenue:107

