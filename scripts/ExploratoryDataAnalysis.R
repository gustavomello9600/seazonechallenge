library(tidyverse)

# Loads datasets as tibbles
cwd <- getwd()
listings <- as_tibble(read.csv(paste0(cwd, "/../data/listings-challenge.csv")))
daily.revenue <- as_tibble(read.csv(paste0(cwd, "/../data/daily_revenue-challenge.csv")))

# Prepares datasets to perform relevant analysis
listings <- listings %>%
  mutate(across(c("Código", "Categoria", "Endereço",
                  "Comissão", "Banheiros", "Taxa.de.Limpeza",
                  "Data.Inicial.do.contrato"),
                as.character)) %>%
  mutate(across(c("Comissão", "Banheiros", "Taxa.de.Limpeza"),
                function(x){
                  parse_number(x, locale=locale(decimal_mark=","))
                  })) %>%
  mutate(Data.Inicial.do.contrato=parse_date(Data.Inicial.do.contrato,
                                             "%d/%m/%Y")) %>%
  extract(Categoria, c("Categoria", "Quartos"), "[HOU]*([A-Z]+)([0-9])*Q*",
          convert=TRUE) 
