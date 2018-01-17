#load packages
pacman::p_load(dplyr,lubridate,xlsx,reshape2,scales,slackr) 

#setting up slack acount
slackr_setup(api_token = "xoxp-xxxx-xxxxx",
             config_file = "~/.slackr",
             incoming_webhook_url = "https://hooks.slack.com/services/xxxxx/xxxxxx")


                                    #1. Get Monefy and Cashback data



setwd("Path-to-Monefy-data")
Expenses = read.csv(paste("Monefy.Data.", format(today(), "%d-%m-%Y"), ".csv", 
                          sep = ""), header = TRUE)
Cashback = as.numeric(read.xlsx("Cashback-excel-file", sheetIndex = 1, rowIndex = 20, 
                                colIndex = 3:14, header = F))



                                  #2. Preparing data for analysis



#Remove unnecessary columns 
Expenses = Expenses[,-c(2,5,6,7)]
Expenses$amount = abs(Expenses$amount)
#Changed date column from character to date using default date format
Expenses$date = base::as.Date(Expenses$date, format = "%d/%m/%Y")
colnames(Expenses) = c("Date", "Category", "Amount", "Description")
#remove deposit rows since not using
Expenses = filter(Expenses, Category != "Deposits")
Expenses$MonYear <- as.Date(cut(Expenses$Date, breaks = "month"))


#add cashback as -ve value in each month column
a = data.frame(Amount = -Cashback, 
               MonYear = seq.Date(base::as.Date("2017-10-01"), by = "month", length.out = 12))
#binded cashback to df
a = na.omit(a)
Expenses.cashback = bind_rows(a, Expenses)



        #3. Summarise for monthly budgeting where 500 is the budget you want to set for each month



Monthly.Expenses <- Expenses.cashback %>% 
  group_by(MonYear) %>% 
  summarise(Amount = sum(Amount))
Monthly.Expenses$Difference = cumsum(500-Monthly.Expenses$Amount)
Monthly.Expenses$Budget = Monthly.Expenses$Difference + Monthly.Expenses$Amount



                    #8. Determines if budget met and sends corresponding message



#subset last row for this month's budget & amount
currentmonth =  slice(Monthly.Expenses, n())

#sends conditional message to slack
spent = abs(round(currentmonth$Budget - currentmonth$Amount, digits = 2))
y = paste("Well done you! You've spent ", "$", currentmonth$Amount, "which is ", "$", spent, 
          " under this month's budget. Now go and stuff yourself with cake.")
n = paste("You spent ", "$", currentmonth$Amount, "which is ", "$", spent, 
          "over this month's budget. Noooooooo cakeeeeeeeeeee! (╯︵╰,)")

if(currentmonth$Amount<currentmonth$Budget)
  slackr_msg(y, as_user = FALSE, username = "Monthly reminder") else
    slackr_msg(n, as_user = FALSE, username = "Monthly reminder")