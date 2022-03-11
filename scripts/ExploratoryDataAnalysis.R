library(tidyverse)

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
  select(-c("Hotel")) %>%
  mutate(Categoria=fct_collapse(Categoria, TOP=c("TOP", "TOPM")))

tidy.daily.revenue <- daily.revenue %>%
  select(-c("occupancy", "blocked", "revenue")) %>%
  mutate(across(-c("listing"), as.character)) %>%
  mutate(last_offered_price=parse_double_with_comma(last_offered_price)) %>%
  mutate(across(contains("date"), function(x){as.Date(parse_datetime(x))})) %>%
  mutate(reservation_advance=date - creation_date)