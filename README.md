# Personal-Expenses
Combines Monefy data to track expenses, sending reminders and graphs to your mobile.

# About
I've been using the Monefy App to keep track of my daily expenses since it's easy to add expenses immediately and decided to write an R script to automatically send myself messages and graphs on my mobile at the end of every week and month. These remind me to keep within my budget by showing how much I've spent and utilise the behaviour modification techniques of positive reinforcement and negative punishment to encourage behaviour maintenance/change. 

# What it does  
1. Get the Monefy .csv and Cashback .xlsx files from a folder in your computer
2. Prepares the data for analysis
3. Summarises the combined data into a monthly format 
4. Create new dataframe for calculating next month's budget 
5. Generates a graph showing monthly expenditure and budget
6. Generates a graph showing a breakdown of the monthly expenditure to identify major expenses
7. Send graphs and messages to your Slack Account
 
# To use this, you need to
1. Download Monefy's mobile app (Available on both Android & IOS)
2. Set up a Slack Account and download the mobile app
3. Set up Windows Task Scheduler to run the R script at the desired time 

# Caveats
1. If you're using the free Monefy App, you need to export the .csv file from the app to a folder on your computer. 
  - I sync mine to my OneDrive on the day I run the R script.
2. As Slack is used to send the graphs and messages to the mobile, the computer needs to be connected to the Internet while running the R script for Slack to work.
