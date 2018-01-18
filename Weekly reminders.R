#load packages
pacman::p_load(dplyr,ggplot2,lubridate,xlsx,reshape2,scales,slackr) 

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
#bind cashback to df
a = na.omit(a)
Expenses.cashback = bind_rows(a, Expenses)



         #3. Summarise for monthly budgeting where 500 is the budget you want to set for each month



Monthly.Expenses <- Expenses.cashback %>% 
  group_by(MonYear) %>% 
  summarise(Amount = sum(Amount))
Monthly.Expenses$Difference = cumsum(500-Monthly.Expenses$Amount)
Monthly.Expenses$Budget = Monthly.Expenses$Difference + Monthly.Expenses$Amount



                  #4. Create new dataframe for calculating next month's budget



#calculating next month's budget based on current spendings
x = sum(Monthly.Expenses$Amount)
Future.Budget = round((500*12 - x)/(12 - length(Monthly.Expenses$Amount)), digits = 2)

#create new row in df for next month's budget to show in graph 
f = data.frame(MonYear = max(Monthly.Expenses$MonYear) %m+% months(1), Budget = Future.Budget)
Monthly.Expenses.future = merge(Monthly.Expenses, f, all = TRUE)

#slackr message to inform graphs coming in
slackr_msg("It's that time of the month again.", as_user = FALSE, username = "Botups")



              #5. Generates a graph showing monthly expenditure and budget and sends to Slack



ggslackr(ggplot(Monthly.Expenses.future, aes(MonYear, Amount)) + 
           geom_bar(stat = "identity", fill = "steelblue3") +
           labs(x = "Month", y = "Expenditure") +
           scale_x_date(labels = date_format("%b-%Y"))+
           geom_errorbar(aes(ymin = Budget, ymax = Budget), size = 2) + 
           geom_text(aes(label = paste("$", (Amount), "\n", 
                                       "(", round(Amount/Budget *100), "%", ")", sep = ""), y = 60), 
                     size = 4, colour = "black") + theme_minimal() + 
           geom_text(aes(label = paste("$", (Budget)), y = Budget + 30)) +
           geom_hline(yintercept = 500, linetype="dashed", color = "red", size=1) +
           labs(title = "Monthly budget and expenditure", x = "Month", y = "Expenditure($)"))



          #6. Generates a graph showing breakdown of monthly expenditure and sends to Slack



graph2.df = Expenses[,-c(1,4)]
graph2.df = aggregate(Amount ~ Category + MonYear, data = graph2.df, sum)
ggslackr(ggplot(graph2.df, aes(x = MonYear, y = Amount, colour = Category)) + geom_line() +
           geom_point() + scale_x_date(labels = date_format("%b-%Y")) + theme_minimal() + 
           labs(title = "Monthly expenditure breakdown", x = "Month", y = "Expenditure($)"))



                    #7. Calculating weekly expected expenditure for Slack messsage 



#today and number of days in month
monthdays = as.numeric(days_in_month(Sys.Date()))
num.today = as.numeric(day(today()))

#vectorise current month row to make it easier to work on
currentmonth =  slice(Monthly.Expenses, n())
expectedexpenditure = round((num.today/monthdays) * currentmonth$Budget,digits =2)

#message shows whether spending in line with expected amount. +ve reinforcement for meeting goal. 
spent = abs(round(expectedexpenditure - currentmonth$Amount, digits = 2))
y = paste("Well done! ", "You've spent ", "$", currentmonth$Amount, " so far, which is ",
          "$", spent, "under this week's budget. Reward yourself with a movie :).")
n = paste("You're ", "$", spent, "over this week's budget of ", "$", expectedexpenditure,
          "so far. Beeee carefulllll *stares*.")

#sends conditional message to slack
if(currentmonth$Amount<=expectedexpenditure)
  slackr_msg(y, as_user = FALSE, username = "Weekly reminder") else
    slackr_msg(n, as_user = FALSE, username = "Weekly reminder")
