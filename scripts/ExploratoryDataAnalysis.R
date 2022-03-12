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

# Answers second challenge question
library(caret)

price.estimation.data <- listings.daily.revenue %>%
  filter(last_offered_price > 0) %>%
  group_by(Hotel) %>%
  group_split(.keep = FALSE)

price.estimation.data.not.hotel <- price.estimation.data[[1]]
price.estimation.data.hotel <- price.estimation.data[[2]]

## Model for estimating prices for apartment and houses
price.estimation.data.not.hotel <- price.estimation.data.not.hotel %>%
  mutate(weekday=relevel(as.factor(as.character(wday(date, label = TRUE))),
                         "seg"),
         Localização=relevel(Localização, "CENTRO"),
         Categoria=relevel(Categoria, "SIM"))%>%
  select(last_offered_price, weekday, reservation_advance, Localização,
         Categoria, Quartos, Cama.Casal, Cama.Solteiro, Cama.Queen,
         Cama.King, Sofá.Cama.Solteiro, Taxa.de.Limpeza, Banheiros, Capacidade)

### Splits the data in training and testing sets
set.seed(1)
train.index <- createDataPartition(price.estimation.data.not.hotel$last_offered_price,
                                   p=0.60, list=FALSE)
training <- price.estimation.data.not.hotel[train.index,]
testing <- price.estimation.data.not.hotel[-train.index,]

### Trains a multivariate linear regression model optimally
first.model <- lm(last_offered_price ~ ., training)
model.no.hotel <- step(first.model)

### Assesses model fit on testing and training data
summary(model.no.hotel) # R² = 93.58%

predictions <- predict(model.no.hotel, testing)
RMSE.on.training.set <- sqrt(mean(model.no.hotel$residuals^2))
RMSE.on.testing.set <- sqrt(mean((predictions - testing$last_offered_price)^2))

c("Training RMSE"=RMSE.on.training.set, #91.00553
  "Testing RMSE"=RMSE.on.testing.set)   #99.38460

## Model for estimating prices for hotel rooms
price.estimation.data.hotel <- price.estimation.data.hotel %>%
  mutate(weekday=relevel(as.factor(as.character(wday(date, label = TRUE))),
                         "seg"),
         Localização=relevel(Localização, "CENTRO"),
         Categoria=relevel(Categoria, "SIM"))%>%
  select(last_offered_price, weekday, reservation_advance, Localização,
         Categoria, Cama.Casal, Cama.Solteiro, Cama.Queen,
         Cama.King, Sofá.Cama.Solteiro, Banheiros, Capacidade)

### Splits the data in training and testing sets
set.seed(1)
train.index <- createDataPartition(price.estimation.data.hotel$last_offered_price,
                                   p=0.70, list=FALSE)
training <- price.estimation.data.hotel[train.index,]
testing <- price.estimation.data.hotel[-train.index,]

### Trains a multivariate linear regression model optimally
first.model <- lm(last_offered_price ~ ., training)
model.hotel <- step(first.model)

### Assesses model fit on testing and training data
summary(model.hotel) # R² = 61.38%

predictions <- predict(model.hotel, testing)
RMSE.on.training.set <- sqrt(mean(model.hotel$residuals^2))
RMSE.on.testing.set <- sqrt(mean((predictions - testing$last_offered_price)^2))

c("Training RMSE"=RMSE.on.training.set, #114.6488
  "Testing RMSE"=RMSE.on.testing.set)   #116.4826

## Generalizes for the whole data
price.data <- listings.daily.revenue %>%
  mutate(weekday=as.factor(as.character(wday(date, label = TRUE)))) %>%
  group_by(Hotel) %>%
  group_split(.keep = FALSE)

### Uses both models to make predictions, then rejoins the dataset
price.data.no.hotel <- price.data[[1]]
price.data.hotel <- price.data[[2]]

predictions.no.hotel <- predict(model.no.hotel, price.data.no.hotel %>%
                                  mutate(Localização=fct_collapse(Localização, CAN=setdiff(
                                    levels(price.data.no.hotel$Localização),
                                    model.no.hotel$xlevels$Localização))))

predictions.hotel <- predict(model.hotel, price.data.hotel%>%
                               mutate(Localização=fct_collapse(Localização, ILC=setdiff(
                                 levels(price.data.hotel$Localização),
                                 model.hotel$xlevels$Localização))))

price.data.no.hotel <- price.data.no.hotel %>%
  mutate(predicted.price=predictions.no.hotel)
price.data.hotel <- price.data.hotel %>%
  mutate(predicted.price=predictions.hotel)

price.data <- full_join(price.data.no.hotel, price.data.hotel)

# Exploratory Analysis on Predicted Price Data
p <- price.data %>%
  group_by(date) %>%
  summarise(predicted.revenue=sum(predicted.price*Comissão))

qplot(x=date, y=predicted.revenue, data=p,geom="line")